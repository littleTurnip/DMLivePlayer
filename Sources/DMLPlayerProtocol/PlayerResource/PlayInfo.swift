//
//  PlayInfo.swift
//
//
//  Created by littleTurnip on 4/17/24.
//

import Foundation

public struct PlayInfo: Sendable {
  public var isFav = false
  public var cdnLine: String?
  public var playCount = 0
  public var lastPlay = Date()
  public var isSync = false
  public init(
    isFav: Bool = false,
    playCount: Int = 0,
    cdnLine: String? = nil,
    lastPlay: Date = Date(),
    isSync: Bool = false
  ) {
    self.isFav = isFav
    self.playCount = playCount
    self.cdnLine = cdnLine
    self.lastPlay = lastPlay
    self.isSync = isSync
  }
}
