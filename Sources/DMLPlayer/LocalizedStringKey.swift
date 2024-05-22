//
//  LocalizedStringKey.swift
//
//
//  Created by littleTurnip on 5/21/24.
//

import SwiftUI

// MARK: - LocalizedValueProtocol

protocol LocalizedValueProtocol: RawRepresentable where RawValue == String.LocalizationValue {}

extension LocalizedValueProtocol {
  static subscript(_ key: Self) -> String {
    String(localized: key.rawValue, table: "Localizable", bundle: .module)
  }
}

// MARK: - Localized

enum Localized {
  enum Alert: String.LocalizationValue, LocalizedValueProtocol {
    case favMessage = "alert.favMessage"
  }

  enum Button: String.LocalizationValue, LocalizedValueProtocol {
    case confirmUnfav = "button.confirmUnfav"
    case confirm = "button.confirm"
    case cancel = "button.cancel"
  }
}
