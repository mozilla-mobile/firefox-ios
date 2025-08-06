// swift-tools-version: 5.6
import PackageDescription

let checksum = "59187d32ffb48f8d9af468bbb88a7d0e09e1b3f2099a785dd187f9bd3cafb72e"
let version = "143.0.20250806050417"
let url = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.143.20250806050417/artifacts/public/build/MozillaRustComponents.xcframework.zip"

// Focus xcframework
let focusChecksum = "92db36c2d988124ada8c59c9cd693a4715e28d731b2ba6f000053086375f535c"
let focusUrl = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.143.20250806050417/artifacts/public/build/FocusRustComponents.xcframework.zip"

let package = Package(
    name: "MozillaRustComponentsSwift",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "MozillaRustComponents", targets: ["MozillaAppServices"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mozilla/glean-swift", from: "64.1.0"),
    ],
    targets: [
        // A wrapper around our binary target that combines + any swift files we want to expose to the user
        .target(
            name: "MozillaAppServices",
            dependencies: ["MozillaRustComponents", .product(name: "Glean", package: "glean-swift")],
            path: "Sources/MozillaRustComponentsWrapper"
        ),
        .target(
            name: "FocusMozillaAppServices",
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
