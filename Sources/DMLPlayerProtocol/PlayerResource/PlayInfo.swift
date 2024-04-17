//
//  PlayInfo.swift
//
//
//  Created by littleTurnip on 4/17/24.
//

import Foundation

public struct PlayInfo: Sendable {
  public var isFav: Bool = false
  public var cdnLine: String?
  public var playCount: Int = 0
  public var lastPlay: Date = .init()
  public init(isFav: Bool = false, playCount: Int = 0, cdnLine: String? = nil, lastPlay: Date = Date()) {
    self.isFav = isFav
    self.playCount = playCount
    self.cdnLine = cdnLine
    self.lastPlay = lastPlay
  }
}
