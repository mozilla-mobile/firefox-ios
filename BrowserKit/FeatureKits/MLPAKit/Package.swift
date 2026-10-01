// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MLPAKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MLPAKit",
            targets: ["MLPAKit"]),
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../AppAttestKit"),
    ],
    targets: [
        .target(
            name: "MLPAKit",
            dependencies: [
                .product(name: "AppAttestKit", package: "AppAttestKit"),
                .product(name: "Common", package: "Core"),
                .product(name: "JWTKit", package: "Core"),
                .product(name: "Shared", package: "Core")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "MLPAKitTests",
            dependencies: [
                "MLPAKit",
                .product(name: "AppAttestKit", package: "AppAttestKit"),
                .product(name: "AppAttestTestKit", package: "AppAttestKit"),
                .product(name: "TestKit", package: "Core")
            ]),
    ]
)
