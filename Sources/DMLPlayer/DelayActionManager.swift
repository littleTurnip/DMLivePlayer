//
//  DelayActionManager.swift
//  DMLPlayer
//
//  Created by littleTurnip on 11/12/24.
//

import Foundation

actor DelayActionManager {
  private let interval: TimeInterval
  private let action: @Sendable () async -> Void
  private var task: Task<Void, Never>?
  private var continuation: AsyncStream<Void>.Continuation?

  init(interval: TimeInterval, action: @escaping @Sendable () async -> Void) {
    self.interval = interval
    self.action = action
    Task {
      await startTask()
    }
  }

  func resetDelay() {
    continuation?.yield()
  }

  func cancel() {
    continuation?.finish()
    task?.cancel()
    task = nil
  }

  private func startTask() {
    task = Task { [weak self] in
      await self?.run()
    }
  }

  private func run() async {
    let stream = AsyncStream<Void> { continuation in
      self.continuation = continuation
      continuation.yield()
    }

    var delayTask: Task<Void, Never>?

    for await _ in stream {
      delayTask?.cancel()
      delayTask = Task {
        do {
          try await Task.sleep(nanoseconds: UInt64(self.interval * 1_000_000_000))
          await self.action()
          self.continuation?.finish()
        } catch {}
      }
    }

    delayTask?.cancel()
    task = nil
    continuation = nil
  }
}
