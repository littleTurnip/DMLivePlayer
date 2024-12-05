//
//  RoomInfo.swift
//
//
//  Created by littleTurnip on 4/17/24.
//

import Foundation

// MARK: - RoomInfo

public protocol RoomInfo: Sendable {
  var roomStatus: RoomStatus { get }
}

// MARK: - RoomStatus

public enum RoomStatus: Int {
  case live = 2
  case replay = 1
  case offline = 0
}

// MARK: Sendable

extension RoomStatus: Sendable {}

// MARK: Decodable

extension RoomStatus: Decodable {}

// MARK: Hashable

extension RoomStatus: Hashable {}

// MARK: Comparable

extension RoomStatus: Comparable {
  public static func < (lhs: RoomStatus, rhs: RoomStatus) -> Bool {
    // 自定义排序逻辑
    switch (lhs, rhs) {
    case (.offline, .live), (.offline, .replay), (.replay, .live):
      true
    default:
      false
    }
  }
}
