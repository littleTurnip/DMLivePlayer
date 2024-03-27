//
//  Danmaku.swift
//  DMLPlayer
//
//  Created by littleTurnip on 2/27/24.
//

import DanmakuKit
import DMLPlayerProtocol
import UIKit

// MARK: - DanmakuItem

public typealias Danmaku = DMLPlayerProtocol.Danmaku

// MARK: - DanmakuItem

public struct DanmakuItem: Danmaku {
  public let id = UUID()
  public var text: String
  public var color: UIColor

  public init(text: String, color: UIColor) {
    self.text = text
    self.color = color
  }
}

// MARK: - TextDanmakuModel

public class TextDanmakuModel: DanmakuCellModel {
  public var cellClass: DanmakuCell.Type
  public var type: DanmakuCellType

  public var track: UInt?
  public var displayTime: Double
  public var size: CGSize

  public var identifier: String
  public func isEqual(to cellModel: DanmakuCellModel) -> Bool {
    identifier == cellModel.identifier
  }

  var text: String
  var font: UIFont
  var textColor: UIColor

  public init(_ danmaku: Danmaku, fontSize: CGFloat, speed: Double) {
    let fontSize = fontSize
    let danmakuSpeed = speed * 0.1
    cellClass = TextDanmakuCell.self
    type = .floating

    text = danmaku.text
    textColor = danmaku.color
    identifier = danmaku.id.uuidString

    font = .systemFont(ofSize: fontSize, weight: .medium)
    size = CGSize(width: Double(text.count + 1) * fontSize, height: fontSize * 1.2)
    displayTime = 10.0 / danmakuSpeed
  }
}

// MARK: - TextDanmakuCell

class TextDanmakuCell: DanmakuCell {
  required init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func displaying(_ context: CGContext, _: CGSize, _: Bool) {
    guard let model = model as? TextDanmakuModel else { return }

    // 绘制文本
    let text = NSString(string: model.text)
    context.setLineWidth(1)
    context.setLineJoin(.round)
    context.setStrokeColor(UIColor.black.cgColor)
    context.saveGState()

    context.setTextDrawingMode(.stroke)
    text.draw(at: .zero, withAttributes: [.font: model.font])
    context.restoreGState()

    context.setTextDrawingMode(.fill)
    text.draw(at: .zero, withAttributes: [.font: model.font, .foregroundColor: model.textColor])
  }

  override func leaveTrack() {}
}
