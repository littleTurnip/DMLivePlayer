//
//  DanmakuGifCellModel.swift
//  DanmakuKit
//
//  Created by littleTurnip on 9/3/23.
//

import Foundation

// MARK: - DanmakuGifCellModel

public protocol DanmakuGifCellModel: DanmakuCellModel {
  /// GIF data source
  var resource: Data? { get }

  /// The animation duration of each frame, default is 0.1.
  var minFrameDuration: Float { get }

  /// Number of preloaded frames, default is 10.
  var preloadFrameCount: Int { get }

  /// Maximum number of repetitions of animation.
  var maxRepeatCount: Int { get }

  /// Decode image in background, default is true.
  var backgroundDecode: Bool { get }
}

public extension DanmakuGifCellModel {
  var minFrameDuration: Float {
    0.1
  }

  var preloadFrameCount: Int {
    10
  }

  var maxRepeatCount: Int {
    .max
  }

  var backgroundDecode: Bool {
    true
  }
}
