// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Components",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SiteImageView",
            targets: ["SiteImageView"]),
        .library(
            name: "ComponentLibrary",
            targets: ["ComponentLibrary"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(
            url: "https://github.com/nbhasin2/Fuzi.git",
            branch: "master"),
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            exact: "8.12.0"),
        .package(
            url: "https://github.com/nbhasin2/GCDWebServer.git",
            branch: "master"),
        .package(
            url: "https://github.com/swhitty/SwiftDraw",
            exact: "0.29.0"),
    ],
    targets: [
        .target(
            name: "ComponentLibrary",
            dependencies: [
                .product(name: "Common", package: "Core"),
                "SiteImageView"
            ],
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
            dependencies: [
                "Fuzi",
                "Kingfisher",
                .product(name: "Common", package: "Core"),
                "SwiftDraw"
            ],
            exclude: ["README.md"],
            resources: [.process("BundledTopSitesFavicons.xcassets")],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "SiteImageViewTests",
            dependencies: [
                "SiteImageView",
                .product(name: "TestKit", package: "Core"),
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
    ]
)
