//
//  PlayerProtocol.swift
//
//
//  Created by littleTurnip on 4/10/24.
//

import Foundation
import KSPlayer

public typealias DanmakuCoordinator = DanmakuDelegate
public typealias PlayerCoordinator = KSVideoPlayer.Coordinator

// MARK: - PlayerProtocol

@MainActor
public protocol PlayerProtocol: ObservableObject, Sendable {
  var item: (any PlayableItem)? { get set }
  var playerCoordinator: PlayerCoordinator { get }
  var danmakuCoordinator: DanmakuCoordinator { get }
  var playerOptions: PlayerOptions { get set }
  var danmakuOptions: DanmakuOptions { get set }
  var isVisible: Bool { get set }

  func updateItem(_ newItem: any PlayableItem)
  func updateOptions(_ player: PlayerOptions, _ danmaku: DanmakuOptions)
}
