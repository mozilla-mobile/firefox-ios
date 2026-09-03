// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Danger",
    platforms: [.iOS("15"), .macOS("11")],
    products: [
        // Suffixed to avoid clashing with the "DangerDeps" product that danger/swift itself
        // exports at the pinned revision; danger-swift matches `DangerDeps[A-Za-z]*`.
        .library(name: "DangerDepsFirefox", type: .dynamic, targets: ["DangerDependencies"]), // dev
    ],
    dependencies: [
        // Pinned to danger/swift#663 rather than a tag: Xcode 27's SwiftPM emits modules flat in
        // .build/debug instead of .build/debug/Modules, so 3.22.x fails Dangerfile eval with
        // "no such module 'Danger'". Move back to `exact:` once a release includes the fix.
        .package(url: "https://github.com/danger/swift.git", revision: "53887414329bbf7deecde31f7d1d20bb15e6c4d3"), // dev
        .package(url: "https://github.com/f-meloni/danger-swift-coverage", exact: "1.2.1") // dev
    ],
    targets: [
        .target(
            name: "DangerDependencies",
            dependencies: [
                .product(name: "Danger", package: "swift"),
                .product(name: "DangerSwiftCoverage", package: "danger-swift-coverage")
            ]
        ) // dev
    ]
)
