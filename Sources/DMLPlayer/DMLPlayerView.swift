//
//  DMLPlayerView.swift
//  DMLPlayer
//
//  Created by littleTurnip on 6/5/23.
//
import DMLPlayerProtocol
import KSPlayer
import SwiftUI

// MARK: - PlayerFocusState

enum PlayerFocusState {
  case player, controller
}

// MARK: - DMLPlayerView

public struct DMLPlayerView<Title: View, Info: View, Recommend: View>: View {
  @ObservedObject var manager: PlayerManager

  @FocusState private var focusState: PlayerFocusState?
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

  var confirmButton: some View {
    Button(Localized.Button[.confirm]) {
      manager.showNotPlayingAlert = false
      manager.isVisible = false
    }
  }

  public var body: some View {
    if let url = manager.resource?.url {
      KSVideoPlayer(
        coordinator: manager.player,
        url: url,
        options: manager.playerOptions
      )
      .onStateChanged(manager.handlePlayerStateChanged)
      .background(Color.black)
      .overlay { DanmakuContainer(coordinator: manager.danmaku, options: manager.danmakuOptions) }
      .ignoresSafeArea(.all)
      .overlay {
        GestureOverlay(perform: manager.handleSwipe)
          .focused($focusState, equals: .player)
          .opacity(!manager.overlayVisible ? 1 : 0)
        VideoControllerView(title: title, info: info, recommend: recommend)
          .focused($focusState, equals: .controller)
          .opacity(manager.overlayVisible ? 1 : 0)
      }
      .defaultFocus($focusState, .controller)
      .environmentObject(manager)
      .preferredColorScheme(.dark)
      .alert(
        Localized.Alert[.notPlaying],
        isPresented: $manager.showNotPlayingAlert,
        actions: { confirmButton }
      )
      .onMoveCommand(perform: manager.handleKey)
      .onPlayPauseCommand(perform: manager.refreshStream)
      .onExitCommand(perform: manager.handleExit)
      .onAppear { manager.showOverlay() }
      .onDisappear(perform: manager.destroy)
    }
  }
}
