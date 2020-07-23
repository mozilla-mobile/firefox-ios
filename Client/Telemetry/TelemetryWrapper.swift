/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Glean
import Shared
import Telemetry

class TelemetryWrapper {
    let legacyTelemetry = Telemetry.default
    let glean = Glean.shared

    // Boolean flag to temporarily remember if we crashed during the
    // last run of the app. We cannot simply use `Sentry.crashedLastLaunch`
    // because we want to clear this flag after we've already reported it
    // to avoid re-reporting the same crash multiple times.
    private var crashedLastLaunch: Bool

    private var profile: Profile?

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

        let telemetryConfig = legacyTelemetry.configuration
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
        legacyTelemetry.beforeSerializePing(pingType: CorePingBuilder.PingType) { (inputDict) -> [String: Any?] in
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

        legacyTelemetry.beforeSerializePing(pingType: MobileEventPingBuilder.PingType) { (inputDict) -> [String: Any?] in
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
                    let category = TelemetryWrapper.EventCategory.appExtensionAction.rawValue
                    let newEvent = TelemetryEvent(category: category, method: extensionEvent["method"] ?? "", object: extensionEvent["object"] ?? "")
                    pingEvents.append(newEvent.toArray())
                }
                outputDict["events"] = pingEvents
            }

            return outputDict
        }

        legacyTelemetry.add(pingBuilderType: CorePingBuilder.self)
        legacyTelemetry.add(pingBuilderType: MobileEventPingBuilder.self)

        // Initialize Glean
        initGlean(profile, sendUsageData: sendUsageData)
    }

    func initGlean(_ profile: Profile, sendUsageData: Bool) {
        // Get the legacy telemetry ID and record it in Glean for the deletion-request ping
        if let uuidString = UserDefaults.standard.string(forKey: "telemetry-key-prefix-clientId"), let uuid = UUID(uuidString: uuidString) {
            GleanMetrics.LegacyIds.clientId.set(uuid)
        }

        // Initialize Glean telemetry
        glean.initialize(uploadEnabled: sendUsageData, configuration: Configuration(channel: AppConstants.BuildChannel.rawValue))

        // Save the profile so we can record settings from it when the notification below fires.
        self.profile = profile

        // Register an observer to record settings and other metrics that are more appropriate to
        // record on going to background rather than during initialization.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordPreferenceMetrics(notification:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    // Function for recording metrics that are better recorded when going to background due
    // to the particular measurement, or availability of the information.
    @objc func recordPreferenceMetrics(notification: NSNotification) {
        guard let profile = self.profile else { assert(false); return; }

        // Record default search engine setting
        let searchEngines = SearchEngines(prefs: profile.prefs, files: profile.files)
        GleanMetrics.Search.defaultEngine.set(searchEngines.defaultEngine.engineID ?? "custom")

        // Record the open tab count
        let delegate = UIApplication.shared.delegate as? AppDelegate
        if let count = delegate?.tabManager.count {
            GleanMetrics.Tabs.cumulativeCount.add(Int32(count))
        }

        // Record other preference settings.
        // If the setting exists at the key location, use that value. Otherwise record the default
        // value for that preference to ensure it makes it into the metrics ping.
        let prefs = profile.prefs
        // Record New Tab setting
        if let newTabChoice = prefs.stringForKey(NewTabAccessors.HomePrefKey) {
            GleanMetrics.Preferences.newTabExperience.set(newTabChoice)
        } else {
            GleanMetrics.Preferences.newTabExperience.set(NewTabAccessors.Default.rawValue)
        }
        // Record chosen email client setting
        if let chosenEmailClient = prefs.stringForKey(PrefsKeys.KeyMailToOption) {
            GleanMetrics.Preferences.mailClient.set(chosenEmailClient)
        }
        // Block popups
        if let blockPopups = prefs.boolForKey(PrefsKeys.KeyBlockPopups) {
            GleanMetrics.Preferences.blockPopups.set(blockPopups)
        } else {
            GleanMetrics.Preferences.blockPopups.set(true)
        }
        // Save logins
        if let saveLogins = prefs.boolForKey(PrefsKeys.LoginsSaveEnabled) {
            GleanMetrics.Preferences.saveLogins.set(saveLogins)
        } else {
            GleanMetrics.Preferences.saveLogins.set(true)
        }
        // Show clipboard bar
        if let showClipboardBar = prefs.boolForKey("showClipboardBar") {
            GleanMetrics.Preferences.showClipboardBar.set(showClipboardBar)
        } else {
            GleanMetrics.Preferences.showClipboardBar.set(false)
        }
        // Close private tabs
        if let closePrivateTabs = prefs.boolForKey("settings.closePrivateTabs") {
            GleanMetrics.Preferences.closePrivateTabs.set(closePrivateTabs)
        } else {
            GleanMetrics.Preferences.closePrivateTabs.set(false)
        }
        // Pocket stories visible
        if let pocketStoriesVisible = prefs.boolForKey(PrefsKeys.ASPocketStoriesVisible) {
            GleanMetrics.ApplicationServices.pocketStoriesVisible.set(pocketStoriesVisible)
        } else {
            GleanMetrics.ApplicationServices.pocketStoriesVisible.set(true)
        }
        // Bookmark highlights visible
        if let bookmarkHighlightsVisible = prefs.boolForKey(PrefsKeys.ASBookmarkHighlightsVisible) {
            GleanMetrics.ApplicationServices.bookmarkHighlightsVisible.set(bookmarkHighlightsVisible)
        } else {
            GleanMetrics.ApplicationServices.bookmarkHighlightsVisible.set(true)
        }
        // Recent highlights visible
        if let recentHighlightsVisible = prefs.boolForKey(PrefsKeys.ASRecentHighlightsVisible) {
            GleanMetrics.ApplicationServices.recentHighlightsVisible.set(recentHighlightsVisible)
        } else {
            GleanMetrics.ApplicationServices.recentHighlightsVisible.set(true)
        }
        // Tracking protection - enabled
        if let tpEnabled = prefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) {
            GleanMetrics.TrackingProtection.enabled.set(tpEnabled)
        } else {
            GleanMetrics.TrackingProtection.enabled.set(true)
        }
        // Tracking protection - strength
        if let tpStrength = prefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey) {
            GleanMetrics.TrackingProtection.strength.set(tpStrength)
        } else {
            GleanMetrics.TrackingProtection.strength.set("basic")
        }
        // System theme enabled
        GleanMetrics.Theme.useSystemTheme.set(ThemeManager.instance.systemThemeIsOn)
        // Automatic brightness enabled
        GleanMetrics.Theme.automaticMode.set(ThemeManager.instance.automaticBrightnessIsOn)
        // Automatic brightness slider value
        // Note: we are recording this as a string since there is not currently a pure Numeric
        // Glean metric type.
        GleanMetrics.Theme.automaticSliderValue.set("\(ThemeManager.instance.automaticBrightnessValue)")
        // Theme name
        GleanMetrics.Theme.name.set(ThemeManager.instance.currentName.rawValue)
    }

    @objc func uploadError(notification: NSNotification) {
        guard !DeviceInfo.isSimulator(), let error = notification.userInfo?["error"] as? NSError else { return }
        Sentry.shared.send(message: "Upload Error", tag: SentryTag.unifiedTelemetry, severity: .info, description: error.debugDescription)
    }
}

