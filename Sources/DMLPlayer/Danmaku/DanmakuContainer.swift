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
    coordinator.uiView = createDanmakuView()
    coordinator.blockKeywords = options.blockKeywords
    return coordinator
  }

  func createDanmakuView() -> DanmakuView {
    let uiView = DanmakuView(frame: CGRect(x: 0, y: 0, width: 1920, height: options.layer.viewHeight))
    uiView.alpha = CGFloat(options.layer.opacity)
    uiView.isUserInteractionEnabled = false
    uiView.enableCellReusable = true
    uiView.trackHeight = options.layer.trackHeight * options.danmaku.fontSize
    return uiView
  }

  func makeUIView(context: Context) -> DanmakuView {
    let uiView = context.coordinator.uiView

    uiView?.play()
    return uiView!
  }

  func updateUIView(_ uiView: DanmakuView, context: Context) {}

  func dismantleUIView(_ uiView: DanmakuView, coordinator: Coordinator) {
    coordinator.stopDanmakuStream()
    uiView.stop()
  }
}

// MARK: DanmakuContainer.Coordinator

extension DanmakuContainer {
  public class Coordinator: DanmakuDelegate {
    private let logger = Logger(subsystem: "DMLPlayer", category: "Danmaku.Coordinator")
    private(set) var danmakuService: DanmakuService?
    var blockKeywords: Set<String> = []
    var uiView: DanmakuView?

    init(service: DanmakuService? = nil) {
      danmakuService = service
    }

    deinit {
      logger.debug("DanmakuContainer.Coordinator deinit")
      stopDanmakuStream()
      danmakuService = nil
      uiView = nil
    }

    func setDanmakuService(_ service: DanmakuService?) {
      logger.debug("set danmaku service: \(service.debugDescription)")
      danmakuService = service
    }

    func startDanmakuStream(options: DanmakuOptions) {
      logger.debug("start danmaku stream")
      Task { @MainActor [weak self] in
        await self?.danmakuService?.setDanmakuHandler { [weak self] danmaku in
          await self?.shootDanmaku(danmaku, options: options.danmaku)
        }
        await self?.danmakuService?.start()
      }
    }

    func stopDanmakuStream() {
      logger.debug("stop danmaku stream")
      uiView?.clean()
      Task { [weak self] in
        await self?.danmakuService?.stop()
        await self?.danmakuService?.clearDanmakuHandler()
      }
    }

    @MainActor
    func shootDanmaku(_ danmaku: Danmaku, options: DanmakuOptions.Danmaku) async {
      // 判断是否包含屏蔽词
      guard !isDanmakuInSet(danmaku, in: blockKeywords) else {
        logger.debug("Blocked Danmaku: \(danmaku.text)")
        return
      }
      let model = TextDanmakuModel(danmaku, options: options)
      uiView?.shoot(danmaku: model)
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
