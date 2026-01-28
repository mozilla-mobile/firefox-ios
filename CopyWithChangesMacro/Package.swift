// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "CopyWithChangesMacro",
    platforms: [.macOS(.v10_15), .iOS(.v15), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "CopyWithChanges",
            targets: ["CopyWithChanges"]
        ),
        .executable(
            name: "CopyWithChangesClient",
            targets: ["CopyWithChangesClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "CopyWithChangesMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "CopyWithChanges", dependencies: ["CopyWithChangesMacros"]),
        .executableTarget(name: "CopyWithChangesClient", dependencies: ["CopyWithChanges"]),
        .testTarget(
            name: "CopyWithChangesTests",
            dependencies: [
                "CopyWithChangesMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
