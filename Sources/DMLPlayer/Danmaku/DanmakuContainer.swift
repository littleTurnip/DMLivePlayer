//
//  DanmakuContainer.swift
//  DMLPlayer
//
//  Created by littleTurnip on 8/5/23.
//
import DanmakuKit
import DMLPlayerProtocol
import OSLog
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
    private let logger = Logger(subsystem: "DMLPlayer", category: "Danmaku.Coordinator")
    var danmakuService: DanmakuService?
    var blockKeywords: Set<String> = []
    var uiView: DanmakuView?

    init(service: DanmakuService? = nil) {
      danmakuService = service
    }

    deinit {
      cleanDanmakuService()
    }

    func setDanmakuService(_ service: DanmakuService?) {
      logger.debug("set danmaku service: \(service.debugDescription)")
      danmakuService = service
    }

    func cleanDanmakuService() {
      logger.debug("clean danmaku service: \(self.danmakuService.debugDescription)")
      stopDanmakuStream()
    }

    func startDanmakuStream(options: DanmakuOptions) {
      logger.debug("start danmaku stream")
      Task { @MainActor in
        await danmakuService?.setDanmakuHandler { [weak self] danmaku in
          await self?.shootDanmaku(danmaku, fontSize: options.danmakuFontSize, speed: options.danmakuSpeed)
        }
        await danmakuService?.start()
      }
    }

    func stopDanmakuStream() {
      logger.debug("stop danmaku stream")
      uiView?.clean()
      Task {
        await danmakuService?.stop()
        await danmakuService?.clearDanmakuHandler()
      }
    }

    @MainActor
    func shootDanmaku(_ danmaku: Danmaku, fontSize: CGFloat, speed: Double) {
      // 判断是否包含屏蔽词
      if isDanmakuInSet(danmaku, in: blockKeywords) {
        return
      } else {
        let model = TextDanmakuModel(danmaku, fontSize: fontSize, speed: speed)
        uiView?.shoot(danmaku: model)
      }
    }

    private func isDanmakuInSet(_ danmaku: Danmaku, in keywordSet: Set<String>) -> Bool {
      guard !keywordSet.isEmpty else { return false }
      let pattern = keywordSet.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
      guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return false
      }
      let matches = regex.firstMatch(in: danmaku.text, options: [], range: NSRange(location: 0, length: danmaku.text.utf16.count))
      return matches != nil
    }
  }
}
