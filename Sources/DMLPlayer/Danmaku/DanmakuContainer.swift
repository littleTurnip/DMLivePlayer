//
//  DanmakuCoordinator.swift
//  DMLPlayer
//
//  Created by littleTurnip on 8/5/23.
//
import DanmakuKit
import DMLPlayerProtocol
import SwiftUI

// MARK: - DanmakuDelegate

protocol DanmakuDelegate: AnyObject, Sendable {
  @Sendable func shootDanmaku(_ danmaku: Danmaku, fontSize: CGFloat, speed: Double) async
}

// MARK: - DanmakuOptions

public struct DanmakuOptions {
  var danmakuViewHeight: CGFloat
  var danmakuOpacity: Double
  var danmakuTrackHeight: CGFloat
  var danmakuFontSize: CGFloat
  var danmakuSpeed: Double
  var isDanmakuAutoPlay: Bool

  public init(
    danmakuViewHeight: CGFloat = 550,
    danmakuOpacity: Double = 0.8,
    danmakuTrackHeight: CGFloat = 1.4,
    danmakuFontSize: CGFloat = 34,
    danmakuSpeed: Double = 10,
    isDanmakuAutoPlay: Bool = true
  ) {
    self.danmakuViewHeight = danmakuViewHeight
    self.danmakuOpacity = danmakuOpacity
    self.danmakuTrackHeight = danmakuTrackHeight
    self.danmakuFontSize = danmakuFontSize
    self.danmakuSpeed = danmakuSpeed
    self.isDanmakuAutoPlay = isDanmakuAutoPlay
  }
}

// MARK: - DanmakuCoordinator

public class DanmakuCoordinator: ObservableObject, DanmakuViewDelegate, @unchecked Sendable {
  var option: DanmakuOptions
  var danmakuService: DanmakuService?
  var uiView: DanmakuView?

  init(service: DanmakuService?, option: DanmakuOptions) {
    danmakuService = service
    self.option = option
  }

  deinit {
    stopDanmakuStream()
  }

  func startDanmakuStream(options: DanmakuOptions) {
    Task { @MainActor in
      await danmakuService?.setDanmakuHandler { [weak self] danmaku in
        self?.shootDanmaku(danmaku, fontSize: options.danmakuFontSize, speed: options.danmakuSpeed)
      }
    }
    Task {
      await danmakuService?.start()
    }
  }

  func stopDanmakuStream() {
    Task {
      await danmakuService?.stop()
      await danmakuService?.clearDanmakuHandler()
    }
  }
}

// MARK: DanmakuDelegate

extension DanmakuCoordinator: DanmakuDelegate {
  @Sendable func shootDanmaku(_ danmaku: Danmaku, fontSize: CGFloat, speed: Double) {
    Task { @MainActor in
      let model = TextDanmakuModel(danmaku, fontSize: fontSize, speed: speed)
      uiView?.shoot(danmaku: model)
    }
  }
}

// MARK: - DanmakuContainer

struct DanmakuContainer: UIViewRepresentable {
  @ObservedObject
  var coordinator: DanmakuCoordinator
  let options: DanmakuOptions

  func makeCoordinator() -> DanmakuCoordinator {
    let uiView = DanmakuView(frame: CGRect(x: 0, y: 0, width: 1920, height: options.danmakuViewHeight))
    uiView.alpha = CGFloat(options.danmakuOpacity)
    uiView.isUserInteractionEnabled = false
    uiView.enableCellReusable = true
    uiView.trackHeight = options.danmakuTrackHeight * options.danmakuFontSize
    uiView.delegate = coordinator
    coordinator.uiView = uiView
    return coordinator
  }

  func makeUIView(context: Context) -> DanmakuView {
    let uiView = context.coordinator.uiView

    uiView?.play()
    if context.coordinator.option.isDanmakuAutoPlay {
      context.coordinator.startDanmakuStream(options: options)
    }
    return uiView!
  }

  func updateUIView(_ uiView: DanmakuView, context: Context) {}

  func dismantleUIView(_ uiView: DanmakuView, coordinator: DanmakuCoordinator) {
    coordinator.stopDanmakuStream()
    uiView.stop()
  }
}
