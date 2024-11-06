//
//  Options.swift
//
//
//  Created by littleTurnip on 4/10/24.
//

import AVFoundation
import Foundation
import KSPlayer
#if os(tvOS)
  import DisplayCriteria
#endif
import UIKit

public typealias MediaPlayerProtocol = KSPlayer.MediaPlayerProtocol
public typealias MEPlayer = KSMEPlayer
public typealias AVPlayer = KSAVPlayer

// MARK: - PlayerOptions

public class PlayerOptions: KSOptions {
  public var isDisplayCriteriaEnabled: Bool = false

  override public func sei(string: String) {}
  override public func updateVideo(refreshRate: Float, isDovi: Bool, formatDescription: CMFormatDescription) {
    guard isDisplayCriteriaEnabled else { return }
    super.updateVideo(refreshRate: refreshRate, isDovi: isDovi, formatDescription: formatDescription)
  }
}

// MARK: - DanmakuOptions

public struct DanmakuOptions {
  public var danmaku: Self.Danmaku
  public var layer: Self.Layer
  public var blockKeywords: Set<String>

  public init(
    viewHeight: CGFloat,
    opacity: Double,
    trackHeight: CGFloat,
    fontSize: CGFloat,
    speed: Double,
    isAutoPlay: Bool,
    isColor: Bool,
    blockKeywords: Set<String>
  ) {
    danmaku = Self.Danmaku(
      speed: speed,
      isColor: isColor,
      fontSize: fontSize
    )
    layer = Self.Layer(
      viewHeight: viewHeight,
      opacity: opacity,
      trackHeight: trackHeight,
      isAutoPlay: isAutoPlay
    )
    self.blockKeywords = blockKeywords
  }

  public init(layer: Self.Layer, danmaku: Self.Danmaku, blockKeywords: Set<String>) {
    self.layer = layer
    self.danmaku = danmaku
    self.blockKeywords = blockKeywords
  }
}

public extension DanmakuOptions {
  struct Layer {
    public var viewHeight: CGFloat
    public var opacity: Double
    public var trackHeight: CGFloat
    public var isAutoPlay: Bool

    public init(
      viewHeight: CGFloat,
      opacity: Double,
      trackHeight: CGFloat,
      isAutoPlay: Bool
    ) {
      self.viewHeight = viewHeight
      self.opacity = opacity
      self.trackHeight = trackHeight
      self.isAutoPlay = isAutoPlay
    }
  }

  struct Danmaku {
    public var speed: Double
    public var isColor: Bool
    public var fontSize: CGFloat

    public init(
      speed: Double,
      isColor: Bool,
      fontSize: CGFloat
    ) {
      self.speed = speed
      self.isColor = isColor
      self.fontSize = fontSize
    }
  }
}

public extension DanmakuOptions {
  static var `default`: Self = .init(
    viewHeight: 550,
    opacity: 0.8,
    trackHeight: 1.4,
    fontSize: 34,
    speed: 10,
    isAutoPlay: true,
    isColor: true,
    blockKeywords: []
  )
}
