/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Telemetry

//
// 'Unified Telemetry' is the name for Mozilla's telemetry system
//
class UnifiedTelemetry {

    // Boolean flag to temporarily remember if we crashed during the
    // last run of the app. We cannot simply use `Sentry.crashedLastLaunch`
    // because we want to clear this flag after we've already reported it
    // to avoid re-reporting the same crash multiple times.
    private var crashedLastLaunch: Bool

    private func migratePathComponentInDocumentsDirectory(_ pathComponent: String, to destinationSearchPath: FileManager.SearchPathDirectory) {
        guard let oldPath = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(pathComponent).path, FileManager.default.fileExists(atPath: oldPath) else {
            return
        }

        print("Migrating \(pathComponent) from ~/Documents to \(destinationSearchPath)")
        guard let newPath = try? FileManager.default.url(for: destinationSearchPath, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(pathComponent).path else {
            print("Unable to get destination path \(destinationSearchPath) to move \(pathComponent)")
            return
        }

        do {
            try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)

            print("Migrated \(pathComponent) to \(destinationSearchPath) successfully")
        } catch let error as NSError {
            print("Unable to move \(pathComponent) to \(destinationSearchPath): \(error.localizedDescription)")
        }
    }

    init(profile: Profile) {
        crashedLastLaunch = Sentry.crashedLastLaunch

        migratePathComponentInDocumentsDirectory("MozTelemetry-Default-core", to: .cachesDirectory)
        migratePathComponentInDocumentsDirectory("MozTelemetry-Default-mobile-event", to: .cachesDirectory)
        migratePathComponentInDocumentsDirectory("eventArray-MozTelemetry-Default-mobile-event.json", to: .cachesDirectory)

        NotificationCenter.default.addObserver(self, selector: #selector(uploadError), name: Telemetry.notificationReportError, object: nil)

        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "Fennec"
        telemetryConfig.userDefaultsSuiteName = AppInfo.sharedContainerIdentifier
        telemetryConfig.dataDirectory = .cachesDirectory
        telemetryConfig.updateChannel = AppConstants.BuildChannel.rawValue
        let sendUsageData = profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true
        telemetryConfig.isCollectionEnabled = sendUsageData
        telemetryConfig.isUploadEnabled = sendUsageData

        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.blockPopups", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.saveLogins", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.showClipboardBar", withDefaultValue: false)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.settings.closePrivateTabs", withDefaultValue: false)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.ASPocketStoriesVisible", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.ASBookmarkHighlightsVisible", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.ASRecentHighlightsVisible", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.prefkey.trackingprotection.normalbrowsing", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.prefkey.trackingprotection.privatebrowsing", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.prefkey.trackingprotection.strength", withDefaultValue: "basic")
        telemetryConfig.measureUserDefaultsSetting(forKey: ThemeManagerPrefs.systemThemeIsOn.rawValue, withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: ThemeManagerPrefs.automaticSwitchIsOn.rawValue, withDefaultValue: false)
        telemetryConfig.measureUserDefaultsSetting(forKey: ThemeManagerPrefs.automaticSliderValue.rawValue, withDefaultValue: 0)
        telemetryConfig.measureUserDefaultsSetting(forKey: ThemeManagerPrefs.themeName.rawValue, withDefaultValue: "normal")
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.show-translation", withDefaultValue: true)

        let prefs = profile.prefs
        Telemetry.default.beforeSerializePing(pingType: CorePingBuilder.PingType) { (inputDict) -> [String: Any?] in
            var outputDict = inputDict // make a mutable copy

            var settings: [String: Any?] = inputDict["settings"] as? [String: Any?] ?? [:]

            if let newTabChoice = prefs.stringForKey(NewTabAccessors.HomePrefKey) {
                outputDict["defaultNewTabExperience"] = newTabChoice as AnyObject?
            }
            if let chosenEmailClient = prefs.stringForKey(PrefsKeys.KeyMailToOption) {
                outputDict["defaultMailClient"] = chosenEmailClient as AnyObject?
            }

            // Report this flag as a `1` or `0` integer to allow it
            // to be counted easily when reporting. Then, clear the
            // flag to avoid it getting reported multiple times.
            settings["crashedLastLaunch"] = self.crashedLastLaunch ? 1 : 0
            self.crashedLastLaunch = false

            outputDict["settings"] = settings
            
            let delegate = UIApplication.shared.delegate as? AppDelegate

            outputDict["openTabCount"] = delegate?.tabManager.count ?? 0

            var userInterfaceStyle = "unknown" // unknown implies that device is on pre-iOS 13
            if #available(iOS 13.0, *) {
                userInterfaceStyle = UITraitCollection.current.userInterfaceStyle == .dark ? "dark" : "light"
            }
            outputDict["systemTheme"] = userInterfaceStyle

