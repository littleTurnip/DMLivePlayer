//
//  PlayerResource.swift
//
//
//  Created by littleTurnip on 3/1/24.
//
import OSLog
import SwiftUI

// MARK: - PlayInfo

public struct PlayInfo: Sendable {
  public var isFav: Bool = false
  public var cdnLine: String?
  public var playCount: Int = 0
  public var lastPlay: Date = .init()
  public init(isFav: Bool = false, playCount: Int = 0, cdnLine: String? = nil, lastPlay: Date = Date()) {
    self.isFav = isFav
    self.playCount = playCount
    self.cdnLine = cdnLine
    self.lastPlay = lastPlay
  }
}

// MARK: - PlayableItem

public protocol PlayableItem: ObservableObject, Identifiable {
  associatedtype LiveInfo
  var id: String { get }
  var platform: String { get }
  var roomID: String { get }
  var helperID: String? { get }
  var liveInfo: LiveInfo { get set }

  // MARK: - local properties

//  var isFav: Bool { get set }
//  var savedCDN: String? { get set }
//  var playCount: Int { get set }
//  var lastPlayTime: Date { get set }

  var playerInfo: PlayInfo { get set }
  var currentResource: LiveResource? { get set }
  var danmakuService: DanmakuService? { get }
  /// An `AsyncStream` of `PlayerResource` objects.
  var resourceStream: AsyncStream<LiveResource?> { get }
  var resourceContinuation: AsyncStream<LiveResource?>.Continuation? { get set }
  init(playerArgs: PlayInfo?, with liveInfo: LiveInfo)

  func update()

  /// method to update livestream resource
  /// - Parameter newResource: `PlayerResource` object
  func updateResource(with newResource: LiveResource?)
  /// fetch livestream resource
  /// - Parameters:
  ///  - line: Name string representing the CDN line
  ///  - rate: Rate value for the stream
  func loadResource(line: String?, rate: Int?)
  func fetchResource(line: String?, rate: Int?) async -> LiveResource?
}

public extension PlayableItem {
  var logger: Logger { Logger(subsystem: "DMLPlayer", category: "PlayableItem") }
}

/// add stream resource related methods
public extension PlayableItem {
  var resourceStream: AsyncStream<LiveResource?> {
    AsyncStream { [weak self] continuation in
      self?.resourceContinuation = continuation
    }
  }

  func updateResource(with newResource: LiveResource?) {
    logger.trace("updateResource")
    resourceContinuation?.yield(newResource)
  }

  func loadResource(line: String? = nil, rate: Int? = nil) {
    logger.trace("loadStream")
    Task { @MainActor in
      let streamResource = await self.fetchResource(line: line, rate: rate)
      #if DEBUG
        debugPrint(streamResource.debugDescription)
      #endif
      await MainActor.run {
        currentResource = streamResource
        self.updateResource(with: streamResource)
      }
    }
  }
}

public extension PlayableItem {
  func plusPlayCount() {
    playerInfo.playCount += 1
  }

  func setCDNLine() {
    playerInfo.cdnLine = currentResource?.line
  }

  func setLastPlayTime() {
    playerInfo.lastPlay = Date()
  }

  func toggleFav() {
    playerInfo.isFav.toggle()
  }
}
