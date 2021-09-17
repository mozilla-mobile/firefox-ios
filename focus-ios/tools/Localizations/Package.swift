// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Localizations",
    platforms: [
        .macOS(.v10_13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.4.0"),
    ],
    targets: [
        .target(
            name: "Localizations",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(
            name: "LocalizationsTests",
            dependencies: ["Localizations"]),
    ]
)
