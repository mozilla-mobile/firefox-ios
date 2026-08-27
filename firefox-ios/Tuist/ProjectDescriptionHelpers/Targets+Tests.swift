import ProjectDescription

/// All test targets (unit tests and UI tests).
public enum TestTargets {

    public static func all() -> [Target] {
        [
            accountTests(),
            clientTests(),
            storagePerfTests(),
            storageTests(),
            sharedTests(),
            syncTelemetryTests(),
            syncTests(),
            l10nSnapshotTests(),
            ecosiaSnapshotTests(),
            ecosiaTests(),
        ]
    }

    /// Ecosia: settings for a test target hosted by the `Client` app (one that depends on `Client` and
    /// so links with `-bundle_loader`). Use this instead of `testBaseSettings` for those targets.
    ///
    /// Xcode leaves SPM dynamic package products off an app-hosted test bundle's link line, assuming the
    /// host provides them, and relies on `ld` resolving them transitively through `Client.debug.dylib`.
    /// That works locally but not on CI, where test code calling package API directly (`Maybe`,
    /// `Deferred`, `Date.now()`, `SnowplowTracker.Structured`) failed with "Undefined symbols". Declaring
    /// the dependency does not help — the generated project already lists them correctly.
    ///
    /// `-undefined dynamic_lookup` defers those symbols to load time, which is safe because the bundle
    /// loads into the host process where the frameworks are already loaded. We defer rather than name the
    /// frameworks explicitly because their names are not stable: Xcode promotes a static package product
    /// to a hashed dynamic framework based on how many targets link it, so both the name and whether it
    /// is dynamic at all differ between local and CI. The tradeoff is that a genuinely missing symbol
    /// fails at bundle load instead of at link time, naming the symbol either way.
    static let appHostedTestSettings: SettingsDictionary = BuildConfigurations.testBaseSettings
        .merging([
            "OTHER_LDFLAGS": .array(["$(inherited)", "-Xlinker", "-undefined", "-Xlinker", "dynamic_lookup"]),
        ], uniquingKeysWith: { _, new in new })

