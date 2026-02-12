// swift-tools-version: 6.2

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
        .library(name: "TestKit",
                 targets: ["TestKit"]),
        .library(
            name: "ToolbarKit",
            targets: ["ToolbarKit"]),
        .library(
            name: "MenuKit",
            targets: ["MenuKit"]),
        .library(name: "SummarizeKit",
                 targets: ["SummarizeKit"]),
        .library(name: "JWTKit",
                 targets: ["JWTKit"]),
        .library(
            name: "UnifiedSearchKit",
            targets: ["UnifiedSearchKit"]),
        .library(
            name: "ContentBlockingGenerator",
            targets: ["ContentBlockingGenerator"]),
        .library(
            name: "OnboardingKit",
            targets: ["OnboardingKit"]),
        .library(
            name: "ActionExtensionKit",
            targets: ["ActionExtensionKit"]),
        .library(
            name: "VoiceSearchKit",
            targets: ["VoiceSearchKit"]),
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
            ]
        ),
        .target(
            name: "ComponentLibrary",
            dependencies: ["Common", "SiteImageView"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "ComponentLibraryTests",
            dependencies: ["ComponentLibrary"],
            swiftSettings: [
            ]
        ),
        .target(
            name: "SiteImageView",
            dependencies: ["Fuzi", "Kingfisher", "Common", "SwiftDraw"],
            exclude: ["README.md"],
            resources: [.process("BundledTopSitesFavicons.xcassets")],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "SiteImageViewTests",
            dependencies: [
                "SiteImageView",
                "TestKit",
                .product(name: "GCDWebServers", package: "GCDWebServer")
            ],
            resources: [
                .copy("Resources/mozilla.ico"),
                .copy("Resources/inf-nan.svg"),
                .copy("Resources/hackernews.svg")
            ],
            swiftSettings: [
            ],
        ),
        .target(
            name: "Common",
            dependencies: ["Dip",
                           "SwiftyBeaver",
                           .product(name: "Sentry-Dynamic", package: "sentry-cocoa")],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]
        ),
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"],
            swiftSettings: [
            ]),
        .target(
            name: "TabDataStore",
            dependencies: ["Common"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "TabDataStoreTests",
            dependencies: ["TabDataStore", "TestKit"],
            swiftSettings: [
            ]
        ),
        .target(
            name: "Redux",
            dependencies: ["Common"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "ReduxTests",
            dependencies: ["Redux"],
            swiftSettings: [
            ]
        ),
        .target(
            name: "WebEngine",
            dependencies: ["Common",
                           .product(name: "GCDWebServers", package: "GCDWebServer")],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "WebEngineTests",
            dependencies: ["WebEngine", "TestKit"],
            swiftSettings: [
            ]
        ),
        .target(name: "TestKit"),
        .target(
            name: "ToolbarKit",
            dependencies: ["Common"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "ToolbarKitTests",
            dependencies: ["ToolbarKit", "TestKit"],
            swiftSettings: [
        ]),
        .target(
            name: "MenuKit",
            dependencies: ["Common", "ComponentLibrary"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "MenuKitTests",
            dependencies: ["MenuKit"],
            swiftSettings: [
            ]
        ),
        .target(
            name: "SummarizeKit",
            dependencies: [
                "Common",
                "ComponentLibrary",
                "Down"
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]
        ),
        .testTarget(name: "SummarizeKitTests",
                    dependencies: ["SummarizeKit", "TestKit"],
                    swiftSettings: [
                        .unsafeFlags(["-enable-testing"]),
                    ]),
        .target(
            name: "JWTKit",
            dependencies: ["Common", "Shared"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]
        ),
        .testTarget(
            name: "JWTKitTests",
            dependencies: ["JWTKit"],
            swiftSettings: [
            ]
        ),
        .target(
            name: "UnifiedSearchKit",
            dependencies: ["Common", "ComponentLibrary"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .target(
            name: "VoiceSearchKit",
            dependencies: ["Common"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"])
            ]
        ),
        .testTarget(
            name: "VoiceSearchKitTests",
            dependencies: ["VoiceSearchKit"]
        ),
        .target(
            name: "ContentBlockingGenerator",
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "ContentBlockingGeneratorTests",
            dependencies: ["ContentBlockingGenerator"],
            swiftSettings: [
            ]),
        .target(
            name: "OnboardingKit",
            dependencies: ["Common", "ComponentLibrary"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "OnboardingKitTests",
            dependencies: ["OnboardingKit"],
            swiftSettings: [
            ]),
        .target(
            name: "ActionExtensionKit",
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "ActionExtensionKitTests",
            dependencies: ["ActionExtensionKit"],
            swiftSettings: [
            ]),
        .executableTarget(
            name: "ExecutableContentBlockingGenerator",
            dependencies: ["ContentBlockingGenerator"]),
    ]
)
