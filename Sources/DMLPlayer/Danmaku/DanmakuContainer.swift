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
  @StateObject var coordinator: Coordinator
  var service: DanmakuService?
  let options: DanmakuOptions

  func makeCoordinator() -> Coordinator {
    let uiView = DanmakuView(frame: CGRect(x: 0, y: 0, width: 1920, height: options.layer.viewHeight))
    uiView.alpha = CGFloat(options.layer.opacity)
    uiView.isUserInteractionEnabled = false
    uiView.enableCellReusable = true
    uiView.trackHeight = options.layer.trackHeight * options.danmaku.fontSize
    uiView.delegate = coordinator
    coordinator.uiView = uiView
    coordinator.blockKeywords = options.blockKeywords
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
  public class Coordinator: DanmakuDelegate {
    private let logger = Logger(subsystem: "DMLPlayer", category: "Danmaku.Coordinator")
    var danmakuService: DanmakuService?
    var blockKeywords: Set<String> = []
    var uiView: DanmakuView?

    init(service: DanmakuService? = nil) {
      danmakuService = service
    }

    deinit {
      cleanDanmakuService()
      uiView = nil
    }

    func setDanmakuService(_ service: DanmakuService?) {
      logger.debug("set danmaku service: \(service.debugDescription)")
      danmakuService = service
    }

    func cleanDanmakuService() {
      logger.debug("clean danmaku service: \(self.danmakuService.debugDescription)")
      if uiView != nil {
        stopDanmakuStream()
      }
    }

    func startDanmakuStream(options: DanmakuOptions) {
      logger.debug("start danmaku stream")
      Task { @MainActor in
        await danmakuService?.setDanmakuHandler { [weak self] danmaku in
          await self?.shootDanmaku(danmaku, options: options.danmaku)
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
    func shootDanmaku(_ danmaku: Danmaku, options: DanmakuOptions.Danmaku) async {
      // 判断是否包含屏蔽词
      if isDanmakuInSet(danmaku, in: blockKeywords) {
        logger.debug("block danmaku: \(danmaku.text)")
        return
      } else {
        let model = TextDanmakuModel(danmaku, options: options)
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

// MARK: - DanmakuContainer.Coordinator + ObservableObject

extension DanmakuContainer.Coordinator: ObservableObject {}

// MARK: - DanmakuContainer.Coordinator + Sendable

extension DanmakuContainer.Coordinator: @unchecked Sendable {}
