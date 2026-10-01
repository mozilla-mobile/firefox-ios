// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AppAttestKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AppAttestKit",
            targets: ["AppAttestKit"]),
        .library(
            name: "AppAttestTestKit",
            targets: ["AppAttestTestKit"]),
    ],
    targets: [
        .target(
            name: "AppAttestKit",
            dependencies: [],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "AppAttestKitTests",
            dependencies: ["AppAttestKit", "AppAttestTestKit"],
            swiftSettings: []
        ),
        .target(
            name: "AppAttestTestKit",
            dependencies: ["AppAttestKit"]
        ),
    ]
)
