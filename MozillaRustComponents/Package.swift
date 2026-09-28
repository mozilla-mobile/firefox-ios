// swift-tools-version: 5.10
import PackageDescription

let checksum = "16070fd26a134da2cf1e6ea4fed2d2c88bbdc3585f301a727699c1366076b8c3"
let version = "158.0.20260924050203"
let url = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.158.20260924050203/artifacts/public/build/MozillaRustComponents.xcframework.zip"

// Focus xcframework
let focusChecksum = "e1fdaa1f81f3c3ac5abf16ccd0634884984136d9d3b6afc641daabf05eb23490"
let focusUrl = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.158.20260924050203/artifacts/public/build/FocusRustComponents.xcframework.zip"

let package = Package(
    name: "MozillaRustComponentsSwift",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "MozillaRustComponents", targets: ["MozillaAppServices"]),
        .library(name: "FocusRustComponents", targets: ["FocusAppServices"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mozilla/glean-swift", from: "70.1.0")
    ],
    targets: [
        // A wrapper around our binary target that combines + any swift files we want to expose to the user
        .target(
            name: "MozillaAppServices",
            dependencies: [
                "MozillaRustComponents", .product(name: "Glean", package: "glean-swift"),
            ],
            path: "Sources/MozillaRustComponentsWrapper",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .unsafeFlags(["-enable-testing"]),
            ],
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
