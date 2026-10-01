// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "UnifiedSearchKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "UnifiedSearchKit",
            targets: ["UnifiedSearchKit"]),
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../Components"),
    ],
    targets: [
        .target(
            name: "UnifiedSearchKit",
            dependencies: [
                .product(name: "Common", package: "Core"),
                .product(name: "ComponentLibrary", package: "Components")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
    ]
)
