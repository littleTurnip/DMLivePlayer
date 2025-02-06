//
//  FunctionalViewModel.swift
//  Demo
//
//  Created by littleTurnip on 2/5/25.
//

import DMLPlayer
import SwiftUI

// MARK: - FunctionalViewModel

class FunctionalViewModel: ObservableObject, @unchecked Sendable {
  @Published var url = ""
  @Published var roomName = ""
  @Published var danmakuUrl = ""
  @Published var coverUrl = ""
  @Published var isOptionActive = false
  @Published var navigateToLive = false
  @Published var isSuccessShow = false
  @Published var itemvm: ItemViewModel?
  var streamerName = "web"
  var streamerAvatar: URL?

  func handleURL() {
    if let url = URL(string: url) {
      if url.scheme == "http" || url.scheme == "https" {
        isOptionActive = true
        roomName = url.lastPathComponent
        if let parts = url.host?.split(separator: ".") {
          if parts.count >= 2 {
            streamerName = parts.suffix(2).joined(separator: ".")
          }
        }
        Task {
          streamerAvatar = await getFaviconURL(url: url)
        }
      }
    }
  }

  func getFaviconURL(url: URL) async -> URL? {
    nil
  }

  func decodeURL(using openURL: OpenURLAction, with player: PlayerManager) {
    if let url = URL(string: url) {
      switch url.scheme {
      case "http", "https":
        addLivestream(player)
      default:
        openURL(url)
      }
    }
  }

  func addLivestream(_ player: PlayerManager) {
    let liveInfo = LiveInfo(
      roomID: "[\(roomName)]-[\(url)]",
      helperID: danmakuUrl,
      streamerName: streamerName,
      streamerAvatar: streamerAvatar,
      heat: 0,
      roomStatus: .live,
      roomName: roomName,
      roomCover: URL(string: coverUrl))

    itemvm = ItemViewModel(with: liveInfo)
    itemvm?.loadResource()
    Task {
      await itemvm?.play(with: player)
    }
  }
}

#if DEBUG
struct TestButtonData {
  let title: String
  let url: String
  let roomName: String
  let coverUrl: String
  let streamerName: String
  let danmakuUrl: String
}

extension FunctionalViewModel {
  var buttonsData: [TestButtonData] { [
    TestButtonData(
      title: "test-hls1",
      url: "https://cph-msl.akamaized.net/hls/live/2000341/test/master.m3u8",
      roomName: "Tears of Steel",
      coverUrl: "https://raw.githubusercontent.com/TurnipProject/Turnip-Player/main/test/test-hls1.png",
      streamerName: "test-hls1",
      danmakuUrl: "https://test.lib-hub.com/danmaku"),
    TestButtonData(
      title: "test-hls2",
      url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
      roomName: "Big Buck Bunny",
      coverUrl: "https://raw.githubusercontent.com/TurnipProject/Turnip-Player/main/test/test-hls2.png",
      streamerName: "test-hls2",
      danmakuUrl: "https://test.lib-hub.com/danmaku"),
    TestButtonData(
      title: "test-dash",
      url: "https://cdn.bitmovin.com/content/assets/art-of-motion-dash-hls-progressive/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd",
      roomName: "Art of Motion (dash)",
      coverUrl: "https://cdn.bitmovin.com/content/assets/art-of-motion-dash-hls-progressive/poster.jpg",
      streamerName: "test-dash",
      danmakuUrl: "https://test.lib-hub.com/danmaku"),
    TestButtonData(
      title: "test-mp4",
      url: "https://cdn.bitmovin.com/content/assets/art-of-motion-dash-hls-progressive/MI201109210084_mpeg-4_hd_high_1080p25_10mbits.mp4",
      roomName: "Art of Motion (1080p 25fps)",
      coverUrl: "https://cdn.bitmovin.com/content/assets/art-of-motion-dash-hls-progressive/poster.jpg",
      streamerName: "test-mp4",
      danmakuUrl: "https://test.lib-hub.com/danmaku"),
  ] }
}
#endif
