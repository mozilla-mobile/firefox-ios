// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SummarizeKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SummarizeKit",
            targets: ["SummarizeKit"]),
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../Components"),
        .package(path: "../../AppAttestKit"),
        .package(path: "../LLMKit"),
        .package(
            url: "https://github.com/johnxnguyen/Down.git",
            exact: "0.11.0"),
    ],
    targets: [
        .target(
            name: "SummarizeKit",
            dependencies: [
                .product(name: "AppAttestKit", package: "AppAttestKit"),
                .product(name: "Common", package: "Core"),
                .product(name: "ComponentLibrary", package: "Components"),
                "Down",
                .product(name: "LLMKit", package: "LLMKit"),
                .product(name: "Shared", package: "Core")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "SummarizeKitTests",
            dependencies: [
                "SummarizeKit",
                .product(name: "TestKit", package: "Core")
            ]),
    ]
)
