// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Focus",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "UIHelpers",
            targets: ["UIHelpers"]),
        .library(
            name: "DesignSystem",
            targets: ["DesignSystem"]),
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]),
        .library(
            name: "AppShortcuts",
            targets: ["AppShortcuts"])
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.1")
    ],
    targets: [
        .target(
            name: "UIHelpers",
            dependencies: [
                .product(name: "SnapKit", package: "SnapKit")
            ]
        ),
        .target(
            name: "DesignSystem",
            exclude: ["Preview Files"]
        ),
        .target(
            name: "Onboarding",
            dependencies: [
                "DesignSystem",
                .product(name: "SnapKit", package: "SnapKit")
            ],
            exclude: ["Preview Files"]
        ),
        .target(
            name: "AppShortcuts",
            dependencies: [
                "DesignSystem",
                .product(name: "SnapKit", package: "SnapKit")
            ]
        ),
        .testTarget(
            name: "BlockzillaPackageTests",
            dependencies: ["AppShortcuts"])
    ]
)
