// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LLMKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "LLMKit",
            targets: ["LLMKit"]),
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../AppAttestKit"),
        .package(path: "../MLPAKit"),
    ],
    targets: [
        .target(
            name: "LLMKit",
            dependencies: [
                .product(name: "MLPAKit", package: "MLPAKit"),
                .product(name: "AppAttestKit", package: "AppAttestKit"),
                .product(name: "Common", package: "Core"),
                .product(name: "Shared", package: "Core")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "LLMKitTests",
            dependencies: [
                "LLMKit",
                .product(name: "MLPAKit", package: "MLPAKit"),
                .product(name: "AppAttestKit", package: "AppAttestKit"),
                .product(name: "AppAttestTestKit", package: "AppAttestKit"),
                .product(name: "TestKit", package: "Core")
            ]),
    ]
)
