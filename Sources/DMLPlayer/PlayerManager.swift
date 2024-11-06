//
//  PlayerViewModel.swift
//  DMLPlayer
//
//  Created by littleTurnip on 9/27/23.
//

import Combine
import DMLPlayerProtocol
import KSPlayer
import OSLog
import SwiftUI

// MARK: - PlayerManager

@MainActor
public class PlayerManager: PlayerProtocol, ObservableObject, Sendable {
  let logger = Logger(subsystem: "DMLPlayer", category: "Player.Viewmodel")

  private var cancellables: Set<AnyCancellable> = []
  private var retryStreamIndex = -1

  @Published public var player: PlayerCoordinator
  public let danmaku: DanmakuCoordinator
  public var playerOptions: PlayerOptions
  public var danmakuOptions: DanmakuOptions

  @Published public var item: (any PlayableItem)?
  @Published public var playlists: [any Playlist] = []

  public var playlistMap: [UUID: Set<String>] {
    playlists.reduce(into: [:]) { result, playlist in
      result[playlist.id] = Set(playlist.entries.map { $0.id })
    }
  }

  @Published public var libraryItemList: [any PlayableItem] = []
  @Published public var libraryPlaylist: [any Playlist] = []
  @Published public var isVisible = false

  @Published var streamResource: (any LiveResource)?
  @Published public var isRecommendVisible = false
  @Published var isInfoVisible = false
  @Published var isDanmakuVisible: Bool

  @Published var showUnfavConfirmation = false
  @Published var showNotPlayingAlert = false

  public init(playerOptions: PlayerOptions? = nil, danmakuOptions: DanmakuOptions = DanmakuOptions.default) {
    if let playerOptions {
      self.playerOptions = playerOptions
    } else {
      self.playerOptions = PlayerOptions()
    }
    self.danmakuOptions = danmakuOptions
    isDanmakuVisible = danmakuOptions.layer.isAutoPlay
    player = KSVideoPlayer.Coordinator()
    danmaku = DanmakuContainer.Coordinator()
    bindingMaskShow()
  }

  deinit {
    logger.trace("PlayerViewModel deinit")
  }

  public func updateItem(_ newItem: any PlayableItem) {
    logger.info("update item: \(newItem.id)")
    danmaku.stopDanmakuStream()
    updatePlayInfo()
    item = newItem
    danmaku.setDanmakuService(newItem.danmakuService)
    if danmakuOptions.layer.isAutoPlay {
      danmaku.startDanmakuStream(options: danmakuOptions)
    }
    subscribeResource()
  }

  public func updateOptions(_ player: PlayerOptions, _ danmaku: DanmakuOptions) {
    playerOptions = player
    danmakuOptions = danmaku
  }

  public func subscribeToLibraryItems(_ publisher: AnyPublisher<[any PlayableItem], Never>) {
    publisher
      .sink(receiveValue: { [weak self] newItems in
        self?.libraryItemList = newItems
      })
      .store(in: &cancellables)
  }

  public func subscribeToLibraryPlaylists(_ publisher: AnyPublisher<[any Playlist], Never>) {
    publisher
      .sink(receiveValue: { [weak self] newItems in
        self?.libraryPlaylist = newItems
      })
      .store(in: &cancellables)
  }

  private func bindingMaskShow() {
    player.$isMaskShow
      .sink { [weak self] _ in
        self?.objectWillChange.send()
      }
      .store(in: &cancellables)
  }

  func subscribeResource() {
    guard let item else { return }
    Task {
      for await resource in item.resourceStream {
        await MainActor.run { [weak self] in
          self?.logger.trace("resourceStream got")
          self?.streamResource = resource
        }
      }
    }
  }

  func destroy() {
    logger.info("destroy")
    player.resetPlayer()
    updatePlayInfo()
    danmaku.stopDanmakuStream()
    item = nil
    streamResource = nil
    #if DEBUG
      debugPrint(item?.id ?? "item is nil")
    #endif
  }

  // MARK: - methods of PlayerViewModel

  func handlePlayerStateChanged(_ layer: KSPlayerLayer, _ state: KSPlayerState) {
    #if DEBUG
      debugPrint("PlayerViewModel.handlePlayerStateChanged: \(state)")
    #endif
    switch state {
    case .buffering:
      break
    case .bufferFinished:
      Task { @MainActor in
        item?.setCDNLine()
      }
    case .error:
      getNextStream()
    default:
      break
    }
  }

  func handleSwipe(_ direction: UISwipeGestureRecognizer.Direction) {
    switch direction {
    default:
      player.mask(show: true)
    }
  }

  func handleKey(_ move: MoveCommandDirection) {
    switch move {
    case .down:
      if !isRecommendVisible {
        isRecommendVisible = true
      }
      player.mask(show: true)
    default:
      player.mask(show: true)
    }
  }
}

// MARK: - methods of Controller

extension PlayerManager {
  func toggleInfo() {
    guard player.isMaskShow else { return }
    isInfoVisible.toggle()
  }

  func toggleDanmaku() {
    guard player.isMaskShow else { return }
    if isDanmakuVisible {
      danmaku.stopDanmakuStream()
      isDanmakuVisible = false
    } else {
      danmaku.startDanmakuStream(options: danmakuOptions)
      isDanmakuVisible = true
    }
  }

  func updatePlayInfo() {
    item?.plusPlayCount()
    item?.setLastPlayTime()
    item?.setCDNLine()
    item?.saveInfo()
  }

  func getNextStream() {
    guard let stream = streamResource else { return }
    retryStreamIndex += 1
//    guard retryStreamIndex < stream.cdnList.count else {
//      logger.error("No more stream to play")
//      return
//    }
    if retryStreamIndex >= stream.cdnList.count {
      retryStreamIndex = 0
      item?.loadResource(line: stream.cdnList[0].id, rate: stream.rate)
    } else {
      item?.loadResource(line: stream.cdnList[retryStreamIndex].id, rate: stream.rate)
    }
  }

  func refreshStream() {
    item?.fetchInfo()
    item?.loadResource(line: streamResource?.line, rate: streamResource?.rate)
    if player.state == .paused {
      player.playerLayer?.play()
    }
  }

  func toggleFav() {
    if let isFav = item?.playerInfo.isFav, isFav {
      showUnfavConfirmation = true
    } else {
      performToggleFav()
    }
  }

  func confirmUnfav() {
    performToggleFav()
    showUnfavConfirmation = false
  }

  private func performToggleFav() {
    item?.toggleFav()
    objectWillChange.send()
    item?.saveInfo()
  }
}
