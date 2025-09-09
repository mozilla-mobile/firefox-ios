// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "BrowserKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "Shared",
                 targets: ["Shared"]),
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
            name: "MenuKit",
            targets: ["MenuKit"]),
        .library(name: "SummarizeKit",
                 targets: ["SummarizeKit"]),
        .library(
            name: "UnifiedSearchKit",
            targets: ["UnifiedSearchKit"]),
        .library(
            name: "ContentBlockingGenerator",
            targets: ["ContentBlockingGenerator"]),
        .library(
            name: "OnboardingKit",
            targets: ["OnboardingKit"]),
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
            exact: "8.2.0"),
        .package(
            url: "https://github.com/AliSoftware/Dip.git",
            exact: "7.1.1"),
        .package(
            url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git",
            exact: "2.0.0"),
        .package(
            url: "https://github.com/getsentry/sentry-cocoa.git",
            exact: "8.36.0"),
        .package(
            url: "https://github.com/nbhasin2/GCDWebServer.git",
            branch: "master"),
        .package(
            url: "https://github.com/swhitty/SwiftDraw",
            exact: "0.18.3"),
        .package(
            url: "https://github.com/johnxnguyen/Down.git",
            exact: "0.11.0"),
    ],
    targets: [
        .target(
            name: "Shared",
            dependencies: ["Common"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "ComponentLibrary",
            dependencies: ["Common", "SiteImageView"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferSendableFromCaptures")
            ]),
        .testTarget(
            name: "ComponentLibraryTests",
            dependencies: ["ComponentLibrary"]),
        .target(
            name: "SiteImageView",
            dependencies: ["Fuzi", "Kingfisher", "Common", "SwiftDraw"],
            exclude: ["README.md"],
            resources: [.process("BundledTopSitesFavicons.xcassets")],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferSendableFromCaptures")
            ]),
        .testTarget(
            name: "SiteImageViewTests",
            dependencies: ["SiteImageView", .product(name: "GCDWebServers", package: "GCDWebServer")],
            resources: [
                .copy("Resources/mozilla.ico"),
                .copy("Resources/inf-nan.svg"),
                .copy("Resources/hackernews.svg")
            ]
        ),
        .target(
            name: "Common",
            dependencies: ["Dip",
                           "SwiftyBeaver",
                           .product(name: "Sentry-Dynamic", package: "sentry-cocoa")],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferSendableFromCaptures")
            ]
        ),
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"]),
        .target(
            name: "TabDataStore",
            dependencies: ["Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"]),
                            .enableExperimentalFeature("StrictConcurrency")]),
        .testTarget(
            name: "TabDataStoreTests",
            dependencies: ["TabDataStore"]),
        .target(
            name: "Redux",
            dependencies: ["Common"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
                .enableExperimentalFeature("StrictConcurrency")
            ]),
        .testTarget(
            name: "ReduxTests",
            dependencies: ["Redux"]),
        .target(
            name: "WebEngine",
            dependencies: ["Common",
                           .product(name: "GCDWebServers", package: "GCDWebServer")],
            swiftSettings: [.unsafeFlags(["-enable-testing"])]),
        .testTarget(
            name: "WebEngineTests",
            dependencies: ["WebEngine"]),
        .target(
            name: "ToolbarKit",
            dependencies: ["Common"],
            swiftSettings: [.unsafeFlags(["-enable-testing"]),
                            .enableExperimentalFeature("StrictConcurrency"),
                            .enableUpcomingFeature("InferSendableFromCaptures")]),
        .testTarget(
            name: "ToolbarKitTests",
            dependencies: ["ToolbarKit"]),
        .target(
            name: "MenuKit",
            dependencies: ["Common", "ComponentLibrary"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
                .enableExperimentalFeature("StrictConcurrency")
            ]),
        .testTarget(
            name: "MenuKitTests",
            dependencies: ["MenuKit"]),
        .target(
            name: "SummarizeKit",
            dependencies: [
                "Common",
                "ComponentLibrary",
                "Down"
            ],
            swiftSettings: [.unsafeFlags(["-enable-testing"])]
        ),
        .testTarget(name: "SummarizeKitTests",
                    dependencies: ["SummarizeKit"]),
        .target(
            name: "UnifiedSearchKit",
            dependencies: ["Common", "ComponentLibrary", "MenuKit"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
                .enableExperimentalFeature("StrictConcurrency")
            ]),
        .target(
            name: "ContentBlockingGenerator",
            swiftSettings: [.unsafeFlags(["-enable-testing"])]),
        .testTarget(
            name: "ContentBlockingGeneratorTests",
            dependencies: ["ContentBlockingGenerator"]),
        .target(
            name: "OnboardingKit",
            dependencies: ["Common", "ComponentLibrary"],
            resources: [
                .process("Shaders")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
                .enableExperimentalFeature("StrictConcurrency")
            ],
            linkerSettings: [
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit")
            ]),
        .testTarget(
            name: "OnboardingKitTests",
            dependencies: ["OnboardingKit"]),
        .executableTarget(
            name: "ExecutableContentBlockingGenerator",
            dependencies: ["ContentBlockingGenerator"]),
    ]
)
