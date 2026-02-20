// swift-tools-version: 5.10
import PackageDescription

let checksum = "839e3ebb3e4e3ab64f78e80ff42eb6c3f538b270f7c0c1ba5fb99257aef907c3"
let version = "149.0.20260218050310"
let url = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.149.20260218050310/artifacts/public/build/MozillaRustComponents.xcframework.zip"
    "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.148.20251217050246/artifacts/public/build/MozillaRustComponents.xcframework.zip"

// Focus xcframework
let focusChecksum = "2f0ddb2b77c920df241714f40a056ff7edb874d71280a03dc567160ed682dc73"
let focusUrl = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.swift.149.20260218050310/artifacts/public/build/FocusRustComponents.xcframework.zip"
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
