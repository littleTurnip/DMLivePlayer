//
//  DMLPlayerView.swift
//  DMLPlayer
//
//  Created by littleTurnip on 6/5/23.
//
import DMLPlayerProtocol
import KSPlayer
import SwiftUI

public struct DMLPlayerView<Title: View, Source: View>: View {
  @Environment(\.dismiss)
  private var dismiss

  @EnvironmentObject var manager: PlayerManager
  private let titleView: Title
  private let sourceView: Source
  public init(
    @ViewBuilder title: @escaping () -> Title,
    @ViewBuilder source: @escaping () -> Source
  ) {
    titleView = title()
    sourceView = source()
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
      VideoControllerView(
        manager: manager,
        title: { titleView },
        source: { sourceView }
      )
      .opacity(manager.isOverlayVisible ? 1 : 0)
      .zIndex(manager.controlletrZIndex)
      DanmakuContainer(
        coordinator: manager.danmakuCoordinator as! DanmakuContainer.Coordinator,
        service: manager.danmakuService,
        options: manager.danmakuOptions
      )
      .allowsHitTesting(false)
      .ignoresSafeArea(.all)
      .zIndex(2)
    }
    .preferredColorScheme(.dark)
    .onMoveCommand(perform: manager.handleKey)
    .onPlayPauseCommand(perform: manager.refreshStream)
    .onExitCommand { manager.isOverlayVisible ? manager.hideOverlay() : dismiss() }
    .onDisappear {
      manager.updateItem()
      Task { await manager.destroy() }
    }
  }
}
