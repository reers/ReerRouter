// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReerRouter",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "ReerRouter",
            targets: ["ReerRouter"]),
    ],
    targets: [
        .target(
            name: "ReerRouter",
            path: "Sources")
    ]
)

