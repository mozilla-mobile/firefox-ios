// swift-tools-version: 5.10
import PackageDescription

let checksum = "ef9ad19898e446f71c4c96714166cc17b99a65ee57f30022c680c3c553203e81"
let version = "149.0.20260127050311"
let url = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.149.20260127050311/artifacts/public/build/MozillaRustComponents.xcframework.zip"
    "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.148.20251217050246/artifacts/public/build/MozillaRustComponents.xcframework.zip"

// Focus xcframework
let focusChecksum = "1a7b8c38e70ebe6979ddbfa262fa39b686a113cffebfb087cff00c5379842bc2"
let focusUrl = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.149.20260127050311/artifacts/public/build/FocusRustComponents.xcframework.zip"
    "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.148.20251217050246/artifacts/public/build/FocusRustComponents.xcframework.zip"

let package = Package(
    name: "MozillaRustComponentsSwift",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "MozillaRustComponents", targets: ["MozillaAppServices"]),
        .library(name: "FocusRustComponents", targets: ["FocusAppServices"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mozilla/glean-swift", from: "66.3.0")
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
                .enableExperimentalFeature("StrictConcurrency")
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
