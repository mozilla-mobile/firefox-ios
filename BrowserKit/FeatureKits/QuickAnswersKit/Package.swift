// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "QuickAnswersKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "QuickAnswersKit",
            targets: ["QuickAnswersKit"]),
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../Components"),
        .package(path: "../MLPAKit"),
        .package(path: "../LLMKit"),
    ],
    targets: [
        .target(
            name: "QuickAnswersKit",
            dependencies: [
                .product(name: "Common", package: "Core"),
                .product(name: "Shared", package: "Core"),
                .product(name: "MLPAKit", package: "MLPAKit"),
                .product(name: "LLMKit", package: "LLMKit"),
                .product(name: "SiteImageView", package: "Components")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "QuickAnswersKitTests",
            dependencies: [
                "QuickAnswersKit",
                .product(name: "Shared", package: "Core"),
                .product(name: "TestKit", package: "Core")
            ]),
    ]
)
