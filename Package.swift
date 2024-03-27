// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DMLPlayer",
  platforms: [
    .tvOS(.v16),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "DMLPlayer", targets: ["DMLPlayer"]),
    .library(name: "DMLPlayerProtocol", targets: ["DMLPlayerProtocol"]),
  ],
  dependencies: [
    .package(url: "https://github.com/littleTurnip/KSPlayer.git", exact: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "DMLPlayer",
      dependencies: [
        "DMLPlayerProtocol",
        .ksplayer,
      ]
    ),
    .target(
      name: "DMLPlayerProtocol"
    ),
    .testTarget(
      name: "DMLPlayerTests",
      dependencies: ["DMLPlayer"]
    ),
  ]
)

extension Target.Dependency {
  static let ksplayer = Target.Dependency.product(name: "KSPlayer", package: "KSPlayer")
}
