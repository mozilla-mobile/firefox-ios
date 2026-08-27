import ProjectDescription

/// App extension targets (ShareTo, WidgetKitExtension).
/// Uses ExtensionConfigurations to avoid duplicating the six build configurations per extension.
public enum ExtensionTargets {

    public static func all() -> [Target] {
        [shareTo(), widgetKitExtension()]
    }

    static func shareTo() -> Target {
        .target(
            name: "ShareTo",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "$(MOZ_BUNDLE_ID).ShareTo",
            infoPlist: .file(path: "Extensions/ShareTo/Info.plist"),
            sources: [
                "Extensions/ShareTo/**/*.swift",
                .glob("Providers/**/*.swift", excluding: [
                    "Providers/Merino/**/*.swift",
                    "Providers/TopSitesProvider.swift",
                    "Providers/TopSitesWidgetManager.swift"
                ]),
                "Push/Autopush.swift",
                "Push/PushConfiguration.swift",
                "Client/Frontend/Extensions/DevicePickerViewController.swift",
                "Client/Frontend/DevicePickerTableViewCell.swift",
                "Client/Frontend/DevicePickerTableViewHeaderCell.swift",
                "Client/Frontend/HostingTableViewCell.swift",
                "Client/Frontend/InstructionsView.swift",
                "Client/Frontend/HelpView.swift",
                "Client/Frontend/Share/SendToDeviceHelper.swift",
                "Client/Application/AccessibilityIdentifiers.swift",
                "Client/Frontend/Browser/Event Queue/EventQueue.swift",
                "Client/Frontend/Browser/Event Queue/AppEvent.swift",
                "Client/Frontend/Browser/URIFixup.swift",
                "Client/Frontend/Browser/DefaultSearchPrefs.swift",
                "Client/Frontend/Browser/String+Punycode.swift",
                "Client/Extensions/Locale+possibilitiesForLanguageIdentifier.swift",
                "Client/Frontend/Theme/LegacyThemeManager/LegacyTheme.swift",
                "Client/Frontend/Theme/LegacyThemeManager/photon-colors.swift",
                "Client/Utils/DispatchQueueHelper.swift",
                "Client/Application/UIConstants.swift",
                "Client/ImageIdentifiers.swift",
                "Client/Extensions/AnyHashable.swift",
                "Client/Ecosia/UI/Theme/EcosiaColor.swift",
                "Client/Ecosia/UI/Theme/EcosiaThemeManager.swift",
                "Client/Ecosia/UI/Theme/EcosiaLightTheme.swift",
                "Client/Ecosia/UI/Theme/EcosiaDarkTheme.swift",
                "Client/Utils/LocaleProvider.swift",
                "Client/Application/RemoteSettings/Application Services/RemoteSettingsServiceSyncCoordinator.swift"
            ],
            resources: [
                "Extensions/ShareTo/**/*.{xcassets,strings,stringsdict}",
                "Ecosia/UI/ShareToAssets.xcassets"
            ],
            scripts: BuildScripts.removeFrameworkScriptFromExtensionTargets,
            dependencies: [
                .target(name: "Account"),
                .target(name: "Storage"),
                .target(name: "Sync"),
                .target(name: "Localizations"),
                .sdk(name: "Ecosia", type: .framework),
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .sdk(name: "ImageIO", type: .framework),
                .package(product: "Fuzi"),
                .package(product: "Shared"),
                .package(product: "SnapKit"),
                .package(product: "Common")
            ],
            settings: .settings(
                base: BuildConfigurations.baseSettings.merging([
                    "SKIP_INSTALL": "NO",
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                    "OTHER_SWIFT_FLAGS": "$(inherited) -DMOZ_TARGET_SHARETO"
                ], uniquingKeysWith: { _, new in new }),
                configurations: ExtensionConfigurations.configurations(suffix: "ShareTo")
            )
        )
    }

    static func widgetKitExtension() -> Target {
        .target(
            name: "WidgetKitExtension",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "$(MOZ_BUNDLE_ID).WidgetKit",
            infoPlist: .file(path: "WidgetKit/Info.plist"),
            sources: [
                "WidgetKit/**/*.swift",
                "WidgetKit/**/*.intentdefinition",
                "Client/Frontend/Browser/DownloadHelper/DownloadLiveActivityIntent.swift",
                "Client/TabManagement/Legacy/LegacyTabDataRetriever.swift",
                "Client/TabManagement/Legacy/LegacyTabFileManager.swift",
                "Client/TabManagement/Legacy/LegacyTabGroupData.swift",
                "Client/TabManagement/Legacy/LegacySavedTab.swift",
                "Client/Frontend/Browser/PrivilegedRequest.swift",
                "Client/ImageIdentifiers.swift",
                "Client/Frontend/InternalSchemeHandler/InternalSchemeHandler.swift",
                "Client/Frontend/Theme/LegacyThemeManager/photon-colors.swift",
                "Client/Ecosia/UI/Theme/EcosiaColor.swift",
                "Client/Ecosia/UI/Theme/EcosiaThemeManager.swift",
                "Client/Ecosia/UI/Theme/EcosiaLightTheme.swift",
                "Client/Ecosia/UI/Theme/EcosiaDarkTheme.swift",
                "Client/Utils/DispatchQueueHelper.swift",
                "Shared/TimeConstants.swift",
                "Shared/AppInfo.swift"
            ],
            resources: [
                "WidgetKit/**/*.{xcassets,strings,stringsdict}",
                "PrivacyInfo.xcprivacy"
            ],
            scripts: BuildScripts.removeFrameworkScriptFromExtensionTargets,
            dependencies: [
                .target(name: "Localizations"),
                .target(name: "Storage"),
                .sdk(name: "Ecosia", type: .framework),
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .sdk(name: "WidgetKit", type: .framework),
                .sdk(name: "SwiftUI", type: .framework),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(
                base: BuildConfigurations.baseSettings.merging([
                    "SKIP_INSTALL": "NO",
                    "APPLICATION_EXTENSION_API_ONLY": "YES"
                ], uniquingKeysWith: { _, new in new }),
                configurations: ExtensionConfigurations.configurations(suffix: "WidgetKit")
            )
        )
    }
}
