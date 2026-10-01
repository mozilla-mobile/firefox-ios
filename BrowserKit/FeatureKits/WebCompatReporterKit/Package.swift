// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WebCompatReporterKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WebCompatReporterKit",
            targets: ["WebCompatReporterKit"]),
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../Components"),
    ],
    targets: [
        .target(
            name: "WebCompatReporterKit",
            dependencies: [
                .product(name: "Common", package: "Core"),
                .product(name: "ComponentLibrary", package: "Components")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "WebCompatReporterKitTests",
            dependencies: [
                "WebCompatReporterKit",
                .product(name: "TestKit", package: "Core")
            ]),
    ]
)
