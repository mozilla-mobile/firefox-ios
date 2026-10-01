// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MenuKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MenuKit",
            targets: ["MenuKit"]),
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../Components"),
    ],
    targets: [
        .target(
            name: "MenuKit",
            dependencies: [
                .product(name: "Common", package: "Core"),
                .product(name: "ComponentLibrary", package: "Components"),
                .product(name: "SiteImageView", package: "Components")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "MenuKitTests",
            dependencies: [
                "MenuKit"
            ]),
    ]
)
