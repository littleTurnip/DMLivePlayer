//
//  DanmakuPreviewView.swift
//
//
//  Created by littleTurnip on 9/12/24.
//

import DMLPlayerProtocol
import SwiftUI

// MARK: - DanmakuPreviewView

public struct DanmakuPreviewView: View {
  @StateObject var coordinator: DanmakuContainer.Coordinator = .init()
  var options: DanmakuOptions

  public init(_ options: DanmakuOptions) {
    self.options = options
  }

  public var body: some View {
    DanmakuContainer(coordinator: coordinator, options: options)
      .onAppear { [weak coordinator] in
        coordinator?.setDanmakuService(ExampleDanmakuService())
        coordinator?.startDanmakuStream(options: options)
      }
      .ignoresSafeArea(.all)
  }
}

// MARK: - ExampleDanmakuService

actor ExampleDanmakuService: DanmakuService {
  var id: String = "ExampleDanmakuService"

  var task: Task<Void, Never>?
  var onDanmakuReceived: DanmakuHandler?

  func generateSampleStreamTask() async {
    while !Task.isCancelled {
      let randomDelay = UInt64.random(in: 1 ... 1000) * 1_000_000
      try? await Task.sleep(nanoseconds: randomDelay)

      let randomCount = Int.random(in: 1 ... min(10, sampleStrings.count))
      let selectedStrings = sampleStrings.shuffled().prefix(randomCount)
      for string in selectedStrings {
        let danmaku = DanmakuItem(text: string, color: .white)
        await onDanmakuReceived?(danmaku)
      }
    }
  }

  func start() {
    task = Task { await generateSampleStreamTask() }
  }

  func stop() {
    task?.cancel()
  }

  func setDanmakuHandler(_ handler: @escaping DanmakuHandler) {
    onDanmakuReceived = handler
  }

  func clearDanmakuHandler() {
    onDanmakuReceived = nil
  }
}

private let sampleStrings = [
  "Great stream!",
  "Lol",
  "Amazing play!",
  "This is epic",
  "What a game!",
  "GGWP!",
  "Can't believe that happened",
  "Wow just wow!",
  "Best streamer ever",
  "Haha that was funny",
  "Keep it up!",
  "How did you do that?",
  "That's insane!",
  "Love from Brazil",
  "Greetings from Germany",
  "Such skill much wow",
  "Whoa did you see that?",
  "Incredible skill!",
  "This music is lit",
  "First time viewer here",
  "How are you today?",
  "This is so relaxing",
  "Shoutout please?",
  "Missed the start what happened?",
  "Can't stop watching",
  "Streaming goals right here",
  "Your setup is amazing",
  "How long will you stream?",
  "That strategy though",
  "Literally the best content",
]
