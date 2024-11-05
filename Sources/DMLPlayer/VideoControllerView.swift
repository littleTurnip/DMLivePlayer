//
//  VideoControllerView.swift
//  DMLPlayer
//
//  Created by littleTurnip on 6/1/23.
//

import KSPlayer
import SwiftUI

// MARK: - ControllerFocusState

enum ControllerFocusState: Hashable {
  case controller(Controller)
  case recommend
}

// MARK: ControllerFocusState.Controller

extension ControllerFocusState {
  enum Controller: Hashable {
    case favToggle
    case refresh
    case danmakuToggle
    case lineMenu
    case resMenu
    case infoPanal
  }
}

// MARK: - VideoControllerView

@available(tvOS 16, *)
struct VideoControllerView<Title: View, Info: View, Recommend: View>: View {
  @EnvironmentObject var manager: PlayerManager
  @State private var isLineMenuVisible = false
  @State private var isResMenuVisible = false
  @State private var recommendHeight: CGFloat = 0
  @FocusState private var controllerFocused: ControllerFocusState?

  private let title: Title
  private let info: Info
  private let recommend: Recommend
  init(
    @ViewBuilder title: () -> Title,
    @ViewBuilder info: () -> Info,
    @ViewBuilder recommend: () -> Recommend
  ) {
    self.title = title()
    self.info = info()
    self.recommend = recommend()
  }

  public var body: some View {
    VStack(alignment: .leading) {
      ProgressView()
        .opacity(manager.isPlaying ? 0 : 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      title
      controller
        .focusSection()
      GeometryReader { geometry in
        recommend
          .onAppear { recommendHeight = geometry.size.height }
          .focusSection()
          .focused($controllerFocused, equals: .recommend)
      }
    }
    .background(overlayGradient)
    .offset(y: manager.isRecommendVisible ? 60 : recommendHeight - 90)
    .onChange(of: manager.isRecommendVisible) { isVisible in
      if !isVisible { controllerFocused = .controller(.refresh) }
    }
    .onChange(of: controllerFocused) { newFocus in
      switch newFocus {
      case .recommend:
        manager.isRecommendVisible = true
      default:
        break
      }
    }
  }

  var controller: some View {
    HStack(alignment: .center, spacing: 20) {
      info
      Button(action: manager.toggleFav) {
        if let isFav = manager.item?.playerInfo.isFav {
          Image(systemName: "star")
            .symbolVariant(isFav ? .fill : .none)
            .foregroundColor(isFav ? .yellow : .secondary)
        }
      }
      .focused($controllerFocused, equals: .controller(.favToggle))
      .alert(Localized.Alert[.favMessage], isPresented: $manager.showUnfavConfirmation) {
        Button(Localized.Button[.confirmUnfav], role: .destructive) { manager.confirmUnfav() }
        Button(Localized.Button[.cancel], role: .cancel) {}
      }
      .disabled(!manager.isOverlayVisible)

      Button(action: manager.refreshStream) {
        Image(systemName: "arrow.clockwise")
      }
      .focused($controllerFocused, equals: .controller(.refresh))
      .disabled(!manager.isOverlayVisible)
      Spacer()
      resourceMenu
        .focused($controllerFocused, equals: .controller(.resMenu))
      lineMenu
        .focused($controllerFocused, equals: .controller(.lineMenu))
      danmakuToggle
        .focused($controllerFocused, equals: .controller(.danmakuToggle))
      infoPanel
        .focused($controllerFocused, equals: .controller(.infoPanal))
    }
    .buttonStyle(ControllerButtonStyle())
  }

  @ViewBuilder
  private var resourceMenu: some View {
    if let stream = manager.streamResource {
      let label = { Text(stream.resolution) }
      let content = {
        ForEach(stream.rateList, id: \.id) { rate in
          Button(
            action: { manager.item?.loadResource(line: stream.line, rate: rate.id) },
            label: {
              HStack {
                if rate.id == stream.rate { Image(systemName: "checkmark") }
                Text(rate.resolution)
              }
            }
          )
        }
      }

      if #available(tvOS 17, *) {
        Menu(content: content, label: label)
      } else {
        Button(action: { isResMenuVisible.toggle() }, label: label)
          .fullScreenCover(isPresented: $isResMenuVisible) {
            CustomMenu(content: content)
          }
      }
    } else {
      Image(systemName: "antenna.radiowaves.left.and.right.slash")
        .focusable(false)
    }
  }

