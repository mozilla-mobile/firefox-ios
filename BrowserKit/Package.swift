// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "BrowserKit",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SiteImageView",
            targets: ["SiteImageView"]),
        .library(
            name: "Common",
            targets: ["Common"]),
        .library(
            name: "TabDataStore",
            targets: ["TabDataStore"]),
        .library(
            name: "Redux",
            targets: ["Redux"]),
        .library(
            name: "ComponentLibrary",
            targets: ["ComponentLibrary"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/nbhasin2/Fuzi.git",
            branch: "master"),
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            exact: "7.6.2"),
        .package(
            url: "https://github.com/AliSoftware/Dip.git",
            exact: "7.1.1"),
        .package(
            url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git",
            exact: "2.0.0"),
        .package(
            url: "https://github.com/getsentry/sentry-cocoa.git",
            exact: "8.9.3"),
    ],
    targets: [
        .target(
            name: "ComponentLibrary",
            dependencies: ["Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"])]),
        .testTarget(
            name: "ComponentLibraryTests",
            dependencies: ["ComponentLibrary"]),
        .target(
            name: "SiteImageView",
            dependencies: ["Fuzi", "Kingfisher", "Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"])]),
        .testTarget(
            name: "SiteImageViewTests",
            dependencies: ["SiteImageView"]),
        .target(
            name: "Common",
            dependencies: ["Dip",
                           "SwiftyBeaver",
                           .product(name: "Sentry", package: "sentry-cocoa")],
            swiftSettings: [.unsafeFlags(["-enable-testing"])]),
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"]),
        .target(
            name: "TabDataStore",
            dependencies: ["Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"])]),
        .testTarget(
            name: "TabDataStoreTests",
            dependencies: ["TabDataStore"]),
        .target(
            name: "Redux",
            swiftSettings: [.unsafeFlags(["-enable-testing"])]),
        .testTarget(
            name: "ReduxTests",
            dependencies: ["Redux"])
    ]
)
