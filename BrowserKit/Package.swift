// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "BrowserKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SiteImageView",
            targets: ["SiteImageView"]),
        .library(
            name: "Common",
            targets: ["Common"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/nbhasin2/Fuzi.git",
            branch: "master"),
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            exact: "7.2.2"),
        .package(
            url: "https://github.com/AliSoftware/Dip.git",
            exact: "7.1.1"),
    ],
    targets: [
        .target(
            name: "SiteImageView",
            dependencies: ["Fuzi", "Kingfisher", "Common"]),
        .testTarget(
            name: "SiteImageViewTests",
            dependencies: ["SiteImageView"]),
        .target(
            name: "Common",
            dependencies: ["Dip"]),
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"]),
    ]
)
