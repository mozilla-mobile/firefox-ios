// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "Shared",
                 targets: ["Shared"]),
        .library(
            name: "Common",
            targets: ["Common"]),
        .library(
            name: "TabDataStore",
            targets: ["TabDataStore"]),
        .library(
            name: "WebEngine",
            targets: ["WebEngine"]),
        .library(name: "TestKit",
                 targets: ["TestKit"]),
        .library(name: "JWTKit",
                 targets: ["JWTKit"]),
        .library(
            name: "ContentBlockingGenerator",
            targets: ["ContentBlockingGenerator"]),
        .library(
            name: "ActionExtensionKit",
            targets: ["ActionExtensionKit"]),
        .executable(
            name: "ExecutableContentBlockingGenerator",
            targets: ["ExecutableContentBlockingGenerator"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/AliSoftware/Dip.git",
            exact: "7.1.1"),
        .package(
            url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git",
            exact: "2.1.1"),
        .package(
            url: "https://github.com/getsentry/sentry-cocoa.git",
            exact: "9.10.0"),
        .package(
            url: "https://github.com/nbhasin2/GCDWebServer.git",
            branch: "master"),
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
        .target(
            name: "TestKit",
            dependencies: ["Common", "Shared"]
        ),
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
