// swift-tools-version: 5.6
import PackageDescription

let checksum = "52eae47464bda6c5e8563d8e0ae9aafd3c3de45306c0e1ad9c34d7f739f0afff"
let version = "145.0.20250924215458"
let url = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.145.20250924215458/artifacts/public/build/MozillaRustComponents.xcframework.zip"

// Focus xcframework
let focusChecksum = "680c41cc6004b5e42d215b99e92d85aa0bb080d7a76c908fb8be11b6d9bc4491"
let focusUrl = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.145.20250924215458/artifacts/public/build/FocusRustComponents.xcframework.zip"

let package = Package(
    name: "MozillaRustComponentsSwift",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "MozillaRustComponents", targets: ["MozillaAppServices"]),
        .library(name: "FocusRustComponents", targets: ["FocusAppServices"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mozilla/glean-swift", from: "65.1.1"),
    ],
    targets: [
        // A wrapper around our binary target that combines + any swift files we want to expose to the user
        .target(
            name: "MozillaAppServices",
            dependencies: ["MozillaRustComponents", .product(name: "Glean", package: "glean-swift")],
            path: "Sources/MozillaRustComponentsWrapper"
        ),
        .target(
            name: "FocusAppServices",
            dependencies: [
                .target(name: "FocusRustComponents", condition: .when(platforms: [.iOS]))
            ],
            path: "Sources/FocusRustComponentsWrapper"
        ),
        .binaryTarget(
            name: "MozillaRustComponents",
            //
            // For release artifacts, reference the MozillaRustComponents as a URL with checksum.
            // IMPORTANT: The checksum has to be on the line directly after the `url`
            // this is important for our release script so that all values are updated correctly
            url: url,
            checksum: checksum

            // For local testing, you can point at an (unzipped) XCFramework that's part of the repo.
            // Note that you have to actually check it in and make a tag for it to work correctly.
            //
            //path: "./MozillaRustComponents.xcframework"
        ),
        .binaryTarget(
            name: "FocusRustComponents",
            //
            // For release artifacts, reference the MozillaRustComponents as a URL with checksum.
            // IMPORTANT: The checksum has to be on the line directly after the `url`
            // this is important for our release script so that all values are updated correctly
            url: focusUrl,
            checksum: focusChecksum

            // For local testing, you can point at an (unzipped) XCFramework that's part of the repo.
            // Note that you have to actually check it in and make a tag for it to work correctly.
            //
            //path: "./FocusRustComponents.xcframework"
        ),
        // Tests
        .testTarget(
            name: "MozillaRustComponentsTests",
            dependencies: ["MozillaAppServices"]
        ),
    ]
)
