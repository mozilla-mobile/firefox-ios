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
    ],
    dependencies: [
        .package(
            url: "https://github.com/nbhasin2/Fuzi.git",
            branch: "master")
    ],
    targets: [
        .target(
            name: "SiteImageView",
            dependencies: ["Fuzi"]),
        .testTarget(
            name: "SiteImageViewTests",
            dependencies: ["SiteImageView"]),
    ]
)
