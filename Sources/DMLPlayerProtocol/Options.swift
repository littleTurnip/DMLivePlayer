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
  override public func updateVideo(refreshRate: Float, isDovi: Bool, formatDescription: CMFormatDescription?) {
    Task { @MainActor in
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let displayManager = windowScene.windows.first?.avDisplayManager,
            isDisplayCriteriaEnabled,
            displayManager.isDisplayCriteriaMatchingEnabled
      else {
        return
      }
      if let formatDescription {
        if #available(tvOS 17.0, *),
           KSOptions.displayCriteriaFormatDescriptionEnabled {
          displayManager.preferredDisplayCriteria = AVDisplayCriteria(refreshRate: refreshRate, formatDescription: formatDescription)
        } else {
          let dynamicRange = isDovi ? .dolbyVision : formatDescription.dynamicRange
          displayManager.preferredDisplayCriteria = AVDisplayCriteria(refreshRate: refreshRate, videoDynamicRange: dynamicRange.rawValue)
        }
      }
    }
  }
}

// MARK: - DanmakuOptions

public struct DanmakuOptions {
  public var danmakuViewHeight: CGFloat
  public var danmakuOpacity: Double
  public var danmakuTrackHeight: CGFloat
  public var danmakuFontSize: CGFloat
  public var danmakuSpeed: Double
  public var isDanmakuAutoPlay: Bool

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
