//
//  PlayerViewModel.swift
//  DMLPlayer
//
//  Created by littleTurnip on 9/27/23.
//

import DMLPlayerProtocol
import KSPlayer
import OSLog
import SwiftUI

// MARK: - PlayerManager

public class PlayerManager: PlayerProtocol, @unchecked Sendable {
  let logger = Logger(subsystem: "DMLPlayer", category: "Player.Viewmodel")
  private var overlayTask: Task<Void, Never>?
  private var retryStreamIndex = -1
  private var retryCount = 0
  private let maxRetryCount = 3

  public var item: (any PlayableItem)?
  @MainActor
  public let playerCoordinator: PlayerCoordinator = KSVideoPlayer.Coordinator()
  public let danmakuCoordinator: DanmakuCoordinator = DanmakuContainer.Coordinator()
  public var playerOptions: PlayerOptions
  public var danmakuOptions: DanmakuOptions
  public var danmakuService: DanmakuService?

  @Published var streamResource: (any LiveResource)?

  @Published var isOverlayVisible = true
  @Published var isMenuVisible = false
  @Published var isInfoVisible = false
  @Published var isDanmakuVisible: Bool

  var controlletrZIndex: Double { isOverlayVisible ? 3.0 : 0 }

  public init(playerOptions: PlayerOptions, danmakuOptions: DanmakuOptions) {
    self.playerOptions = playerOptions
    self.danmakuOptions = danmakuOptions
    isDanmakuVisible = danmakuOptions.isDanmakuAutoPlay
    subscribeResource()
  }

  deinit {
    logger.trace("PlayerViewModel deinit")
  }

  public func updateItem(_ newItem: any PlayableItem) {
    danmakuService = nil
    item = newItem
    streamResource = newItem.currentResource
    danmakuService = newItem.danmakuService
    subscribeResource()
  }

  public func updateOptions(_ options: (PlayerOptions, DanmakuOptions)) {
    playerOptions = options.0
    danmakuOptions = options.1
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

  @MainActor func destroy() async {
    if let playerLayer = playerCoordinator.playerLayer {
      playerLayer.pause()
    }
    danmakuCoordinator.stopDanmakuStream()
    playerCoordinator.playerLayer = nil
  }

  // MARK: - methods of PlayerViewModel

  func handlePlayerStateChanged(_ layer: KSPlayerLayer, _ state: KSPlayerState) {
    #if DEBUG
      debugPrint("PlayerViewModel.handlePlayerStateChanged: \(state)")
    #endif
    switch state {
    case .prepareToPlay:
      break
    case .readyToPlay:
      break
    case .buffering:
      Task { @MainActor in
      }
    case .bufferFinished:
      Task { @MainActor in
        item?.setCDNLine()
      }
    case .paused:
      Task { @MainActor in
      }
    case .playedToTheEnd:
      break
    case .error:
      guard let stream = streamResource else { return }
      retryStreamIndex += 1
      guard retryStreamIndex < stream.cdnList.count else {
        logger.error("No more stream to play")
        return
      }
      Task { @MainActor in
        if retryStreamIndex >= stream.cdnList.count {
          item?.loadResource(line: stream.cdnList[0].id, rate: stream.rate)
        } else {
          item?.loadResource(line: stream.cdnList[retryStreamIndex].id, rate: stream.rate)
        }
      }
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
    case .up:
      showOverlay()
    case .down:
      hideOverlay()
    case .left:
      showOverlay()
    case .right:
      showOverlay()
    default:
      break
    }
  }

  private func startOverlayTask() {
    overlayTask?.cancel()
    overlayTask = Task {
      try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
      if Task.isCancelled == false {
        hideOverlay()
      }
    }
  }

  func showOverlay() {
    Task { @MainActor in
      isOverlayVisible = true
      startOverlayTask()
    }
  }

  func hideOverlay() {
    Task { @MainActor in
      isOverlayVisible = false
      overlayTask?.cancel()
      overlayTask = nil
    }
  }
}

// MARK: - methods of Controller

extension PlayerManager {
  func toggleResMenu() {
    guard isOverlayVisible else { return }
    isMenuVisible.toggle()
  }

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

  func updateItem() {
    item?.plusPlayCount()
    item?.setLastPlayTime()
    item?.update()
  }

  func refreshStream() {
    item?.loadResource(line: streamResource?.line, rate: streamResource?.rate)
  }

  func toggleFav() {
    item?.toggleFav()
    item?.update()
  }
}