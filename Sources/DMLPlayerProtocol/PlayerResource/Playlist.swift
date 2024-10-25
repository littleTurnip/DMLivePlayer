//
//  Playlist.swift
//  Turnip Player
//
//  Created by littleTurnip on 5/9/24.
//

import Foundation

// MARK: - PlaylistEntry

public protocol PlaylistEntry: Identifiable, Equatable {
  var id: String { get }

  static func == (lhs: Self, rhs: Self) -> Bool
}

// MARK: - Playlist

public protocol Playlist: Identifiable, Equatable, Hashable {
  associatedtype Entry: PlaylistEntry

  var id: UUID { get }
  var name: String { get }
  var entries: [Entry] { get }

  static func == (lhs: Self, rhs: Self) -> Bool
}
