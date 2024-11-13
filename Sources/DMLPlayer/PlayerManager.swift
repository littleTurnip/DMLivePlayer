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

  let player: KSVideoPlayer.Coordinator
  let danmaku: DanmakuContainer.Coordinator

  private var cancellables: Set<AnyCancellable> = []
  private var overlayHideManager: DelayActionManager?
  private var retryStreamIndex = -1

  public var playerOptions: PlayerOptions
  public var danmakuOptions: DanmakuOptions

  @Published public var currentItem: (any PlayableItem)?
  @Published public var playlists: [any Playlist] = []
  @Published public var libraryItemList: [any PlayableItem] = []
  @Published public var isVisible = false
  @Published public var overlayVisible = false
  @Published public var showRecommend = false

  @Published var resource: (any Resource)?
  @Published var showInfo = false
  @Published var showDanmaku: Bool
  @Published var showUnfavConfirmation = false
  @Published var showNotPlayingAlert = false

  public init(playerOptions: PlayerOptions? = nil, danmakuOptions: DanmakuOptions = DanmakuOptions.default) {
    if let playerOptions {
      self.playerOptions = playerOptions
    } else {
      self.playerOptions = PlayerOptions()
    }
    self.danmakuOptions = danmakuOptions
    showDanmaku = danmakuOptions.layer.isAutoPlay
    player = KSVideoPlayer.Coordinator()
    danmaku = DanmakuContainer.Coordinator()
  }

  deinit {
    logger.trace("PlayerViewModel deinit")
  }

  public func updateItem(_ newItem: any PlayableItem) {
    logger.info("update item: \(newItem.id)")
    danmaku.stopDanmakuStream()
    updatePlayInfo()
    currentItem = newItem
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

  func subscribeResource() {
    guard let currentItem else { return }
    Task {
      for await resource in currentItem.resourceStream {
        await MainActor.run { [weak self] in
          self?.logger.trace("resourceStream got")
          self?.resource = resource
        }
      }
    }
  }

  func destroy() {
    logger.info("destroy")
    player.resetPlayer()
    updatePlayInfo()
    danmaku.stopDanmakuStream()
    currentItem = nil
    resource = nil
    #if DEBUG
      debugPrint(currentItem?.id ?? "item is nil")
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
        currentItem?.setCDNLine()
      }
    case .error:
      getNextStream()
    default:
      break
    }
  }

  @MainActor
  func showOverlay() {
    overlayVisible = true
    scheduleOverlayHide()
  }

  @MainActor
  func hideOverlay() {
    showRecommend = false
    overlayVisible = false
    cancelOverlayHide()
  }

  private func scheduleOverlayHide() {
    let delay = playerOptions.autoHideDelay

    if overlayHideManager == nil {
      overlayHideManager = DelayActionManager(interval: delay) { [weak self] in
        await self?.hideOverlay()
      }
    }
    Task {
      await overlayHideManager?.resetDelay()
    }
  }

  private func cancelOverlayHide() {
    Task {
      await overlayHideManager?.cancel()
      overlayHideManager = nil
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
      if !showRecommend {
        showRecommend = true
      }
      showOverlay()
    default:
      showOverlay()
    }
  }

  func handleExit() {
    guard overlayVisible else { isVisible = false; return }
    if showRecommend {
      showRecommend = false
    } else {
      hideOverlay()
    }
  }
}

// MARK: - methods of Controller

extension PlayerManager {
  func toggleInfo() {
    guard overlayVisible else { return }
    showInfo.toggle()
  }

  func toggleDanmaku() {
    guard overlayVisible else { return }
    if showDanmaku {
      danmaku.stopDanmakuStream()
      showDanmaku = false
    } else {
      danmaku.startDanmakuStream(options: danmakuOptions)
      showDanmaku = true
    }
  }

  func updatePlayInfo() {
    currentItem?.plusPlayCount()
    currentItem?.setLastPlayTime()
    currentItem?.setCDNLine()
    currentItem?.saveInfo()
  }

  func getNextStream() {
    guard let stream = resource else { return }
    retryStreamIndex += 1
//    guard retryStreamIndex < stream.cdnList.count else {
//      logger.error("No more stream to play")
//      return
//    }
    if retryStreamIndex >= stream.cdnList.count {
      retryStreamIndex = 0
      currentItem?.loadResource(line: stream.cdnList[0].id, rate: stream.rate)
    } else {
      currentItem?.loadResource(line: stream.cdnList[retryStreamIndex].id, rate: stream.rate)
    }
  }

  func refreshStream() {
    currentItem?.fetchInfo()
    currentItem?.loadResource(line: resource?.line, rate: resource?.rate)
    if player.state == .paused {
      player.playerLayer?.play()
    }
  }

  func toggleFav() {
    if let isFav = currentItem?.playerInfo.isFav, isFav {
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
    currentItem?.toggleFav()
    objectWillChange.send()
    currentItem?.saveInfo()
  }
}
