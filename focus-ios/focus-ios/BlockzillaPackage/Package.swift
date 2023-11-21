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
            targets: ["UIComponents"]),
        .library(
            name: "Widget",
            targets: ["Widget"]),
        .library(
            name: "Licenses",
            targets: ["Licenses"])
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.1")
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
                "Widget",
                "DesignSystem",
                .product(name: "SnapKit", package: "SnapKit")
            ]
        ),
        .target(
            name: "AppShortcuts",
            dependencies: [
                "UIComponents",
                "DesignSystem"
            ]
        ),
        .target(
            name: "Widget"
        ),
        .target(
            name: "Licenses",
            resources: [
                .copy("license-list.plist"),
                .copy("focus-ios.plist")
            ]
        ),
        .testTarget(
            name: "BlockzillaPackageTests",
            dependencies: ["AppShortcuts"])
    ]
)
