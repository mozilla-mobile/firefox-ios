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
            targets: ["AppShortcuts"]),
        .library(
            name: "UIComponents",
            targets: ["UIComponents"])
    ],
    targets: [
        .target(
            name: "UIComponents",
            dependencies: [
                "UIHelpers"
            ]
        ),
        .target(
            name: "UIHelpers"
        ),
        .target(
            name: "DesignSystem"
        ),
        .target(
            name: "Onboarding",
            dependencies: [
                "DesignSystem"
            ]
        ),
        .target(
            name: "AppShortcuts",
            dependencies: [
                "UIComponents",
                "DesignSystem"
            ]
        ),
        .testTarget(
            name: "BlockzillaPackageTests",
            dependencies: ["AppShortcuts"])
    ]
)