    static func accountTests() -> Target {
        .target(
            name: "AccountTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.AccountTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/AccountTests/**/*.swift"],
            dependencies: [
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .package(product: "Shared"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Account/Account-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func clientTests() -> Target {
        .target(
            name: "ClientTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.ClientTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/ClientTests/**/*.swift"],
            resources: [
                // Ecosia: Test fixtures ClientTests loads from its own bundle (wallpaper JSON, search/pocket
                // lists, images, search-engine xcassets). Upstream's Client.xcodeproj bundles these; the Tuist
                // migration dropped them, causing `Fatal error: Missing file: wallpaper*.json` /
                // `Couldn't find test file` crashes. (MOB-4384)
                .glob(pattern: "firefox-ios-tests/Tests/ClientTests/**/*.json",
                      excluding: ["firefox-ios-tests/Tests/ClientTests/**/*.xcassets/**"]),
                "firefox-ios-tests/Tests/ClientTests/image.png",
                "firefox-ios-tests/Tests/ClientTests/image.gif",
                "firefox-ios-tests/Tests/ClientTests/Frontend/Browser/SearchEngines/SearchEngineTestAssets.xcassets",
            ],
            dependencies: [
                .target(name: "Client"),
                .target(name: "RustMozillaAppServices"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "Kingfisher"),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
                // Ecosia: ClientTests/Toolbar/ToolbarMiddlewareTests imports ToolbarKit directly and its
                // type metadata is not resolvable through the Client host. Declaring the dependency is
                // enough here only because ToolbarKit links statically; see ``appHostedTestSettings``
                // for why dynamic products need more. (MOB-4384)
                .package(product: "ToolbarKit"),
                .sdk(name: "z", type: .library),
            ],
            settings: .settings(base: appHostedTestSettings)
        )
    }

    static func storagePerfTests() -> Target {
        .target(
            name: "StoragePerfTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.StoragePerfTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/StoragePerfTests/**/*.swift"],
            dependencies: [
                .target(name: "Storage"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings)
        )
    }

    static func storageTests() -> Target {
        .target(
            name: "StorageTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.StorageTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/StorageTests/**/*.swift"],
            resources: [
                // Ecosia: certificate files and DB fixtures required by CertTests and TestBrowserDB.
                .glob(pattern: "firefox-ios-tests/Tests/StorageTests/**/*.pem"),
                .glob(pattern: "firefox-ios-tests/Tests/StorageTests/fixtures/**"),
            ],
            dependencies: [
                .target(name: "Client"),
                .target(name: "Storage"),
                // Ecosia: RustAutofillTests and RustRemoteTabsTests import MozillaAppServices directly,
                // so StorageTests must link RustMozillaAppServices to resolve those symbols at link time.
                .target(name: "RustMozillaAppServices"),
                .package(product: "Common"),
                .package(product: "Shared"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: appHostedTestSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Storage/Storage-Bridging-Header.h",
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func sharedTests() -> Target {
        .target(
            name: "SharedTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.SharedTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SharedTests/**/*.swift"],
            dependencies: [
                // Ecosia: Host SharedTests in the Client app so Bundle.main is the .app bundle. The Ecosia
                // UserAgent/SupportUtils tests exercise production code that reads AppInfo.applicationBundle,
                // which fatalErrors when Bundle.main is the bare xctest agent (logic-test host). Depending on the
                // Client app target makes Tuist app-host the test bundle, matching ClientTests/EcosiaTests. (MOB-4384)
                .target(name: "Client"),
                .package(product: "Common"),
                .package(product: "Shared"),
            ],
            settings: .settings(base: appHostedTestSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Shared/Shared-Bridging-Header.h",
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func syncTelemetryTests() -> Target {
        .target(
            name: "SyncTelemetryTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.SyncTelemetryTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SyncTelemetryTests/**/*.swift"],
            dependencies: [
                .target(name: "Client"),
                .package(product: "Glean"),
                .package(product: "Shared"),
            ],
            settings: .settings(base: appHostedTestSettings)
        )
    }

    static func syncTests() -> Target {
        .target(
            name: "SyncTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.SyncTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SyncTests/**/*.swift"],
            dependencies: [
                .target(name: "Sync"),
                .target(name: "RustMozillaAppServices"),
                .package(product: "Common"),
                .package(product: "Shared"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/firefox-ios-tests/Tests/SyncTests/SyncTests-Bridging-Header.h",
                "HEADER_SEARCH_PATHS": ["$(inherited)", "$(SRCROOT)/Sync", "$(SRCROOT)/Shared", "$(SRCROOT)/Storage"]
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func l10nSnapshotTests() -> Target {
        .target(
            name: "L10nSnapshotTests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "org.mozilla.ios.L10nSnapshotTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/L10nSnapshotTests/**/*.swift"],
            dependencies: [
                .target(name: "Client"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "MappaMundi"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings)
        )
    }

    static func ecosiaSnapshotTests() -> Target {
        .target(
            name: "EcosiaSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.EcosiaSnapshot",
            infoPlist: .default,
            sources: ["EcosiaTests/SnapshotTests/**/*.swift"],
            dependencies: [
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "SnapshotTesting"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings)
        )
    }

    static func ecosiaTests() -> Target {
        .target(
            name: "EcosiaTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.Ecosia",
            infoPlist: .default,
            sources: [
                .glob("EcosiaTests/**/*.swift", excluding: ["EcosiaTests/SnapshotTests/**/*.swift"]),
                // Shared ClientTests helpers required by integration tests
                "firefox-ios-tests/Tests/ClientTests/XCTestCaseExtensions.swift",
                "firefox-ios-tests/Tests/ClientTests/ProfileTest.swift",
                "firefox-ios-tests/Tests/ClientTests/DependencyInjection/*.swift",
                "firefox-ios-tests/Tests/ClientTests/Mocks/*.swift",
                "firefox-ios-tests/Tests/ClientTests/Coordinators/Mocks/*.swift",
                "firefox-ios-tests/Tests/ClientTests/Frontend/Theme/MockThemeManager.swift",
                "firefox-ios-tests/Tests/ClientTests/Utils/StoreTestUtility.swift",
                "firefox-ios-tests/Tests/ClientTests/Microsurvey/Mock/MockMicrosurveySurfaceManager.swift",
            ],
            resources: [
                // Ecosia: JSON fixtures, HTML import/export files, and other test assets
                // required by NewsTests, ReferralsTests, and bookmark import/export tests.
                // Bundle identifier must match bundleId ("com.ecosia.tests.Ecosia") in Bundle+EcosiaTests.swift.
                .glob(pattern: "EcosiaTests/Core/Resources/**"),
            ],
            dependencies: [
                .target(name: "Client"),
                .target(name: "Ecosia"),
                .target(name: "Storage"),
                // Ecosia: EcosiaTests includes MockProfile, MockHistoryHandler, and
                // BookmarksHandlerMock which import MozillaAppServices directly.
                // RustMozillaAppServices must be linked to resolve those symbols at link time.
                .target(name: "RustMozillaAppServices"),
                // Ecosia: ActionExtensionKit is needed by ShareTo/FirefoxURLBuilderSchemeFallbackTests.swift, 
                // which guards the "ecosia" scheme fallback customization against upstream regressions.
                .package(product: "ActionExtensionKit"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
                .package(product: "SnowplowTracker"),
                .package(product: "TabDataStore"),
                .package(product: "ToolbarKit"),
                .package(product: "ViewInspector"),
            ],
            settings: .settings(base: appHostedTestSettings)
        )
    }
}
