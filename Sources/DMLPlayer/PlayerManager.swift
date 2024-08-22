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
public class PlayerManager: PlayerProtocol {
  let logger = Logger(subsystem: "DMLPlayer", category: "Player.Viewmodel")
  private var overlayTask: Task<Void, Never>?
  private var cancellables: Set<AnyCancellable> = []
  private var retryStreamIndex = -1

  @Published public var playerCoordinator: PlayerCoordinator
  public let danmakuCoordinator: DanmakuCoordinator
  public var playerOptions: PlayerOptions
  public var danmakuOptions: DanmakuOptions

  @Published public var item: (any PlayableItem)?
  @Published public var currentPlaylist: (any Playlist)?
  @Published public var libraryItemList: [any PlayableItem] = []
  @Published public var libraryPlaylist: [any Playlist] = []
  @Published public var isVisible = false

  @Published var streamResource: (any LiveResource)?
  @Published var isPlaying = false
  @Published var isOverlayVisible = true
  @Published public var isRecommendVisible = false
  @Published var isInfoVisible = false
  @Published var isDanmakuVisible: Bool

  @Published var showUnfavConfirmation = false
  var controlletrZIndex: Double { isOverlayVisible ? 3.0 : 0 }

  public init(playerOptions: PlayerOptions = PlayerOptions(), danmakuOptions: DanmakuOptions = DanmakuOptions.default) {
    self.playerOptions = playerOptions
    self.danmakuOptions = danmakuOptions
    isDanmakuVisible = danmakuOptions.layer.isAutoPlay
    playerCoordinator = KSVideoPlayer.Coordinator()
    danmakuCoordinator = DanmakuContainer.Coordinator()
  }

  deinit {
    logger.trace("PlayerViewModel deinit")
  }

  public func updateItem(_ newItem: any PlayableItem) {
    logger.info("update item: \(newItem.id)")
    danmakuCoordinator.cleanDanmakuService()
    updatePlayInfo()
    item = newItem
    danmakuCoordinator.setDanmakuService(newItem.danmakuService)
    if danmakuOptions.layer.isAutoPlay {
      danmakuCoordinator.startDanmakuStream(options: danmakuOptions)
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
    playerCoordinator.resetPlayer()
    updatePlayInfo()
    danmakuCoordinator.stopDanmakuStream()
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
      isPlaying = false
    case .bufferFinished:
      isPlaying = true
      Task { @MainActor in
        item?.setCDNLine()
      }
    case .error:
      guard let stream = streamResource else { return }
      retryStreamIndex += 1
      guard retryStreamIndex < stream.cdnList.count else {
        logger.error("No more stream to play")
        return
      }
      if retryStreamIndex >= stream.cdnList.count {
        item?.loadResource(line: stream.cdnList[0].id, rate: stream.rate)
      } else {
        item?.loadResource(line: stream.cdnList[retryStreamIndex].id, rate: stream.rate)
      }
    default:
      break
    }
  }

  func handleSwipe(_ direction: UISwipeGestureRecognizer.Direction) {
    switch direction {
    default:
      showOverlay()
    }
  }

  func handleKey(_ move: MoveCommandDirection) {
    switch move {
    case .down:
      if !isRecommendVisible { isRecommendVisible = true }
    default:
      if !isRecommendVisible { showOverlay() }
    }
  }

  private func startOverlayTask() {
    logger.debug("startOverlayTask")
    overlayTask?.cancel()
    overlayTask = Task {
      try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
      if Task.isCancelled == false {
        hideOverlay()
        logger.debug("endOverlayTask")
      }
    }
  }

  public func showOverlay() {
    isOverlayVisible = true
    startOverlayTask()
  }

  public func hideOverlay() {
    isRecommendVisible = false
    isOverlayVisible = false
    overlayTask?.cancel()
    overlayTask = nil
  }
}

// MARK: - methods of Controller

extension PlayerManager {
  func toggleInfo() {
    guard isOverlayVisible else { return }
    isInfoVisible.toggle()
  }

  func toggleDanmaku() {
    guard isOverlayVisible else { return }
    if isDanmakuVisible {
      danmakuCoordinator.stopDanmakuStream()
      isDanmakuVisible = false
    } else {
      danmakuCoordinator.startDanmakuStream(options: danmakuOptions)
      isDanmakuVisible = true
    }
  }

  func updatePlayInfo() {
    item?.plusPlayCount()
    item?.setLastPlayTime()
    item?.setCDNLine()
    item?.updateInfo()
  }

  func refreshStream() {
    item?.loadResource(line: streamResource?.line, rate: streamResource?.rate)
    if playerCoordinator.state == .paused {
      playerCoordinator.playerLayer?.play()
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
    item?.updateInfo()
  }
}
