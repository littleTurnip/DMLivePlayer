//
//  Resource.swift
//
//
//  Created by littleTurnip on 4/8/24.
//

import Foundation

// MARK: - Resource

public protocol Resource: Sendable {
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
