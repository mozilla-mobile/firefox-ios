// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Sentry",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v2),
    ],
    products: [
        .library(
            name: "Sentry",
            targets: ["Sentry"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Sentry",
            dependencies: [
                "SentryCrash/Installations",
                "SentryCrash/Recording",
                "SentryCrash/Recording/Monitors",
                "SentryCrash/Recording/Tools",
                "SentryCrash/Reporting/Filters",
                "SentryCrash/Reporting/Filters/Tools",
                "SentryCrash/Reporting/Tools",
            ],
            path: "Sources/Sentry",
            cxxSettings: [
                .headerSearchPath("../SentryCrash/Installations"),
                .headerSearchPath("../SentryCrash/Recording"),
                .headerSearchPath("../SentryCrash/Recording/Monitors"),
                .headerSearchPath("../SentryCrash/Recording/Tools"),
                .headerSearchPath("../SentryCrash/Reporting/Filters"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
            ]
        ),

        .target(
            name: "SentryCrash/Installations",
            path: "Sources/SentryCrash/Installations",
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("../Recording"),
                .headerSearchPath("../Recording/Monitors"),
                .headerSearchPath("../Recording/Tools"),
                .headerSearchPath("../Reporting/Filters"),
                .headerSearchPath("../Reporting/Tools"),
            ]
        ),

        .target(
            name: "SentryCrash/Recording",
            path: "Sources/SentryCrash/Recording",
            exclude: [
                "Monitors",
                "Tools",
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("Tools"),
                .headerSearchPath("Monitors"),
                .headerSearchPath("../Reporting/Filters"),
            ]
        ),

        .target(
            name: "SentryCrash/Recording/Monitors",
            path: "Sources/SentryCrash/Recording/Monitors",
            publicHeadersPath: ".",
            cxxSettings: [
                .define("GCC_ENABLE_CPP_EXCEPTIONS", to: "YES"),
                .headerSearchPath(".."),
                .headerSearchPath("../Tools"),
                .headerSearchPath("../../Reporting/Filters"),
            ]
        ),

        .target(
            name: "SentryCrash/Recording/Tools",
            path: "Sources/SentryCrash/Recording/Tools",
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath(".."),
            ]
        ),

        .target(
            name: "SentryCrash/Reporting/Filters",
            path: "Sources/SentryCrash/Reporting/Filters",
            exclude: [
                "Tools",
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("Tools"),
                .headerSearchPath("../../Recording/Tools"),
            ]
        ),

        .target(
            name: "SentryCrash/Reporting/Filters/Tools",
            path: "Sources/SentryCrash/Reporting/Filters/Tools",
            publicHeadersPath: "."
        ),

        .target(
            name: "SentryCrash/Reporting/Tools",
            path: "Sources/SentryCrash/Reporting/Tools",
            publicHeadersPath: "."
        ),

        .testTarget(
            name: "SentrySwiftTests",
            dependencies: [
                "Sentry",
            ],
            path: "Tests/SentryTests",
            sources: [
                "SentrySwiftTests.swift",
            ]
        ),

        // TODO: make Objective-C tests work.
        // .testTarget(
        //     name: "SentryTests",
        //     dependencies: [
        //         "Sentry",
        //     ],
        //     exclude: [
        //         "SentrySwiftTests.swift",
        //     ]
        // ),
    ]
)