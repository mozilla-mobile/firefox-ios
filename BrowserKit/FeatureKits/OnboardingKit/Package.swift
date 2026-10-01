// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OnboardingKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "OnboardingKit",
            targets: ["OnboardingKit"]),
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../Components"),
    ],
    targets: [
        .target(
            name: "OnboardingKit",
            dependencies: [
                .product(name: "Common", package: "Core"),
                .product(name: "ComponentLibrary", package: "Components")
            ],
            resources: [
                .process("IntroVideo.mp4")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "OnboardingKitTests",
            dependencies: [
                "OnboardingKit"
            ]),
    ]
)
