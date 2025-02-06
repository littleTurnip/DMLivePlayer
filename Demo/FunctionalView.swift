//
//  FunctionalView.swift
//  Demo
//
//  Created by littleTurnip on 2/5/25.
//

import DMLPlayer
import SwiftUI

struct FunctionalView: View {
  @EnvironmentObject var player: PlayerManager
  @ObservedObject var viewmodel: FunctionalViewModel

  @Environment(\.openURL) private var openURL

  var body: some View {
    HStack {
      VStack {
        Image(systemName: "antenna.radiowaves.left.and.right")
          .resizable()
          .scaledToFit()
          .foregroundStyle(.secondary)
        Text("Add Livestream")
          .font(.headline)
          .foregroundStyle(.secondary)
      }
      .frame(width: 500)
      Divider()
      VStack(alignment: .leading) {
        Section(header: urlSection) {
          TextField("input url", text: $viewmodel.url)
            .onSubmit(viewmodel.handleURL)
        }
        Section(header: optionsSection) {
          TextField("name", text: $viewmodel.roomName)
          TextField("cover", text: $viewmodel.coverUrl)
          TextField("danmaku", text: $viewmodel.danmakuUrl)
        }.disabled(!viewmodel.isOptionActive)
        HStack {
          Button("go") {
            viewmodel.decodeURL(using: openURL, with: player)
          }
        }
        #if DEBUG
        testButtons
        #endif
      }
    }
  }

  #if DEBUG
  private var testButtons: some View {
    HStack {
      ForEach(viewmodel.buttonsData, id: \.url) { buttonData in
        Button(buttonData.title) {
          viewmodel.url = buttonData.url
          viewmodel.roomName = buttonData.roomName
          viewmodel.coverUrl = buttonData.coverUrl
          viewmodel.streamerName = buttonData.streamerName
          viewmodel.danmakuUrl = buttonData.danmakuUrl
        }
      }
    }
  }
  #endif
  private var urlSection: some View {
    Label("stream url", systemImage: "link.badge.plus").foregroundStyle(.secondary)
  }

  private var optionsSection: some View {
    Label("options", systemImage: "gearshape").foregroundStyle(.secondary)
  }
}

#Preview {
  FunctionalView(viewmodel: .init())
}
