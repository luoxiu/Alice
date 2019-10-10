// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Alice",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "Alice", targets: ["Alice"]),
        .library(name: "Async", targets: ["Async"]),
        .executable(name: "ping", targets: ["ping"])
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Alice", dependencies: []),
        .target(name: "Async", dependencies: []),
        .target(name: "ping", dependencies: ["Alice", "Async"]),
        .testTarget(name: "AliceTests", dependencies: ["Alice"]),
    ]
)
