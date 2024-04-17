//
//  VideoControllerView.swift
//  DMLPlayer
//
//  Created by littleTurnip on 6/1/23.
//

import KSPlayer
import SwiftUI

// MARK: - ControllerFocusState

enum ControllerFocusState {
  case controller
  case recommend
}

// MARK: - VideoControllerView

@available(tvOS 16, *)
struct VideoControllerView<Title: View, Info: View, Recommend: View>: View {
  @EnvironmentObject var manager: PlayerManager
  @State private var isLineMenuVisible = false
  @State private var isResMenuVisible = false
  @FocusState var controllerFocused: ControllerFocusState?

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
        .opacity(manager.playerCoordinator.state == .bufferFinished ? 0 : 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      title
      controller
        .focusSection()
        .focused($controllerFocused, equals: .controller)
      recommend
        .focusSection()
        .focused($controllerFocused, equals: .recommend)
    }
    .background(overlayGradient)
    .offset(y: manager.isRecommendVisible ? 0 : 240)
    .onChange(of: controllerFocused) { newFocus in
      switch newFocus {
      case .controller:
        manager.isRecommendVisible = false
      case .recommend:
        manager.isRecommendVisible = true
      case .none:
        break
      }
    }
  }

  var controller: some View {
    HStack(alignment: .center, spacing: 20) {
      info
      Button(action: manager.toggleFav) {
        manager.item?.playerInfo.isFav ?? false
          ? Image(systemName: "star.fill").foregroundColor(.yellow)
          : Image(systemName: "star").foregroundColor(.secondary)
      }
      .disabled(!manager.isOverlayVisible)
      Button(action: manager.refreshStream) {
        Image(systemName: "arrow.clockwise")
      }
      .disabled(!manager.isOverlayVisible)
      Spacer()
      resourceMenu
      lineMenu
      danmakuToggle
      infoPanel
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
              Text(rate.resolution)
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
        manager.isDanmakuVisible
          ? Image(systemName: "list.bullet.rectangle.fill")
          : Image(systemName: "list.bullet.rectangle")
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
      if let videoinfo = manager.playerCoordinator.playerLayer?.player.tracks(mediaType: .video).first(where: { $0.isEnabled })?.formatDescription {
        Text("Video Codec: \(videoinfo.mediaSubType.description)")
        Text("Resolution: \(videoinfo.dimensions.width) x \(videoinfo.dimensions.height)")
      }
      if let info = manager.playerCoordinator.playerLayer?.player.dynamicInfo {
        Text("FPS: \(String(format: "%.2f", info.displayFPS))")
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
    Gradient.Stop(color: .black.opacity(0.9), location: 1),
  ],
  startPoint: .top,
  endPoint: .bottom
)

private extension VideoControllerView {
  // MARK: - InfoButtonStyle

  private struct InfoButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .foregroundColor(isFocused ? .primary : .secondary)
        .background(isFocused ? .white.opacity(0.3) : .clear)
    }
  }

  // MARK: - ControllerButtonStyle

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
