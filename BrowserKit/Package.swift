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
    dependencies: [],
    targets: [
        .target(
            name: "SiteImageView",
            dependencies: []),
        .testTarget(
            name: "SiteImageViewTests",
            dependencies: ["SiteImageView"]),
    ]
)