            return outputDict
        }

        Telemetry.default.beforeSerializePing(pingType: MobileEventPingBuilder.PingType) { (inputDict) -> [String: Any?] in
            var outputDict = inputDict

            var settings: [String: String?] = inputDict["settings"] as? [String: String?] ?? [:]

            let searchEngines = SearchEngines(prefs: profile.prefs, files: profile.files)
            settings["defaultSearchEngine"] = searchEngines.defaultEngine.engineID ?? "custom"

            if let windowBounds = UIApplication.shared.keyWindow?.bounds {
                settings["windowWidth"] = String(describing: windowBounds.width)
                settings["windowHeight"] = String(describing: windowBounds.height)
            }

            outputDict["settings"] = settings

            // App Extension telemetry requires reading events stored in prefs, then clearing them from prefs.
            if let extensionEvents = profile.prefs.arrayForKey(PrefsKeys.AppExtensionTelemetryEventArray) as? [[String: String]],
                var pingEvents = outputDict["events"] as? [[Any?]] {
                profile.prefs.removeObjectForKey(PrefsKeys.AppExtensionTelemetryEventArray)

                extensionEvents.forEach { extensionEvent in
                    let category = UnifiedTelemetry.EventCategory.appExtensionAction.rawValue
                    let newEvent = TelemetryEvent(category: category, method: extensionEvent["method"] ?? "", object: extensionEvent["object"] ?? "")
                    pingEvents.append(newEvent.toArray())
                }
                outputDict["events"] = pingEvents
            }

            return outputDict
        }

       Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
       Telemetry.default.add(pingBuilderType: MobileEventPingBuilder.self)
    }

    @objc func uploadError(notification: NSNotification) {
        guard !DeviceInfo.isSimulator(), let error = notification.userInfo?["error"] as? NSError else { return }
        Sentry.shared.send(message: "Upload Error", tag: SentryTag.unifiedTelemetry, severity: .info, description: error.debugDescription)
    }
}

// Enums for Event telemetry.
extension UnifiedTelemetry {
    public enum EventCategory: String {
        case action = "action"
        case appExtensionAction = "app-extension-action"
        case prompt = "prompt"
        case enrollment = "enrollment"
        case firefoxAccount = "firefox_account"
    }

    public enum EventMethod: String {
        case add = "add"
        case background = "background"
        case cancel = "cancel"
        case change = "change"
        case close = "close"
        case delete = "delete"
        case deleteAll = "deleteAll"
        case drag = "drag"
        case drop = "drop"
        case foreground = "foreground"
        case open = "open"
        case press = "press"
        case scan = "scan"
        case share = "share"
        case tap = "tap"
        case translate = "translate"
        case view = "view"
        case applicationOpenUrl = "application-open-url"
        case emailLogin = "email"
        case qrPairing = "pairing"
        case settings = "settings"
    }

    public enum EventObject: String {
        case app = "app"
        case bookmark = "bookmark"
        case bookmarksPanel = "bookmarks-panel"
        case download = "download"
        case downloadLinkButton = "download-link-button"
        case downloadNowButton = "download-now-button"
        case downloadsPanel = "downloads-panel"
        case keyCommand = "key-command"
        case locationBar = "location-bar"
        case qrCodeText = "qr-code-text"
        case qrCodeURL = "qr-code-url"
        case readerModeCloseButton = "reader-mode-close-button"
        case readerModeOpenButton = "reader-mode-open-button"
        case readingListItem = "reading-list-item"
        case setting = "setting"
        case tab = "tab"
        case trackingProtectionStatistics = "tracking-protection-statistics"
        case trackingProtectionWhitelist = "tracking-protection-whitelist"
        case trackingProtectionMenu = "tracking-protection-menu"
        case url = "url"
        case searchText = "searchText"
        case whatsNew = "whats-new"
        case dismissUpdateCoverSheetAndStartBrowsing = "dismissed-update-cover_sheet_and_start_browsing"
        case dismissedUpdateCoverSheet = "dismissed-update-cover-sheet"
        case dismissedETPCoverSheet = "dismissed-etp-sheet"
        case dismissETPCoverSheetAndStartBrowsing = "dismissed-etp-cover-sheet-and-start-browsing"
        case dismissETPCoverSheetAndGoToSettings = "dismissed-update-cover-sheet-and-go-to-settings"
        case dismissedOnboarding = "dismissed-onboarding"
        case dismissedOnboardingEmailLogin = "dismissed-onboarding-email-login"
        case dismissedOnboardingSignUp = "dismissed-onboarding-sign-up"
        case privateBrowsingButton = "private-browsing-button"
        case removeUnVerifiedAccountButton = "remove-unverified-account-button"
        case tabSearch = "tab-search"
        case tabToolbar = "tab-toolbar"
        case experimentEnrollment = "experiment-enrollment"
        case chinaServerSwitch = "china-server-switch"
        case accountConnected = "connected"
        case accountDisconnected = "disconnected"
        case appMenu = "app_menu"
        case settings = "settings"
        case onboarding = "onboarding"
    }

    public enum EventValue: String {
        case activityStream = "activity-stream"
        case appMenu = "app-menu"
        case awesomebarResults = "awesomebar-results"
        case bookmarksPanel = "bookmarks-panel"
        case browser = "browser"
        case contextMenu = "context-menu"
        case downloadCompleteToast = "download-complete-toast"
        case downloadsPanel = "downloads-panel"
        case homePanel = "home-panel"
        case homePanelTabButton = "home-panel-tab-button"
        case markAsRead = "mark-as-read"
        case markAsUnread = "mark-as-unread"
        case pageActionMenu = "page-action-menu"
        case readerModeToolbar = "reader-mode-toolbar"
        case readingListPanel = "reading-list-panel"
        case shareExtension = "share-extension"
        case shareMenu = "share-menu"
        case tabTray = "tab-tray"
        case topTabs = "top-tabs"
        case systemThemeSwitch = "system-theme-switch"
        case themeModeManually = "theme-manually"
        case themeModeAutomatically = "theme-automatically"
        case themeLight = "theme-light"
        case themeDark = "theme-dark"
        case privateTab = "private-tab"
        case normalTab = "normal-tab"
        case tabView = "tab-view"
    }

    public static func recordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: EventValue, extras: [String: Any]? = nil) {
        Telemetry.default.recordEvent(category: category.rawValue, method: method.rawValue, object: object.rawValue, value: value.rawValue, extras: extras)
    }

    public static func recordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: String? = nil, extras: [String: Any]? = nil) {
        Telemetry.default.recordEvent(category: category.rawValue, method: method.rawValue, object: object.rawValue, value: value, extras: extras)
    }
}
