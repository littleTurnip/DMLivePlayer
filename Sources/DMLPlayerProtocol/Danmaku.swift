//
//  Danmaku.swift
//
//
//  Created by littleTurnip on 3/1/24.
//

import DanmakuKit
import UIKit

// MARK: - Danmaku

public protocol Danmaku: Sendable {
  var id: UUID { get }
  var text: String { get }
  var color: UIColor { get }

  init(text: String, color: UIColor)
}

public typealias DanmakuHandler = @Sendable (Danmaku) async -> Void

// MARK: - DanmakuService

public protocol DanmakuService: Actor {
  var id: String { get }
  var onDanmakuReceived: DanmakuHandler? { get set }
  func setDanmakuHandler(_ handler: @escaping DanmakuHandler)
  func clearDanmakuHandler()
  func start()
  func stop()
}

// MARK: - DanmakuDelegate

public protocol DanmakuDelegate: DanmakuViewDelegate, Sendable {
  func setDanmakuService(_ service: DanmakuService?)
  func cleanDanmakuService()
  func startDanmakuStream(options: DanmakuOptions)
  func stopDanmakuStream()
  @Sendable func shootDanmaku(_ danmaku: Danmaku, options: DanmakuOptions.Danmaku) async
}
