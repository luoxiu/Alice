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
        .library(name: "HTTP", targets: ["HTTP", "Async"]),
        .library(name: "Async", targets: ["Async"]),
        .executable(name: "ping", targets: ["ping"])
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Utility"),
        .target(name: "Async", dependencies: ["Utility"]),
        .target(name: "HTTP", dependencies: ["Async", "Utility"]),
        .target(name: "ping", dependencies: ["HTTP"]),
        .testTarget(name: "AsyncTests", dependencies: ["Async"]),
        .testTarget(name: "HTTPTests", dependencies: ["HTTP"])
    ]
)
