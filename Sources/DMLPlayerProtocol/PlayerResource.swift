//
//  PlayerResource.swift
//
//
//  Created by littleTurnip on 3/1/24.
//
import SwiftUI

// MARK: - PlayerResource

public protocol PlayerResource: Sendable {
  var line: String { get }
  var rate: Int { get }
  var url: URL? { get }
  var rateList: [any StreamRate] { get }
  var cdnList: [any StreamCDN] { get }
  var cdnName: String { get }
  var resolution: String { get }
}

// MARK: - StreamRate

public protocol StreamRate: Identifiable, Sendable {
  var id: Int { get }
  var resolution: String { get }
}

// MARK: - StreamCDN

public protocol StreamCDN: Identifiable, Sendable {
  var id: String { get }
  var cdnName: String { get }
}

// MARK: - PlayableItem

public protocol PlayableItem {
  var id: String { get }
  var platform: String { get }
  var roomID: String { get }
  var helperID: String? { get }

  // MARK: - local properties

  var isFav: Bool { get set }
  var savedCDN: String? { get set }
  var playCount: Int { get set }
  var lastPlayTime: Date { get set }
  func update()

  // MARK: - stream resource

  var currentResource: PlayerResource? { get set }
  var resourceStream: AsyncStream<PlayerResource?> { get }
  func loadStream(line: String?, rate: Int?)
}
