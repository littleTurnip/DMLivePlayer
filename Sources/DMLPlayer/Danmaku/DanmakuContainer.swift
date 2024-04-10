//
//  DanmakuContainer.swift
//  DMLPlayer
//
//  Created by littleTurnip on 8/5/23.
//
import DanmakuKit
import DMLPlayerProtocol
import SwiftUI

// MARK: - DanmakuContainer

struct DanmakuContainer: UIViewRepresentable {
  @StateObject
  var coordinator: Coordinator
  var service: DanmakuService?
  let options: DanmakuOptions

  func makeCoordinator() -> Coordinator {
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
    if options.isDanmakuAutoPlay {
      context.coordinator.danmakuService = service
      context.coordinator.startDanmakuStream(options: options)
    }
    return uiView!
  }

  func updateUIView(_ uiView: DanmakuView, context: Context) {}

  func dismantleUIView(_ uiView: DanmakuView, coordinator: Coordinator) {
    coordinator.stopDanmakuStream()
    coordinator.danmakuService = nil
    uiView.stop()
  }
}

// MARK: DanmakuContainer.Coordinator

extension DanmakuContainer {
  public class Coordinator: DanmakuDelegate, ObservableObject, @unchecked Sendable {
    var danmakuService: DanmakuService?
    var uiView: DanmakuView?

    init(service: DanmakuService? = nil) {
      danmakuService = service
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

    @Sendable func shootDanmaku(_ danmaku: Danmaku, fontSize: CGFloat, speed: Double) {
      Task { @MainActor in
        let model = TextDanmakuModel(danmaku, fontSize: fontSize, speed: speed)
        uiView?.shoot(danmaku: model)
      }
    }
  }
}
