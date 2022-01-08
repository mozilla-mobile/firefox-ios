// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Glean
import Shared
import Telemetry
import Account
import Sync

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
        crashedLastLaunch = Sentry.shared.crashedLastLaunch

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

        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.saveLogins", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.showClipboardBar", withDefaultValue: false)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.settings.closePrivateTabs", withDefaultValue: false)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.ASPocketStoriesVisible", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.ASBookmarkHighlightsVisible", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.prefkey.trackingprotection.normalbrowsing", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.prefkey.trackingprotection.privatebrowsing", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.prefkey.trackingprotection.strength", withDefaultValue: "basic")
        telemetryConfig.measureUserDefaultsSetting(forKey: LegacyThemeManagerPrefs.systemThemeIsOn.rawValue, withDefaultValue: true)

        let prefs = profile.prefs
        legacyTelemetry.beforeSerializePing(pingType: CorePingBuilder.PingType) { (inputDict) -> [String: Any?] in
            var outputDict = inputDict // make a mutable copy

            var settings: [String: Any?] = inputDict["settings"] as? [String: Any?] ?? [:]

            if let newTabChoice = prefs.stringForKey(NewTabAccessors.HomePrefKey) {
                outputDict["defaultNewTabExperience"] = newTabChoice as AnyObject?
            }

            // Report this flag as a `1` or `0` integer to allow it
            // to be counted easily when reporting. Then, clear the
            // flag to avoid it getting reported multiple times.
            settings["crashedLastLaunch"] = self.crashedLastLaunch ? 1 : 0
            self.crashedLastLaunch = false

            outputDict["settings"] = settings

            let delegate = UIApplication.shared.delegate as? AppDelegate

            outputDict["openTabCount"] = delegate?.tabManager.count ?? 0

            outputDict["systemTheme"] = UITraitCollection.current.userInterfaceStyle == .dark ? "dark" : "light"

            return outputDict
        }

        legacyTelemetry.beforeSerializePing(pingType: MobileEventPingBuilder.PingType) { (inputDict) -> [String: Any?] in
            var outputDict = inputDict

            var settings: [String: String?] = inputDict["settings"] as? [String: String?] ?? [:]

            let searchEngines = SearchEngines(prefs: profile.prefs, files: profile.files)
            settings["defaultSearchEngine"] = searchEngines.defaultEngine.engineID ?? "custom"

            if let windowBounds = UIWindow.keyWindow?.bounds {
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

        setSyncDeviceId()

        // Register an observer to record settings and other metrics that are more appropriate to
        // record on going to background rather than during initialization.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordPreferenceMetrics(notification:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    // Sets hashed fxa sync device id for glean deletion ping
    func setSyncDeviceId() {
        guard let prefs = profile?.prefs else { return }
        // Grab our token so we can use the hashed_fxa_uid and clientGUID from our scratchpad for deletion-request ping
        RustFirefoxAccounts.shared.syncAuthState.token(Date.now(), canBeExpired: true) >>== { (token, kSync) in
            let scratchpadPrefs = prefs.branch("sync.scratchpad")
            guard let scratchpad = Scratchpad.restoreFromPrefs(scratchpadPrefs, syncKeyBundle: KeyBundle.fromKSync(kSync)) else { return }

            let deviceId = (scratchpad.clientGUID + token.hashedFxAUID).sha256.hexEncodedString
            GleanMetrics.Deletion.syncDeviceId.set(deviceId)
        }
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
        // Record `Home` setting, where Firefox Home is "Home", a custom URL is "other" and blank is "Blank".
        let homePageSetting = NewTabAccessors.getHomePage(prefs)
        switch homePageSetting {
        case .topSites:
            let firefoxHome = "Home"
            GleanMetrics.Preferences.homePageSetting.set(firefoxHome)
        case .homePage:
            let customUrl = "other"
            GleanMetrics.Preferences.homePageSetting.set(customUrl)
        default:
            GleanMetrics.Preferences.homePageSetting.set(homePageSetting.rawValue)
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
        GleanMetrics.Theme.useSystemTheme.set(LegacyThemeManager.instance.systemThemeIsOn)
        // Installed Mozilla applications
        GleanMetrics.InstalledMozillaProducts.focus.set(UIApplication.shared.canOpenURL(URL(string: "firefox-focus://")!))
        GleanMetrics.InstalledMozillaProducts.klar.set(UIApplication.shared.canOpenURL(URL(string: "firefox-klar://")!))
        // Device Authentication
        GleanMetrics.Device.authentication.set(AppAuthenticator.canAuthenticateDeviceOwner())
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
        case closeAll = "close-all"
        case delete = "delete"
        case deleteAll = "deleteAll"
        case drag = "drag"
        case drop = "drop"
        case foreground = "foreground"
        case navigate = "navigate"
        case open = "open"
        case press = "press"
        case pull = "pull"
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
        case tabTray = "tab-tray"
        case groupedTab = "grouped-tab"
        case groupedTabPerformSearch = "grouped-tab-perform-search"
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
        case privateBrowsingButton = "private-browsing-button"
        case startSearchButton = "start-search-button"
        case addNewTabButton = "add-new-tab-button"
        case removeUnVerifiedAccountButton = "remove-unverified-account-button"
        case tabSearch = "tab-search"
        case tabToolbar = "tab-toolbar"
        case chinaServerSwitch = "china-server-switch"
        case accountConnected = "connected"
        case accountDisconnected = "disconnected"
        case appMenu = "app_menu"
        case settings = "settings"
        case settingsMenuSetAsDefaultBrowser = "set-as-default-browser-menu-go-to-settings"
        case onboarding = "onboarding"
        case welcomeScreenView = "welcome-screen-view"
        case welcomeScreenClose = "welcome-screen-close"
        case welcomeScreenSignIn = "welcome-screen-sign-in"
        case welcomeScreenSignUp = "welcome-screen-sign-up"
        case welcomeScreenNext = "welcome-screen-next"
        case syncScreenView = "sync-screen-view"
        case syncScreenSignUp = "sync-screen-sign-up"
        case syncScreenStartBrowse = "sync-screen-start-browse"
        case dismissedOnboarding = "dismissed-onboarding"
        case dismissedOnboardingSignUp = "dismissed-onboarding-sign-up"
        case dismissedOnboardingEmailLogin = "dismissed-onboarding-email-login"
        case dismissDefaultBrowserCard = "default-browser-card"
        case goToSettingsDefaultBrowserCard = "default-browser-card-go-to-settings"
        case dismissDefaultBrowserOnboarding = "default-browser-onboarding"
        case goToSettingsDefaultBrowserOnboarding = "default-browser-onboarding-go-to-settings"
        case asDefaultBrowser = "as-default-browser"
        case mediumTabsOpenUrl = "medium-tabs-widget-url"
        case largeTabsOpenUrl = "large-tabs-widget-url"
        case smallQuickActionSearch = "small-quick-action-search"
        case mediumQuickActionSearch = "medium-quick-action-search"
        case mediumQuickActionPrivateSearch = "medium-quick-action-private-search"
        case mediumQuickActionCopiedLink = "medium-quick-action-copied-link"
        case mediumQuickActionClosePrivate = "medium-quick-action-close-private"
        case mediumTopSitesWidget = "medium-top-sites-widget"
        case topSiteTile = "top-site-tile"
        case pocketStory = "pocket-story"
        case pocketSectionImpression = "pocket-section-impression"
        case library = "library"
        case home = "home-page"
        case blockImagesEnabled = "block-images-enabled"
        case blockImagesDisabled = "block-images-disabled"
        case nightModeEnabled = "night-mode-enabled"
        case nightModeDisabled = "night-mode-disabled"
        case logins = "logins-and-passwords"
        case signIntoSync = "sign-into-sync"
        case syncTab = "sync-tab"
        case syncSignIn = "sync-sign-in"
        case syncCreateAccount = "sync-create-account"
        case libraryPanel = "library-panel"
        case sharePageWith = "share-page-with"
        case sendToDevice = "send-to-device"
        case copyAddress = "copy-address"
        case reportSiteIssue = "report-site-issue"
        case findInPage = "find-in-page"
        case requestDesktopSite = "request-desktop-site"
        case requestMobileSite = "request-mobile-site"
        case pinToTopSites = "pin-to-top-sites"
        case removePinnedSite = "remove-pinned-site"
        case firefoxHomepage = "firefox-homepage"
        case jumpBackInImpressions = "jump-back-in-impressions"
        case historyImpressions = "history-highlights-impressions"
        case recentlySavedBookmarkImpressions = "recently-saved-bookmark-impressions"
        case recentlySavedReadingItemImpressions = "recently-saved-reading-items-impressions"
        case inactiveTabTray = "inactiveTabTray"
        case reload = "reload"
    }

    public enum EventValue: String {
        case activityStream = "activity-stream"
        case appMenu = "app-menu"
        case awesomebarResults = "awesomebar-results"
        case browser = "browser"
        case contextMenu = "context-menu"
        case downloadCompleteToast = "download-complete-toast"
        case homePanel = "home-panel"
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
        case bookmarksPanel = "bookmarks-panel"
        case historyPanel = "history-panel"
        case readingPanel = "reading-panel"
        case downloadsPanel = "downloads-panel"
        case syncPanel = "sync-panel"
        case yourLibrarySection = "your-library-section"
        case jumpBackInSectionShowAll = "jump-back-in-section-show-all"
        case jumpBackInSectionTabOpened = "jump-back-in-section-tab-opened"
        case jumpBackInSectionGroupOpened = "jump-back-in-section-group-opened"
        case recentlySavedSectionShowAll = "recently-saved-section-show-all"
        case recentlySavedBookmarkItemAction = "recently-saved-bookmark-item-action"
        case recentlySavedBookmarkItemView = "recently-saved-bookmark-item-view"
        case recentlySavedReadingListView = "recently-saved-reading-list-view"
        case recentlySavedReadingListAction = "recently-saved-reading-list-action"
        case historyHighlightsShowAll = "history-highlights-show-all"
        case historyHighlightsItemOpened = "history-highlights-item-opened"
        case customizeHomepageButton = "customize-homepage-button"
        case cycleWallpaperButton = "cycle-wallpaper-button"
        case fxHomepageOrigin = "firefox-homepage-origin"
        case fxHomepageOriginZeroSearch = "zero-search"
        case fxHomepageOriginOther = "origin-other"
        case addBookmarkToast = "add-bookmark-toast"
        case openHomeFromAwesomebar = "open-home-from-awesomebar"
        case openHomeFromPhotonMenuButton = "open-home-from-photon-menu-button"
        case openInactiveTab = "openInactiveTab"
        case inactiveTabExpand = "inactivetab-expand"
        case inactiveTabCollapse = "inactivetab-collapse"
        case openRecentlyClosedList = "openRecentlyClosedList"
        case openRecentlyClosedTab = "openRecentlyClosedTab"
        case tabGroupWithExtras = "tabGroupWithExtras"
        case closeGroupedTab = "recordCloseGroupedTab"
    }

    public enum EventExtraKey: String, CustomStringConvertible {
        case topSitePosition = "tilePosition"
        case topSiteTileType = "tileType"
        case pocketTilePosition = "pocketTilePosition"
        case fxHomepageOrigin = "fxHomepageOrigin"

        case preference = "pref"
        case preferenceChanged = "to"

        // Grouped Tab
        case groupsWithTwoTabsOnly = "groupsWithTwoTabsOnly"
        case groupsWithTwoMoreTab = "groupsWithTwoMoreTab"
        case totalNumberOfGroups = "totalNumOfGroups"
        case averageTabsInAllGroups = "averageTabsInAllGroups"
        case totalTabsInAllGroups = "totalTabsInAllGroups"
        var description: String {
            return self.rawValue
        }
    }

    public static func recordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: EventValue? = nil, extras: [String: Any]? = nil) {
        Telemetry.default.recordEvent(category: category.rawValue, method: method.rawValue, object: object.rawValue, value: value?.rawValue ?? "", extras: extras)

        gleanRecordEvent(category: category, method: method, object: object, value: value, extras: extras);
    }

    static func gleanRecordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: EventValue? = nil, extras: [String: Any]? = nil) {
        let value = value?.rawValue ?? ""
        switch (category, method, object, value, extras) {
        // Bookmarks
        case (.action, .view, .bookmarksPanel, let from, _):
            GleanMetrics.Bookmarks.viewList[from].add()
        case (.action, .add, .bookmark, let from, _):
            GleanMetrics.Bookmarks.add[from].add()
        case (.action, .delete, .bookmark, let from, _):
            GleanMetrics.Bookmarks.delete[from].add()
        case (.action, .open, .bookmark, let from, _):
            GleanMetrics.Bookmarks.open[from].add()
        case (.action, .change, .bookmark, let from, _):
            GleanMetrics.Bookmarks.edit[from].add()
        // Reader Mode
        case (.action, .tap, .readerModeOpenButton, _, _):
            GleanMetrics.ReaderMode.open.add()
        case (.action, .tap, .readerModeCloseButton, _, _):
            GleanMetrics.ReaderMode.close.add()
        // Reading List
        case (.action, .add, .readingListItem, let from, _):
            GleanMetrics.ReadingList.add[from].add()
        case (.action, .delete, .readingListItem, let from, _):
            GleanMetrics.ReadingList.delete[from].add()
        case (.action, .open, .readingListItem, _, _):
            GleanMetrics.ReadingList.open.add()
        // Top Site
        case (.action, .tap, .topSiteTile, _, let extras):
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.TopSite.pressedTileOrigin[homePageOrigin].add()
            }

            if let position = extras?[EventExtraKey.topSitePosition.rawValue] as? String, let tileType = extras?[EventExtraKey.topSiteTileType.rawValue] as? String {
                GleanMetrics.TopSite.tilePressed.record(GleanMetrics.TopSite.TilePressedExtra(position: position, tileType: tileType))
            } else {
                let msg = "Uninstrumented pref metric: \(category), \(method), \(object), \(value), \(String(describing: extras))"
                Sentry.shared.send(message: msg, severity: .debug)
            }
        // Preferences
        case (.action, .change, .setting, _, let extras):
            if let preference = extras?[EventExtraKey.preference.rawValue] as? String, let to = ((extras?[EventExtraKey.preferenceChanged.rawValue]) ?? "undefined") as? String {
                GleanMetrics.Preferences.changed.record(GleanMetrics.Preferences.ChangedExtra(changedTo: to, preference: preference))
            } else {
                let msg = "Uninstrumented pref metric: \(category), \(method), \(object), \(value), \(String(describing: extras))"
                Sentry.shared.send(message: msg, severity: .debug)
            }
        // QR Codes
        case (.action, .scan, .qrCodeText, _, _),
             (.action, .scan, .qrCodeURL, _, _):
            GleanMetrics.QrCode.scanned.add()
        // Tabs
        case (.action, .add, .tab, let privateOrNormal, _):
            GleanMetrics.Tabs.open[privateOrNormal].add()
        case (.action, .close, .tab, let privateOrNormal, _):
            GleanMetrics.Tabs.close[privateOrNormal].add()
        case (.action, .closeAll, .tab, let privateOrNormal, _):
            GleanMetrics.Tabs.closeAll[privateOrNormal].add()
        case (.action, .tap, .addNewTabButton, _, _):
            GleanMetrics.Tabs.newTabPressed.add()
        case (.action, .tap, .tab, _, _):
            GleanMetrics.Tabs.clickTab.record()
        case (.action, .open, .tabTray, _, _):
            GleanMetrics.Tabs.openTabTray.record()
        case (.action, .close, .tabTray, _, _):
            GleanMetrics.Tabs.closeTabTray.record()
        case(.action, .pull, .reload, _, _):
            GleanMetrics.Tabs.pullToRefresh.add()
        case(.action, .navigate, .tab, _, _):
            GleanMetrics.Tabs.normalAndPrivateUriCount.add()
        // Settings Menu
        case (.action, .open, .settingsMenuSetAsDefaultBrowser, _, _):
            GleanMetrics.SettingsMenu.setAsDefaultBrowserPressed.add()
        // Start Search Button
        case (.action, .tap, .startSearchButton, _, _):
            GleanMetrics.Search.startSearchPressed.add()
        // Default Browser
        case (.action, .tap, .dismissDefaultBrowserCard, _, _):
            GleanMetrics.DefaultBrowserCard.dismissPressed.add()
        case (.action, .tap, .goToSettingsDefaultBrowserCard, _, _):
            GleanMetrics.DefaultBrowserCard.goToSettingsPressed.add()
        case (.action, .open, .asDefaultBrowser, _, _):
            GleanMetrics.App.openedAsDefaultBrowser.add()
        case (.action, .tap, .dismissDefaultBrowserOnboarding, _, _):
            GleanMetrics.DefaultBrowserOnboarding.dismissPressed.add()
        case (.action, .tap, .goToSettingsDefaultBrowserOnboarding, _, _):
            GleanMetrics.DefaultBrowserOnboarding.goToSettingsPressed.add()
        // Onboarding
        case (.action, .press, .dismissedOnboarding, _, let extras):
            if let slideNum = extras?["slide-num"] as? Int32 {
                GleanMetrics.Onboarding.finish.record(GleanMetrics.Onboarding.FinishExtra(slideNum: slideNum))
            } else {
                let msg = "Missing slide-num in onboarding metric: \(category), \(method), \(object), \(value), \(String(describing: extras))"
                Sentry.shared.send(message: msg, severity: .debug)
            }
        case (.action, .view, .welcomeScreenView, _, _):
            GleanMetrics.Onboarding.welcomeScreen.add()
        case(.action, .press, .welcomeScreenSignUp, _, _):
            GleanMetrics.Onboarding.welcomeScreenSignUp.add()
        case (.action, .press, .welcomeScreenSignIn, _, _):
            GleanMetrics.Onboarding.welcomeScreenSignIn.add()
        case(.action, .press, .welcomeScreenNext, _, _):
            GleanMetrics.Onboarding.welcomeScreenNext.add()
        case(.action, .press, .welcomeScreenClose, _, _):
            GleanMetrics.Onboarding.welcomeScreenClose.add()
        case(.action, .view, .syncScreenView, _, _):
            GleanMetrics.Onboarding.syncScreen.add()
        case(.action, .press, .syncScreenSignUp, _, _):
            GleanMetrics.Onboarding.syncScreenSignUp.add()
        case(.action, .press, .syncScreenStartBrowse, _, _):
            GleanMetrics.Onboarding.syncScreenBrowse.add()
        // Widget
        case (.action, .open, .mediumTabsOpenUrl, _, _):
            GleanMetrics.Widget.mTabsOpenUrl.add()
        case (.action, .open, .largeTabsOpenUrl, _, _):
            GleanMetrics.Widget.lTabsOpenUrl.add()
        case (.action, .open, .smallQuickActionSearch, _, _):
            GleanMetrics.Widget.sQuickActionSearch.add()
        case (.action, .open, .mediumQuickActionSearch, _, _):
            GleanMetrics.Widget.mQuickActionSearch.add()
        case (.action, .open, .mediumQuickActionPrivateSearch, _, _):
            GleanMetrics.Widget.mQuickActionPrivateSearch.add()
        case (.action, .open, .mediumQuickActionCopiedLink, _, _):
            GleanMetrics.Widget.mQuickActionCopiedLink.add()
        case (.action, .open, .mediumQuickActionClosePrivate, _, _):
            GleanMetrics.Widget.mQuickActionClosePrivate.add()
        case (.action, .open, .mediumTopSitesWidget, _, _):
            GleanMetrics.Widget.mTopSitesWidget.add()

        // Pocket
        case (.action, .tap, .pocketStory, _, let extras):
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.Pocket.openStoryOrigin[homePageOrigin].add()
            }

            if let position = extras?[EventExtraKey.pocketTilePosition.rawValue] as? String {
                GleanMetrics.Pocket.openStoryPosition["position-"+position].add()
            } else {
                let msg = "Uninstrumented pref metric: \(category), \(method), \(object), \(value), \(String(describing: extras))"
                Sentry.shared.send(message: msg, severity: .debug)
            }
        case (.action, .view, .pocketSectionImpression, _, _):
            GleanMetrics.Pocket.sectionImpressions.add()

        // Library
        case (.action, .tap, .libraryPanel, let type, _):
            GleanMetrics.Library.panelPressed[type].add()
        // Sync
        case (.action, .open, .syncTab, _, _):
            GleanMetrics.Sync.openTab.add()
        case (.action, .tap, .syncSignIn, _, _):
            GleanMetrics.Sync.signInSyncPressed.add()
        case (.action, .tap, .syncCreateAccount, _, _):
            GleanMetrics.Sync.createAccountPressed.add()
        // App menu
        case (.action, .tap, .logins, _, _):
            GleanMetrics.AppMenu.logins.add()
        case (.action, .tap, .signIntoSync, _, _):
            GleanMetrics.AppMenu.signIntoSync.add()
        case (.action, .tap, .home, _, _):
            GleanMetrics.AppMenu.home.add()
        case (.action, .tap, .library, _, _):
            GleanMetrics.AppMenu.library.add()
        case (.action, .tap, .blockImagesEnabled, _, _):
            GleanMetrics.AppMenu.blockImagesEnabled.add()
        case (.action, .tap, .blockImagesDisabled, _, _):
            GleanMetrics.AppMenu.blockImagesDisabled.add()
        case (.action, .tap, .nightModeEnabled, _, _):
            GleanMetrics.AppMenu.nightModeEnabled.add()
        case (.action, .tap, .nightModeDisabled, _, _):
            GleanMetrics.AppMenu.nightModeDisabled.add()
        case (.action, .tap, .whatsNew, _, _):
            GleanMetrics.AppMenu.whatsNew.add()
        case (.action, .open, .settings, _, _):
            GleanMetrics.AppMenu.settings.add()

        // Page Menu
        case (.action, .tap, .sharePageWith, _, _):
            GleanMetrics.PageActionMenu.sharePageWith.add()
        case (.action, .tap, .sendToDevice, _, _):
            GleanMetrics.PageActionMenu.sendToDevice.add()
        case (.action, .tap, .copyAddress, _, _):
            GleanMetrics.PageActionMenu.copyAddress.add()
        case (.action, .tap, .reportSiteIssue, _, _):
            GleanMetrics.PageActionMenu.reportSiteIssue.add()
        case (.action, .tap, .findInPage, _, _):
            GleanMetrics.PageActionMenu.findInPage.add()
        case (.action, .tap, .pinToTopSites, _, _):
            GleanMetrics.PageActionMenu.pinToTopSites.add()
        case (.action, .tap, .removePinnedSite, _, _):
            GleanMetrics.PageActionMenu.removePinnedSite.add()
        case (.action, .tap, .requestDesktopSite, _, _):
            GleanMetrics.PageActionMenu.requestDesktopSite.add()
        case (.action, .tap, .requestMobileSite, _, _):
            GleanMetrics.PageActionMenu.requestMobileSite.add()

        // Inactive Tab Tray
        case (.action, .tap, .inactiveTabTray, EventValue.openInactiveTab.rawValue, _):
            GleanMetrics.InactiveTabsTray.openInactiveTab.add()
        case (.action, .tap, .inactiveTabTray, EventValue.inactiveTabExpand.rawValue, _):
            GleanMetrics.InactiveTabsTray.toggleInactiveTabTray[EventValue.inactiveTabExpand.rawValue].add()
        case (.action, .tap, .inactiveTabTray, EventValue.inactiveTabCollapse.rawValue, _):
            GleanMetrics.InactiveTabsTray.toggleInactiveTabTray[EventValue.inactiveTabCollapse.rawValue].add()
        case (.action, .tap, .inactiveTabTray, EventValue.openRecentlyClosedList.rawValue, _):
            GleanMetrics.InactiveTabsTray.openRecentlyClosedList.add()
        case (.action, .tap, .inactiveTabTray, EventValue.openRecentlyClosedTab.rawValue, _):
            GleanMetrics.InactiveTabsTray.openRecentlyClosedTab.add()

        // Tab Groups
        case (.action, .view, .tabTray, EventValue.tabGroupWithExtras.rawValue, let extras):
           let groupedTabExtras = GleanMetrics.Tabs.GroupedTabExtra.init(averageTabsInAllGroups: extras?["\(EventExtraKey.averageTabsInAllGroups)"] as? Int32, groupsTwoTabsOnly: extras?["\(EventExtraKey.groupsWithTwoTabsOnly)"] as? Int32, groupsWithMoreThanTwoTab: extras?["\(EventExtraKey.groupsWithTwoMoreTab)"] as? Int32, totalNumOfGroups: extras?["\(EventExtraKey.totalNumberOfGroups)"] as? Int32, totalTabsInAllGroups: extras?["\(EventExtraKey.totalTabsInAllGroups)"] as? Int32)
            GleanMetrics.Tabs.groupedTab.record(groupedTabExtras)
        case (.action, .tap, .groupedTab, EventValue.closeGroupedTab.rawValue, _):
            GleanMetrics.InactiveTabsTray.openRecentlyClosedTab.add()
        case (.action, .tap, .groupedTabPerformSearch, _, _):
            GleanMetrics.Tabs.groupedTabSearch.add()
            
        // Firefox Homepage
        case (.action, .view, .firefoxHomepage, EventValue.fxHomepageOrigin.rawValue, let extras):
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.firefoxHomepageOrigin[homePageOrigin].add()
            }
        case (.action, .tap, .firefoxHomepage, EventValue.yourLibrarySection.rawValue, let extras):
            if let panel = extras?[EventObject.libraryPanel.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.yourLibrary[panel].add()
            }
        case (.action, .open, .firefoxHomepage, EventValue.openHomeFromAwesomebar.rawValue, _):
            GleanMetrics.FirefoxHomePage.openFromAwesomebar.add()
        case (.action, .open, .firefoxHomepage, EventValue.openHomeFromPhotonMenuButton.rawValue, _):
            GleanMetrics.FirefoxHomePage.openFromMenuHomeButton.add()

        case (.action, .view, .firefoxHomepage, EventValue.recentlySavedBookmarkItemView.rawValue, let extras):
            if let bookmarksCount = extras?[EventObject.recentlySavedBookmarkImpressions.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.recentlySavedBookmarkView.record(GleanMetrics.FirefoxHomePage.RecentlySavedBookmarkViewExtra(bookmarkCount: bookmarksCount))
            }
        case (.action, .view, .firefoxHomepage, EventValue.recentlySavedReadingListView.rawValue, let extras):
            if let readingListItemsCount = extras?[EventObject.recentlySavedReadingItemImpressions.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.readingListView.record(GleanMetrics.FirefoxHomePage.ReadingListViewExtra(readingListCount: readingListItemsCount))
            }
        case (.action, .tap, .firefoxHomepage, EventValue.recentlySavedSectionShowAll.rawValue, let extras):
            GleanMetrics.FirefoxHomePage.recentlySavedShowAll.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.recentlySavedShowAllOrigin[homePageOrigin].add()
            }
        case (.action, .tap, .firefoxHomepage, EventValue.recentlySavedBookmarkItemAction.rawValue, let extras):
            GleanMetrics.FirefoxHomePage.recentlySavedBookmarkItem.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.recentlySavedBookmarkOrigin[homePageOrigin].add()
            }
        case (.action, .tap, .firefoxHomepage, EventValue.recentlySavedReadingListAction.rawValue, let extras):
            GleanMetrics.FirefoxHomePage.recentlySavedReadingItem.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.recentlySavedReadOrigin[homePageOrigin].add()
            }

        case (.action, .tap, .firefoxHomepage, EventValue.jumpBackInSectionShowAll.rawValue, let extras):
            GleanMetrics.FirefoxHomePage.jumpBackInShowAll.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.jumpBackInShowAllOrigin[homePageOrigin].add()
            }
        case (.action, .view, .jumpBackInImpressions, _, _):
            GleanMetrics.FirefoxHomePage.jumpBackInSectionView.add()
        case (.action, .tap, .firefoxHomepage, EventValue.jumpBackInSectionTabOpened.rawValue, let extras):
            GleanMetrics.FirefoxHomePage.jumpBackInTabOpened.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.jumpBackInTabOpenedOrigin[homePageOrigin].add()
            }
        case (.action, .tap, .firefoxHomepage, EventValue.jumpBackInSectionGroupOpened.rawValue, let extras):
            GleanMetrics.FirefoxHomePage.jumpBackInGroupOpened.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.jumpBackInGroupOpenOrigin[homePageOrigin].add()
            }

        case (.action, .tap, .firefoxHomepage, EventValue.customizeHomepageButton.rawValue, _):
            GleanMetrics.FirefoxHomePage.customizeHomepageButton.add()

        case (.action, .tap, .firefoxHomepage, EventValue.cycleWallpaperButton.rawValue, _):
            GleanMetrics.FirefoxHomePage.customizeHomepageButton.add()

        case (.action, .tap, .firefoxHomepage, EventValue.historyHighlightsShowAll.rawValue, _):
            GleanMetrics.FirefoxHomePage.customizeHomepageButton.add()
        case (.action, .tap, .firefoxHomepage, EventValue.historyHighlightsItemOpened.rawValue, _):
            GleanMetrics.FirefoxHomePage.customizeHomepageButton.add()
        case (.action, .view, .historyImpressions, _, _):
            GleanMetrics.FirefoxHomePage.customizeHomepageButton.add()

        default:
            let msg = "Uninstrumented metric recorded: \(category), \(method), \(object), \(value), \(String(describing: extras))"
            Sentry.shared.send(message: msg, severity: .debug)
        }
    }
}

// MARK: - Firefox Home Page
extension TelemetryWrapper {

    /// Bundle the extras dictionnary for the home page origin
    static func getOriginExtras(isZeroSearch: Bool) -> [String: String] {
        let origin = isZeroSearch ? TelemetryWrapper.EventValue.fxHomepageOriginZeroSearch : TelemetryWrapper.EventValue.fxHomepageOriginOther
        return [TelemetryWrapper.EventExtraKey.fxHomepageOrigin.rawValue: origin.rawValue]
    }
}
