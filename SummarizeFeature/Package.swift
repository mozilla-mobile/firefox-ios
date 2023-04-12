// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SummarizeFeature",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "SummarizeFeature", targets: ["SummarizeFeature"]),
    ],
    dependencies: [
        Package.Dependency.package(path: "../OpenAIClient"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "main"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", branch: "main"),
    ],
    targets: [
        .target(
            name: "SummarizeFeature",
            dependencies: [
                "OpenAIClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "SummarizeFeatureTests",
            dependencies: ["SummarizeFeature"]
        ),
    ]
)
