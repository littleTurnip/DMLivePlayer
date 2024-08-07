//
//  DMLPlayerView.swift
//  DMLPlayer
//
//  Created by littleTurnip on 6/5/23.
//
import DMLPlayerProtocol
import KSPlayer
import SwiftUI

public struct DMLPlayerView<Title: View, Info: View, Recommend: View>: View {
  @Environment(\.dismiss)
  private var dismiss
  @ObservedObject
  var manager: PlayerManager

  @FocusState private var controllerFocused: Bool
  private let title: () -> Title
  private let info: () -> Info
  private let recommend: () -> Recommend
  public init(
    _ manager: PlayerManager,
    @ViewBuilder title: @escaping () -> Title,
    @ViewBuilder info: @escaping () -> Info,
    @ViewBuilder recommend: @escaping () -> Recommend
  ) {
    self.manager = manager
    self.title = title
    self.info = info
    self.recommend = recommend
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      if let url = manager.streamResource?.url {
        KSVideoPlayer(
          coordinator: manager.playerCoordinator,
          url: url,
          options: manager.playerOptions
        )
        .onStateChanged(manager.handlePlayerStateChanged)
        .onSwipe(manager.handleSwipe)
        .onAppear { manager.showOverlay() }
        .background(Color.black)
        .ignoresSafeArea(.all)
        .zIndex(1)
      }
      VideoControllerView(title: title, info: info, recommend: recommend)
        .opacity(manager.isOverlayVisible ? 1 : 0)
        .zIndex(manager.controlletrZIndex)
      DanmakuContainer(
        coordinator: manager.danmakuCoordinator as! DanmakuContainer.Coordinator,
        options: manager.danmakuOptions
      )
      .allowsHitTesting(false)
      .ignoresSafeArea(.all)
      .zIndex(2)
    }
    .environmentObject(manager)
    .preferredColorScheme(.dark)
    .onMoveCommand(perform: manager.handleKey)
    .onPlayPauseCommand(perform: manager.refreshStream)
    .onExitCommand {
      if manager.isOverlayVisible {
        if manager.isRecommendVisible {
          manager.isRecommendVisible = false
        } else {
          manager.hideOverlay()
        }
      } else {
        dismiss()
      }
    }
    .onDisappear { manager.destroy() }
  }
}
