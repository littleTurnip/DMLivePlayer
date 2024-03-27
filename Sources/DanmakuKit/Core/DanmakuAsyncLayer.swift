//
//  DanmakuAsyncLayer.swift
//  DanmakuKit
//
//  Created by littleTurnip on 9/3/23.
//

import UIKit

// MARK: - Sentinel

class Sentinel {
  private var value: Int32 = 0
  private var lock = os_unfair_lock_s()

  public func getValue() -> Int32 {
    os_unfair_lock_lock(&lock)
    defer {
      os_unfair_lock_unlock(&lock)
    }
    return value
  }

  public func increase() {
    os_unfair_lock_lock(&lock)
    defer {
      os_unfair_lock_unlock(&lock)
    }
    value += 1
  }
}

// MARK: - DanmakuAsyncLayer

public class DanmakuAsyncLayer: CALayer {
  /// When true, it is drawn asynchronously and is ture by default.
  public var displayAsync = true

  public var willDisplay: ((_ layer: DanmakuAsyncLayer) -> Void)?

  public var displaying: ((_ context: CGContext, _ size: CGSize, _ isCancelled: () -> Bool) -> Void)?

  public var didDisplay: ((_ layer: DanmakuAsyncLayer, _ finished: Bool) -> Void)?

  /// The number of queues to draw the danmaku.
  public static var drawDanmakuQueueCount = 16 {
    didSet {
      guard drawDanmakuQueueCount != oldValue else { return }
      pool = nil
      createPoolIfNeed()
    }
  }

  private let sentinel = Sentinel()

  private static var pool: DanmakuQueuePool?

  override init() {
    super.init()
    contentsScale = UIScreen.main.scale
  }

  override init(layer: Any) {
    super.init(layer: layer)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  deinit {
    sentinel.increase()
  }

  override public func setNeedsDisplay() {
    // 1. Cancel the last drawing
    sentinel.increase()
    // 2. call super
    super.setNeedsDisplay()
  }

  override public func display() {
    display(isAsync: displayAsync)
  }

  private func display(isAsync: Bool) {
    guard displaying != nil else {
      willDisplay?(self)
      contents = nil
      didDisplay?(self, true)
      return
    }

    if isAsync {
      willDisplay?(self)
      let value = sentinel.getValue()
      let isCancelled = { () -> Bool in
        value != self.sentinel.getValue()
      }
      let size = bounds.size
      let scale = contentsScale
      let opaque = isOpaque
      let backgroundColor = (opaque && backgroundColor != nil) ? backgroundColor : nil
      queue.async {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
          if isCancelled() {
            return
          }
          if opaque {
            context.cgContext.saveGState()
            if backgroundColor == nil || (backgroundColor?.alpha ?? 0) < 1 {
              context.cgContext.setFillColor(UIColor.white.cgColor)
              context.cgContext.addRect(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
              context.cgContext.fillPath()
            }
            if let backgroundColor {
              context.cgContext.setFillColor(backgroundColor)
              context.cgContext.addRect(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
              context.cgContext.fillPath()
            }
            context.cgContext.restoreGState()
          }
          self.displaying?(context.cgContext, size, isCancelled)
        }

        if isCancelled() {
          DispatchQueue.main.async {
            self.didDisplay?(self, false)
          }
          return
        }
        DispatchQueue.main.async {
          if isCancelled() {
            self.didDisplay?(self, false)
          } else {
            self.contents = image.cgImage
            self.didDisplay?(self, true)
          }
        }
      }

    } else {
      sentinel.increase()
      willDisplay?(self)
      UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, contentsScale)
      guard let context = UIGraphicsGetCurrentContext() else {
        UIGraphicsEndImageContext()
        return
      }
      displaying?(context, bounds.size, { () -> Bool in false })
      let image = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      contents = image?.cgImage
      didDisplay?(self, true)
    }
  }

  private static func createPoolIfNeed() {
    guard DanmakuAsyncLayer.pool == nil else { return }
    DanmakuAsyncLayer.pool = DanmakuQueuePool(name: "com.DanmakuKit.DanmakuAsynclayer", queueCount: DanmakuAsyncLayer.drawDanmakuQueueCount, qos: .userInteractive)
  }

  private lazy var queue: DispatchQueue = DanmakuAsyncLayer.pool?.queue ?? DispatchQueue(label: "com.DanmakuKit.DanmakuAsynclayer")
}
