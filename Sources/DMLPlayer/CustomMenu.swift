//
//  CustomMenu.swift
//  DMLPlayer
//
//  Created by littleTurnip on 10/9/23.
//

import SwiftUI

// MARK: - CustomMenu

struct CustomMenu<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    GeometryReader { geo in
      VStack(spacing: 0) {
        content
      }
      .buttonStyle(CustomMenuButtonStyle())
      .background(.regularMaterial)
      .cornerRadius(20)
      .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomTrailing)
    }
    .padding(.bottom, 80)
  }
}

// MARK: - CustomMenuButtonStyle

struct CustomMenuButtonStyle: ButtonStyle {
  @Environment(\.isFocused) private var isFocused

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.horizontal, 40)
      .foregroundColor(isFocused ? .primary : .secondary)
      .frame(height: 64)
      .overlay {
        Rectangle()
          .fill(isFocused ? .white.opacity(0.4) : .clear)
          .frame(width: 1000, alignment: .center)
      }
  }
}
