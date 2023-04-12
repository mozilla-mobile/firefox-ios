// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenAIClient",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "OpenAIClient", targets: ["OpenAIClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nate-parrott/openai-streaming-completions-swift", branch: "main"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "main"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", branch: "main"),
    ],
    targets: [
        .target(
            name: "OpenAIClient",
            dependencies: [
                .product(name: "OpenAIStreamingCompletions", package: "openai-streaming-completions-swift"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "OpenAIClientTests",
            dependencies: ["OpenAIClient"]
        ),
    ]
)
