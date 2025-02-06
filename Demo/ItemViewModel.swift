//
//  ItemViewModel.swift
//  Demo
//
//  Created by littleTurnip on 2/5/25.
//

import Combine
import DMLPlayerProtocol
import Foundation

// MARK: - LiveInfo

struct LiveInfo: RoomInfo {
  let roomID: String
  var helperID: String?
  var streamerName: String?
  var streamerAvatar: URL?
  var heat: Int = 0
  var roomStatus: RoomStatus
  var roomName: String?
  var roomCover: URL?
  var description: String?
  var lastLive: Date?
}

// MARK: - Entry

struct Entry: DMLPlayerProtocol.PlaylistEntry, Hashable {
  var id: String

  static func == (lhs: Entry, rhs: Entry) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - Playlist

struct Playlist: DMLPlayerProtocol.Playlist, Hashable {
  var id: UUID
  var name: String
  var entries: [Entry]

  static func == (lhs: Playlist, rhs: Playlist) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - Platform

enum Platform: String {
  case other
}

// MARK: - ItemViewModel

final class ItemViewModel: PlayableItem {
  var id: String
  var roomID: String
  var liveInfo: LiveInfo
  var helperID: String?
  var playerInfo: DMLPlayerProtocol.PlayInfo
  var playlists: Set<Playlist>
  var currentResource: (any DMLPlayerProtocol.Resource)?

  var danmakuService: (any DMLPlayerProtocol.DanmakuService)?

  var resourceContinuation: AsyncStream<(any DMLPlayerProtocol.Resource)?>.Continuation?

  init(playerArgs: PlayInfo? = nil, with liveInfo: LiveInfo) {
    self.id = UUID().uuidString
    self.roomID = liveInfo.roomID
    self.playerInfo = PlayInfo()
    self.liveInfo = liveInfo
    self.playlists = Set()
  }

  func saveInfo() {}

  func fetchInfo() {}

  func play(with player: any DMLPlayerProtocol.PlayerProtocol) {}

  func fetchResource(line: String?, rate: Int?) async -> (any DMLPlayerProtocol.Resource)? {
    nil
  }
}

// final class ItemViewModel: PlayableItem {
//  enum LoadState {
//    case loading
//    case loaded
//    case failed
//  }
//
//  @Published var showOfflineToast = false
//  @Published var currentResource: Resource?
//  @Published var liveInfo: LiveInfo
//  @Published var playerInfo: PlayInfo
//  @Published var loadState: LoadState?
//
//  let store = Store.shared
//  let platform: Platform
//  let roomID: String
//  var helperID: String?
//  var playlists: Set<Playlist> = []
//  var resourceContinuation: AsyncStream<LiveResource?>.Continuation?
//
//  private let logger = Logger(subsystem: "com.lib-hub.turnip", category: "Item.Viewmodel")
//  private var _danmakuService: DanmakuService?
//
//  var danmakuService: DanmakuService? {
//    if _danmakuService == nil {
//      let platformInstance = platform
//      let helperID = platformInstance == .bili ? AppSettings.shared.biliUid : helperID
//      _danmakuService = platformInstance.danmakuSocket(roomID: roomID, helperID: helperID)
//    }
//    return _danmakuService
//  }
//
//  init(playerArgs: PlayInfo? = nil, with liveInfo: LiveInfo) {
//    self.platform = liveInfo.platform
//    self.roomID = liveInfo.roomID
//    self.helperID = liveInfo.helperID
//    self.loadState = .none
//    self.playerInfo = playerArgs ?? store.getPlayInfo(from: liveInfo)
//    self.liveInfo = liveInfo
//
//    logger.trace("Init \(self.id, privacy: .public) ViewModel with liveInfo")
//  }
//
//  deinit {
//    resourceContinuation?.finish()
//    logger.trace("Deinit \(self.id, privacy: .public) ViewModel")
//  }
//
//  @MainActor
//  func play(with player: any PlayerProtocol) {
//    let playerOptions = PlayerOptions.generateOptions(self)
//    let danmakuOptions = DanmakuOptions.getFromSetting()
//    player.updateOptions(playerOptions, danmakuOptions)
//
//    switch liveInfo.roomStatus {
//    case .live:
//      player.updateItem(self)
//      player.playlists = Array(playlists)
//      loadResource()
//      player.isVisible = true
//
//    case .replay:
//      player.updateItem(self)
//      player.playlists = Array(playlists)
//      loadResource()
//      player.isVisible = true
//
//    case .offline:
//      showOfflineToast = true
//    }
//  }
//
//  func saveInfo() {
//    checkIsSync()
//    logger.debug("""
//      save info change:
//      playCount: \(self.playerInfo.playCount)
//      isFav: \(self.playerInfo.isFav)
//      lastPlayTime: \(self.playerInfo.lastPlay)
//      savedCdnLine: \(self.playerInfo.cdnLine ?? "nil")
//      isSync: \(self.playerInfo.isSync)
//      playlists: \(self.playlists)
//      """)
//    store.saveToCoreData(withInfo: liveInfo, playInfo: playerInfo)
//  }
//
//  func fetchInfo() {
//    logger.debug("fetch info from api")
//    Task {
//      await store.updateItem(liveInfo)
//    }
//  }
//
//  func addToPlaylist() {
//    store.addNewPlaylist(with: [liveInfo.toPlaylistEntry])
//  }
//
//  func removeFromPlaylist(_ playlist: Playlist) {
//    store.removePlaylistEntry(liveInfo.toPlaylistEntry, from: playlist.id)
//  }
//
//  func delete() {
//    store.deleteForCoreData(withInfo: liveInfo)
//  }
//
//  func toggleFav() {
//    playerInfo.isFav.toggle()
//    saveInfo()
//  }
//
//  func checkIsSync() {
//    playerInfo.isSync = !playlists.isEmpty || playerInfo.isFav
//  }
//
//  func fetchResource(line: String? = nil, rate: Int? = nil) async -> LiveResource? {
//    let platformInstance = platform
//    do {
//      if liveInfo.roomStatus != .offline {
//        return try await platformInstance.api.getLiveStream(
//          roomID: liveInfo.roomID,
//          helperID: liveInfo.helperID ?? "",
//          line: line ?? playerInfo.cdnLine,
//          rate: rate)
//      } else {
//        return nil
//      }
//    } catch {
//      print("Failed to fetch stream resource: \(error)")
//      return nil
//    }
//  }
// }
