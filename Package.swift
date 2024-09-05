// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReerRouter",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "ReerRouter",
            targets: ["ReerRouter"]),
    ],
    targets: [
        .target(
            name: "ReerRouter",
            dependencies: ["Launcher"],
            path: "Sources/ReerRouter"
        ),
        .target(name: "Launcher")
    ]
)

