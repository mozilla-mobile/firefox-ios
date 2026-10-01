// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Redux",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Redux",
            targets: ["Redux"]),
        .library(
            name: "ReduxTestKit",
            targets: ["ReduxTestKit"]),
    ],
    dependencies: [
        .package(path: "../Core"),
    ],
    targets: [
        .target(
            name: "Redux",
            dependencies: [.product(name: "Common", package: "Core")],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "ReduxTests",
            dependencies: ["Redux"],
            swiftSettings: [
            ]
        ),
        .target(
            name: "ReduxTestKit",
            dependencies: ["Redux"]
        ),
    ]
)
