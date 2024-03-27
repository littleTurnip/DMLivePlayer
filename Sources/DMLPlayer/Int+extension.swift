//
//  Int+extension.swift
//  DMLPlayer
//
//  Created by littleTurnip on 2/29/24.
//

import Foundation

extension Int {
  func bytesToMegabytes() -> String {
    let megabytes = Double(self) / (1024 * 1024)
    return String(format: "%.2f", megabytes)
  }

  func bytesToKilobytes() -> String {
    let kilobytes = Double(self) / 1024
    return String(format: "%.2f", kilobytes)
  }
}
