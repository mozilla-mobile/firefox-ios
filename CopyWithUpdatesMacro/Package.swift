// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "CopyWithUpdatesMacro",
    platforms: [.macOS(.v10_15), .iOS(.v15), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "CopyWithUpdates",
            targets: ["CopyWithUpdates"]
        ),
        .executable(
            name: "CopyWithUpdatesClient",
            targets: ["CopyWithUpdatesClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "CopyWithUpdatesMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "CopyWithUpdates", dependencies: ["CopyWithUpdatesMacros"]),
        .executableTarget(name: "CopyWithUpdatesClient", dependencies: ["CopyWithUpdates"]),
        .testTarget(
            name: "CopyWithUpdatesTests",
            dependencies: [
                "CopyWithUpdatesMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
