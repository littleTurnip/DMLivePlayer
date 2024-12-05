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
  var playlists: Set<PlayerPlaylist> { get }
  var currentResource: Resource? { get set }
  var danmakuService: DanmakuService? { get }
  /// An `AsyncStream` of `PlayerResource` objects.
  var resourceStream: AsyncStream<Resource?> { get }
  var resourceContinuation: AsyncStream<Resource?>.Continuation? { get set }
  init(playerArgs: PlayInfo?, with liveInfo: LiveInfo)

  func saveInfo()
  func fetchInfo()

  @MainActor
  func play(with player: any PlayerProtocol)
  /// method to update livestream resource
  /// - Parameter newResource: `PlayerResource` object
  func updateResource(with newResource: Resource?)
  /// fetch livestream resource
  /// - Parameters:
  ///  - line: Name string representing the CDN line
  ///  - rate: Rate value for the stream
  func loadResource(line: String?, rate: Int?)
  func fetchResource(line: String?, rate: Int?) async -> Resource?
}

extension PlayableItem {
  public var id: String { "\(platform.rawValue)-\(roomID)" }
  var logger: Logger { Logger(subsystem: "DMLPlayer", category: "PlayableItem") }
}

/// add stream resource related methods
extension PlayableItem {
  public var resourceStream: AsyncStream<Resource?> {
    AsyncStream { [weak self] continuation in
      self?.resourceContinuation = continuation
    }
  }

  public func updateResource(with newResource: Resource?) {
    logger.trace("updateResource")
    resourceContinuation?.yield(newResource)
  }

  public func loadResource(line: String? = nil, rate: Int? = nil) {
    logger.trace("loadStream id: \(self.id) line: \(line ?? "nil") rate: \(rate ?? 0)")
    Task { @MainActor in
      guard liveInfo.roomStatus != .offline else {
        return
      }
      let streamResource = await self.fetchResource(line: line, rate: rate)
      #if DEBUG
      debugPrint("resource: \(streamResource.debugDescription)")
      #endif
      await MainActor.run {
        currentResource = streamResource
        self.updateResource(with: streamResource)
      }
    }
  }
}

extension PlayableItem {
  public static func timeAsc(lhs: any PlayableItem, rhs: any PlayableItem) -> Bool {
    lhs.playerInfo.lastPlay < rhs.playerInfo.lastPlay
  }

  public static func timeDesc(lhs: any PlayableItem, rhs: any PlayableItem) -> Bool {
    lhs.playerInfo.lastPlay > rhs.playerInfo.lastPlay
  }

  public static func playCountAsc(lhs: any PlayableItem, rhs: any PlayableItem) -> Bool {
    lhs.playerInfo.playCount < rhs.playerInfo.playCount
  }

  public static func playCountDesc(lhs: any PlayableItem, rhs: any PlayableItem) -> Bool {
    lhs.playerInfo.playCount > rhs.playerInfo.playCount
  }
}

extension PlayableItem {
  public func plusPlayCount() {
    playerInfo.playCount += 1
  }

  public func setCDNLine() {
    playerInfo.cdnLine = currentResource?.line
  }

  public func setLastPlayTime() {
    playerInfo.lastPlay = Date()
  }

  public func toggleFav() {
    playerInfo.isFav.toggle()
  }
}
