// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ToolbarKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ToolbarKit",
            targets: ["ToolbarKit"]),
    ],
    dependencies: [
        .package(path: "../../Core"),
    ],
    targets: [
        .target(
            name: "ToolbarKit",
            dependencies: [
                .product(name: "Common", package: "Core")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "ToolbarKitTests",
            dependencies: [
                "ToolbarKit",
                .product(name: "TestKit", package: "Core")
            ]),
    ]
)
