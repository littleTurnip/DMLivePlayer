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

public class PlayerManager: PlayerProtocol, @unchecked Sendable {
  let logger = Logger(subsystem: "DMLPlayer", category: "Player.Viewmodel")
  private var overlayTask: Task<Void, Never>?
  private var cancellables: Set<AnyCancellable> = []
  private var retryStreamIndex = -1

  @MainActor public let playerCoordinator: PlayerCoordinator = KSVideoPlayer.Coordinator()
  public let danmakuCoordinator: DanmakuCoordinator = DanmakuContainer.Coordinator()
  public var playerOptions: PlayerOptions
  public var danmakuOptions: DanmakuOptions

  @Published public var item: (any PlayableItem)?
  @Published public var libraryItemList: [any PlayableItem] = []
  @Published public var isVisible = false

  @Published var streamResource: (any LiveResource)?

  @Published var isOverlayVisible = true
  @Published var isRecommendVisible = false
  @Published var isInfoVisible = false
  @Published var isDanmakuVisible: Bool

  var controlletrZIndex: Double { isOverlayVisible ? 3.0 : 0 }

  public init(playerOptions: PlayerOptions = PlayerOptions(), danmakuOptions: DanmakuOptions = DanmakuOptions()) {
    self.playerOptions = playerOptions
    self.danmakuOptions = danmakuOptions
    isDanmakuVisible = danmakuOptions.isDanmakuAutoPlay
    subscribeResource()
  }

  deinit {
    logger.trace("PlayerViewModel deinit")
  }

  @MainActor
  public func updateItem(_ newItem: any PlayableItem) {
    logger.info("update item: \(newItem.id)")
    danmakuCoordinator.cleanDanmakuService()
    isDanmakuVisible = false
    playerCoordinator.playerLayer?.pause()
    item?.update()
    item = newItem
    streamResource = newItem.currentResource
    danmakuCoordinator.setDanmakuService(newItem.danmakuService)
    if danmakuOptions.isDanmakuAutoPlay {
      danmakuCoordinator.startDanmakuStream(options: danmakuOptions)
      isDanmakuVisible = true
    }
    subscribeResource()
  }

  public func updateOptions(_ options: (PlayerOptions, DanmakuOptions)) {
    playerOptions = options.0
    danmakuOptions = options.1
  }

  public func subscribeToLibraryItems(_ publisher: AnyPublisher<[any PlayableItem], Never>) {
    publisher
      .sink(receiveValue: { [weak self] newItems in
        self?.libraryItemList = newItems
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

  @MainActor func destroy() async {
    if let playerLayer = playerCoordinator.playerLayer {
      playerLayer.pause()
    }
    updateItem()
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
      Task { @MainActor in }
    case .bufferFinished:
      Task { @MainActor in
        item?.setCDNLine()
      }
    case .paused:
      Task { @MainActor in }
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
    debugPrint("handleKey: \(move)")
    switch move {
    case .up:
      showOverlay()
    case .down:
      showOverlay()
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
    objectWillChange.send()
    item?.update()
  }
}
