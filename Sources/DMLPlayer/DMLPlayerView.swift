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

  @StateObject var vm: PlayerViewModel
  private let titleView: Title
  private let sourceView: Source
  public init(
    _ item: any PlayableItem,
    viewmodelFactory: @escaping (any PlayableItem) -> PlayerViewModel,
    @ViewBuilder title: @escaping () -> Title,
    @ViewBuilder source: @escaping () -> Source
  ) {
    _vm = StateObject(wrappedValue: viewmodelFactory(item))
    titleView = title()
    sourceView = source()
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      if let url = vm.streamResource?.url {
        KSVideoPlayer(
          coordinator: vm.playerCoordinator,
          url: url,
          options: vm.playerOptions
        )
        .onStateChanged(vm.handlePlayerStateChanged)
        .onSwipe(vm.handleSwipe)
        .onAppear { vm.showOverlay() }
        .background(Color.black)
        .ignoresSafeArea(.all)
        .zIndex(1)
      }
      VideoControllerView(
        viewmodel: vm,
        title: { titleView },
        source: { sourceView }
      )
      .opacity(vm.isOverlayVisible ? 1 : 0)
      .zIndex(vm.controlletrZIndex)
      DanmakuContainer(
        coordinator: vm.danmakuCoordinator,
        options: vm.danmakuOptions
      )
      .allowsHitTesting(false)
      .ignoresSafeArea(.all)
      .zIndex(2)
    }
    .preferredColorScheme(.dark)
    .onMoveCommand(perform: vm.handleKey)
    .onPlayPauseCommand(perform: vm.refreshStream)
    .onExitCommand { vm.isOverlayVisible ? vm.hideOverlay() : dismiss() }
    .onDisappear {
      vm.saveInfoChange()
      Task { await vm.destroy() }
    }
  }
}
