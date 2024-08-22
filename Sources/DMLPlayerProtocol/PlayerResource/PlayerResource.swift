//
//  PlayerResource.swift
//
//
//  Created by littleTurnip on 3/1/24.
//
import OSLog
import SwiftUI

// MARK: - PlayableItem

public protocol PlayableItem: ObservableObject, Identifiable {
  associatedtype LiveInfo: RoomInfo
  associatedtype Platform: RawRepresentable<String>
  associatedtype PlayerPlaylist: Playlist
  var id: String { get }
  var platform: Platform { get }
  var roomID: String { get }
  var helperID: String? { get }
  var liveInfo: LiveInfo { get set }

  // MARK: - local properties

  var playerInfo: PlayInfo { get set }
  var currentPlaylist: PlayerPlaylist? { get }
  var currentResource: LiveResource? { get set }
  var danmakuService: DanmakuService? { get }
  /// An `AsyncStream` of `PlayerResource` objects.
  var resourceStream: AsyncStream<LiveResource?> { get }
  var resourceContinuation: AsyncStream<LiveResource?>.Continuation? { get set }
  init(playerArgs: PlayInfo?, with liveInfo: LiveInfo)

  func saveInfo()
  func fetchInfo()
  func play(with player: any PlayerProtocol)
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
  var id: String { "\(platform.rawValue)-\(roomID)" }
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
    logger.trace("loadStream id: \(self.id) line: \(line ?? "nil") rate: \(rate ?? 0)")
    Task { @MainActor in
      guard liveInfo.roomStatus != .offline else {
        return
      }
      let streamResource = await self.fetchResource(line: line, rate: rate)
      #if DEBUG
        debugPrint("streamResource: \(streamResource.debugDescription)")
      #endif
      await MainActor.run {
        currentResource = streamResource
        self.updateResource(with: streamResource)
      }
    }
  }
}

public extension PlayableItem {
  static func timeAsc(lhs: any PlayableItem, rhs: any PlayableItem) -> Bool {
    lhs.playerInfo.lastPlay < rhs.playerInfo.lastPlay
  }

  static func timeDesc(lhs: any PlayableItem, rhs: any PlayableItem) -> Bool {
    lhs.playerInfo.lastPlay > rhs.playerInfo.lastPlay
  }

  static func playCountAsc(lhs: any PlayableItem, rhs: any PlayableItem) -> Bool {
    lhs.playerInfo.playCount < rhs.playerInfo.playCount
  }

  static func playCountDesc(lhs: any PlayableItem, rhs: any PlayableItem) -> Bool {
    lhs.playerInfo.playCount > rhs.playerInfo.playCount
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
