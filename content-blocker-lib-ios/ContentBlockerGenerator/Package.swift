// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ContentBlockerGenerator",
    targets: [
        .executableTarget(
            name: "ContentBlockerGenerator",
            dependencies: []),
        .testTarget(
            name: "ContentBlockerGeneratorTests",
            dependencies: ["ContentBlockerGenerator"]),
    ]
)
