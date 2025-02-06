// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DMLPlayer",
  defaultLocalization: "en",
  platforms: [
    .tvOS(.v16),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "DMLPlayer", targets: ["DMLPlayer"]),
    .library(name: "DanmakuKit", targets: ["DanmakuKit"]),
    .library(name: "DMLPlayerProtocol", targets: ["DMLPlayerProtocol"]),
  ],
  dependencies: [
    .package(url: "https://github.com/littleTurnip/KSPlayer.git", .upToNextMajor(from: "2.4.8")),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "DMLPlayer",
      dependencies: [
        "DMLPlayerProtocol",
        .ksplayer,
      ]),
    .target(
      name: "DanmakuKit"),
    .target(
      name: "DMLPlayerProtocol",
      dependencies: [
        "DanmakuKit",
        .ksplayer,
      ]),
  ])

extension Target.Dependency {
  static let ksplayer = Target.Dependency.product(name: "KSPlayer", package: "KSPlayer")
}
