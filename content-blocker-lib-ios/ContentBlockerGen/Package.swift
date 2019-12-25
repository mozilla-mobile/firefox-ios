// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ContentBlockerGen",
    products: [
        .executable(name: "ContentBlockerGen", targets: ["ContentBlockerGen"]),
        .library(name: "ContentBlockerGenLib", targets: ["ContentBlockerGenLib"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ContentBlockerGen",
            dependencies: ["ContentBlockerGenLib"]),
        .target(
            name: "ContentBlockerGenLib", dependencies: []),
        .testTarget(
            name: "ContentBlockerGenTests",
            dependencies: ["ContentBlockerGen"]),
    ]
)
