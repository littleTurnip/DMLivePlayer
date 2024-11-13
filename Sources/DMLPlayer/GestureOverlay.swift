//
//  GestureOverlay.swift
//  DMLPlayer
//
//  Created by littleTurnip on 11/13/24.
//

import SwiftUI

public typealias Action = (UISwipeGestureRecognizer.Direction) -> Void

// MARK: - GestureOverlay

public struct GestureOverlay: UIViewRepresentable {
  let swipeAction: Action
  public init(perform swipeAction: @escaping Action) {
    self.swipeAction = swipeAction
  }

  public func makeUIView(context _: Context) -> UIView {
    TVGestureHelper(swipeAction: swipeAction)
  }

  public func updateUIView(_: UIView, context _: Context) {}
}

// MARK: - TVGestureHelper

public class TVGestureHelper: UIControl {
  public let swipeAction: Action

  public init(swipeAction: @escaping Action) {
    self.swipeAction = swipeAction
    super.init(frame: .zero)

    let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
    for direction in directions {
      let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
      recognizer.direction = direction
      addGestureRecognizer(recognizer)
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func handleSwipeGesture(gesture: UIGestureRecognizer) {
    guard let swipeGesture = gesture as? UISwipeGestureRecognizer else { return }
    swipeAction(swipeGesture.direction)
  }
}
