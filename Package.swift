// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Alice",
    products: [
        .library(name: "Alice", targets: ["Alice"]),
        .executable(name: "ping", targets: ["ping"])
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Alice", dependencies: []),
        .target(name: "ping", dependencies: ["Alice"]),
        .testTarget(name: "AliceTests", dependencies: ["Alice"]),
    ]
)
