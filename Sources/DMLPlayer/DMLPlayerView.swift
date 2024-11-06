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
  @Environment(\.dismiss) private var dismiss
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

  public var body: some View {
    if let url = manager.streamResource?.url {
      KSVideoPlayer(
        coordinator: manager.playerCoordinator,
        url: url,
        options: manager.playerOptions
      )
      .onStateChanged(manager.handlePlayerStateChanged)
      .background(Color.black)
      .ignoresSafeArea(.all)
      .overlay {
        DanmakuContainer(
          coordinator: manager.danmakuCoordinator as! DanmakuContainer.Coordinator,
          options: manager.danmakuOptions
        )
        .allowsHitTesting(false)
        .ignoresSafeArea(.all)
      }
      .overlay {
        GestureView(swipeAction: manager.handleSwipe, pressAction: { _ in })
          .focused($focusState, equals: .player)
          .opacity(!manager.playerCoordinator.isMaskShow ? 1 : 0)
        VideoControllerView(title: title, info: info, recommend: recommend)
          .focused($focusState, equals: .controller)
          .opacity(manager.playerCoordinator.isMaskShow ? 1 : 0)
      }

      .environmentObject(manager)
      .preferredColorScheme(.dark)
      .alert(
        Localized.Alert[.notPlaying],
        isPresented: $manager.showNotPlayingAlert
      ) {
        Button(Localized.Button[.confirm]) {
          manager.showNotPlayingAlert = false
          dismiss()
        }
      }
      .onMoveCommand(perform: manager.handleKey)
      .onPlayPauseCommand(perform: manager.refreshStream)
      .onExitCommand {
        if manager.playerCoordinator.isMaskShow {
          if manager.isRecommendVisible {
            manager.isRecommendVisible = false
          } else {
            manager.playerCoordinator.mask(show: false)
          }
        } else {
          dismiss()
        }
      }
      .onDisappear { manager.destroy() }
    }
  }
}