// Enums for Event telemetry.
extension TelemetryWrapper {
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
        case trackingProtectionSafelist = "tracking-protection-safelist"
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
        case startSearchButton = "start-search-button"
        case addNewTabButton = "add-new-tab-button"
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

        gleanRecordEvent(category: category, method: method, object: object, value: value.rawValue, extras: extras);
    }

    public static func recordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: String? = nil, extras: [String: Any]? = nil) {
        Telemetry.default.recordEvent(category: category.rawValue, method: method.rawValue, object: object.rawValue, value: value, extras: extras)

        gleanRecordEvent(category: category, method: method, object: object, value: value ?? "", extras: extras);
    }

    static func gleanRecordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: String, extras: [String: Any]? = nil) {
        switch (category, method, object, value, extras) {
        // Bookmarks
        case (.action, .view, .bookmarksPanel, let value, _):
            GleanMetrics.Bookmarks.viewList[value].add()
        case (.action, .add, .bookmark, let value, _):
            GleanMetrics.Bookmarks.add[value].add()
        case (.action, .delete, .bookmark, let value, _):
            GleanMetrics.Bookmarks.delete[value].add()
        case (.action, .open, .bookmark, let value, _):
            GleanMetrics.Bookmarks.open[value].add()
        // Reader Mode
        case (.action, .tap, .readerModeOpenButton, _, _):
            GleanMetrics.ReaderMode.open.add()
        case (.action, .tap, .readerModeCloseButton, _, _):
            GleanMetrics.ReaderMode.close.add()
        // Reading List
        case (.action, .add, .readingListItem, let value, _):
            GleanMetrics.ReadingList.add[value].add()
        case (.action, .delete, .readingListItem, let value, _):
            GleanMetrics.ReadingList.delete[value].add()
        case (.action, .open, .readingListItem, _, _):
            GleanMetrics.ReadingList.open.add()
        case (.action, .tap, .readingListItem, EventValue.markAsRead.rawValue, _):
            GleanMetrics.ReadingList.markRead.add()
        case (.action, .tap, .readingListItem, EventValue.markAsUnread.rawValue, _):
            GleanMetrics.ReadingList.markUnread.add()
        // Preferences
        case (.action, .change, .setting, let preference, let extras):
            if let to = extras?["go"] as? String {
                GleanMetrics.Preferences.changed.record(
                extra: [GleanMetrics.Preferences.ChangedKeys.preference: preference,
                        GleanMetrics.Preferences.ChangedKeys.changedTo: to])
            } else {
                GleanMetrics.Preferences.changed.record(
                    extra: [GleanMetrics.Preferences.ChangedKeys.preference: preference,
                            GleanMetrics.Preferences.ChangedKeys.changedTo: "undefined"])
            }
        // QR Codes
        case (.action, .scan, .qrCodeText, _, _),
             (.action, .scan, .qrCodeURL, _, _):
            GleanMetrics.QrCode.scanned.add()
        // Tabs
        case (.action, .add, .tab, let value, _):
            GleanMetrics.Tabs.open[value].add()
        case (.action, .close, .tab, let value, _):
            GleanMetrics.Tabs.close[value].add()
        case (.action, .tap, .addNewTabButton, _, _):
            GleanMetrics.Tabs.newTabPressed.add()
        // Start Search Button
        case (.action, .tap, .startSearchButton, _, _):
            GleanMetrics.Search.startSearchPressed.add()
        default:
            let msg = "Uninstrumented metric recorded: \(category), \(method), \(object), \(value), \(String(describing: extras))"
            Sentry.shared.send(message: msg, severity: .debug)
        }
    }
}
