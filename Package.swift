// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SolanaWrapper",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "SolanaWrapper",
            targets: ["SolanaWrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LedgerHQ/hw-transport-ios-ble", branch: "main"),
    ],
    targets: [
        .target(
            name: "SolanaWrapper",
            dependencies: [.product(name: "BleTransport", package: "hw-transport-ios-ble")],
            resources: [.copy("JavaScript/bundle.js")]),
        .testTarget(
            name: "SolanaWrapperTests",
            dependencies: ["SolanaWrapper"]),
    ]
)
