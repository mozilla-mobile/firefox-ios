// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "VersionBump",
    products: [
        .executable(name: "VersionBump", targets: ["VersionBump"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kareman/SwiftShell.git", from: "4.1.2"),
        .package(url: "https://github.com/sharplet/Regex.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "VersionBump",
            dependencies: ["SwiftShell", "Regex"],
            path: "./")
    ]
)
