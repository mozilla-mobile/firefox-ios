// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "BrowserKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
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
            targets: ["ComponentLibrary"]),
        .library(
            name: "WebEngine",
            targets: ["WebEngine"]),
        .library(
            name: "ToolbarKit",
            targets: ["ToolbarKit"]),
        .library(
            name: "ContentBlockingGenerator",
            targets: ["ContentBlockingGenerator"]),
        .executable(
            name: "ExecutableContentBlockingGenerator",
            targets: ["ExecutableContentBlockingGenerator"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/nbhasin2/Fuzi.git",
            branch: "master"),
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            exact: "7.11.0"),
        .package(
            url: "https://github.com/AliSoftware/Dip.git",
            exact: "7.1.1"),
        .package(
            url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git",
            exact: "2.0.0"),
        .package(
            url: "https://github.com/getsentry/sentry-cocoa.git",
            exact: "8.21.0"),
        .package(url: "https://github.com/nbhasin2/GCDWebServer.git",
                 branch: "master"),
        .package(url: "https://github.com/realm/SwiftLint.git",
                 exact: "0.55.1")
    ],
    targets: [
        .target(
            name: "ComponentLibrary",
            dependencies: ["Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"])],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .testTarget(
            name: "ComponentLibraryTests",
            dependencies: ["ComponentLibrary"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .target(
            name: "SiteImageView",
            dependencies: ["Fuzi", "Kingfisher", "Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"])],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .testTarget(
            name: "SiteImageViewTests",
            dependencies: ["SiteImageView"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .target(
            name: "Common",
            dependencies: ["Dip",
                           "SwiftyBeaver",
                           .product(name: "Sentry", package: "sentry-cocoa")],
            swiftSettings: [.unsafeFlags(["-enable-testing"])],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .target(
            name: "TabDataStore",
            dependencies: ["Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"])],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .testTarget(
            name: "TabDataStoreTests",
            dependencies: ["TabDataStore"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .target(
            name: "Redux",
            dependencies: ["Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"])],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .testTarget(
            name: "ReduxTests",
            dependencies: ["Redux"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .target(
            name: "WebEngine",
            dependencies: ["Common",
                           .product(name: "GCDWebServers", package: "GCDWebServer")],
            swiftSettings: [.unsafeFlags(["-enable-testing"])],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .testTarget(
            name: "WebEngineTests",
            dependencies: ["WebEngine"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .target(
            name: "ToolbarKit",
            dependencies: ["Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"])],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .testTarget(
            name: "ToolbarKitTests",
            dependencies: ["ToolbarKit"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .target(
            name: "ContentBlockingGenerator",
            swiftSettings: [.unsafeFlags(["-enable-testing"])],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .testTarget(
            name: "ContentBlockingGeneratorTests",
            dependencies: ["ContentBlockingGenerator"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .executableTarget(
            name: "ExecutableContentBlockingGenerator",
            dependencies: ["ContentBlockingGenerator"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
    ]
)
