//
//  DanmakuCellModel.swift
//
//
//  Created by littleTurnip on 9/3/23.
//

import Foundation

public protocol DanmakuCellModel {
  var cellClass: DanmakuCell.Type { get }

  var size: CGSize { get }

  /// Track for danmaku
  var track: UInt? { get set }

  var displayTime: Double { get }

  var type: DanmakuCellType { get }

  /// unique identifier
  var identifier: String { get }

  /// Used to determine if two cellmodels are equal
  /// - Parameter cellModel: other cellModel
  func isEqual(to cellModel: DanmakuCellModel) -> Bool
}