  @ViewBuilder
  private var lineMenu: some View {
    if let stream = manager.streamResource {
      let label = { Image(systemName: "waveform") }
      let content = {
        ForEach(stream.cdnList, id: \.id) { line in
          Button(
            action: { manager.item?.loadResource(line: line.id, rate: stream.rate) },
            label: {
              HStack {
                if line.id == stream.line { Image(systemName: "checkmark") }
                Text(line.cdnName)
              }
            }
          )
        }
      }

      if #available(tvOS 17, *) {
        Menu(content: content, label: label)
      } else {
        Button(action: { isLineMenuVisible.toggle() }, label: label)
          .fullScreenCover(isPresented: $isLineMenuVisible) {
            CustomMenu(content: content)
          }
      }
    } else {
      Image(systemName: "waveform.slash")
        .focusable(false)
    }
  }

  private var danmakuToggle: some View {
    Button(
      action: manager.toggleDanmaku,
      label: {
        Image(systemName: "list.bullet.rectangle")
          .symbolVariant(manager.isDanmakuVisible ? .fill : .none)
      }
    )
  }

  private var infoPanel: some View {
    Button(
      action: manager.toggleInfo,
      label: { Image(systemName: "info.circle") }
    )
    .fullScreenCover(isPresented: $manager.isInfoVisible) {
      ZStack {
        VStack(alignment: .leading) { mediaInfo }
          .frame(maxWidth: 500, alignment: .topLeading)
          .font(consoleFont)
          .padding(10)
          .background(Color.black.opacity(0.8))
          .foregroundStyle(.white)
          .clipShape(RoundedRectangle(cornerRadius: 10))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
  }

  private var mediaInfo: some View {
    Group {
      Text("id: \(manager.item?.id ?? "N/A")")
      Text("helperID: \(manager.item?.helperID ?? "N/A")")
      Text("playCount: \(manager.item?.playerInfo.playCount ?? 0)")
      Text("line: \(manager.streamResource?.line ?? "N/A")")
      Text("rate: \(manager.streamResource?.rate ?? 0)")
      if let video = manager.playerCoordinator.playerLayer?.player.tracks(mediaType: .video).first(where: { $0.isEnabled }) {
        Text("Video Codec: \(video.mediaSubType.description)")
        Text("Resolution: \(Int(video.naturalSize.width)) x \(Int(video.naturalSize.height))")
      }
      if let info = manager.playerCoordinator.playerLayer?.player.dynamicInfo {
        Text("FPS: \(String(format: "%.2f", info.displayFPS))")
        Text("Frame Drop: \(info.droppedVideoFrameCount + info.droppedVideoPacketCount)")
        Text("Video Bitrate: \(info.videoBitrate.bytesToMegabytes()) MB/s")
        Text("Audio Bitrate: \(info.audioBitrate.bytesToKilobytes()) KB/s")
      }
    }
  }
}

private let consoleFont = Font.system(size: 24).monospaced()
private let overlayGradient = LinearGradient(
  stops: [
    Gradient.Stop(color: .black.opacity(0), location: 0.22),
    Gradient.Stop(color: .black.opacity(0.85), location: 0.7),
  ],
  startPoint: .top,
  endPoint: .bottom
)

// MARK: VideoControllerView.ControllerButtonStyle

private extension VideoControllerView {
  private struct ControllerButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .padding(10)
        .background(isFocused ? .white.opacity(0.3) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
  }
}
