// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Disabling `line_length` for this whole file because it is going to get refactored/replaced soon.
// swiftlint:disable line_length
import Common
import Glean
import Shared
import Storage

protocol TelemetryWrapperProtocol {
    func recordEvent(category: TelemetryWrapper.EventCategory,
                     method: TelemetryWrapper.EventMethod,
                     object: TelemetryWrapper.EventObject,
                     value: TelemetryWrapper.EventValue?,
                     extras: [String: Any]?)
}

extension TelemetryWrapperProtocol {
    func recordEvent(category: TelemetryWrapper.EventCategory,
                     method: TelemetryWrapper.EventMethod,
                     object: TelemetryWrapper.EventObject,
                     value: TelemetryWrapper.EventValue? = nil,
                     extras: [String: Any]? = nil) {
        recordEvent(category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
    }
}

enum SearchLocation: String {
    case actionBar = "actionbar"
    case listItem = "listitem"
    case suggestion = "suggestion"
    case quickSearch = "quicksearch"
}

class TelemetryWrapper: TelemetryWrapperProtocol, FeatureFlaggable {
    typealias ExtraKey = TelemetryWrapper.EventExtraKey

    static let shared = TelemetryWrapper()

    let glean = Glean.shared
    // Boolean flag to temporarily remember if we crashed during the
    // last run of the app. We cannot simply use `Sentry.crashedLastLaunch`
    // because we want to clear this flag after we've already reported it
    // to avoid re-reporting the same crash multiple times.
    private var crashedLastLaunch: Bool

    private var profile: Profile?
    private var logger: Logger
    private let gleanUsageReportingMetricsService: GleanUsageReportingMetricsService

    init(logger: Logger = DefaultLogger.shared,
         gleanUsageReportingMetricsService: GleanUsageReportingMetricsService = AppContainer.shared.resolve()) {
        crashedLastLaunch = logger.crashedLastLaunch
        self.logger = logger
        self.gleanUsageReportingMetricsService = gleanUsageReportingMetricsService
    }

    private func migratePathComponentInDocumentsDirectory(_ pathComponent: String, to destinationSearchPath: FileManager.SearchPathDirectory) {
        guard let oldPath = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false).appendingPathComponent(pathComponent).path,
              FileManager.default.fileExists(atPath: oldPath) else { return }

        guard let newPath = try? FileManager.default.url(
            for: destinationSearchPath,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true).appendingPathComponent(pathComponent).path
        else { return }

        do {
            try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
        } catch {}
    }

    func setup(profile: Profile) {
        migratePathComponentInDocumentsDirectory("MozTelemetry-Default-core", to: .cachesDirectory)
        migratePathComponentInDocumentsDirectory("MozTelemetry-Default-mobile-event", to: .cachesDirectory)
        migratePathComponentInDocumentsDirectory("eventArray-MozTelemetry-Default-mobile-event.json", to: .cachesDirectory)

        let sendUsageData = profile.prefs.boolForKey(AppConstants.prefSendUsageData) ?? true

        // Initialize Glean
        initGlean(profile, sendUsageData: sendUsageData)
    }

    func initGlean(_ profile: Profile, sendUsageData: Bool) {
        // Record default search engine setting to avoid sending a `null` value.
        // If there's no default search engine, (there's not, at this point), we will
        // send "unavailable" in order not to send `null`, but still differentiate
        // the event in the startup sequence.

        let defaultEngine = profile.searchEnginesManager.defaultEngine
        GleanMetrics.Search.defaultEngine.set(defaultEngine?.engineID ?? "unavailable")

        // Set the date that the app was last used as default browser
        if let timestamp = profile.prefs.timestampForKey(PrefsKeys.LastOpenedAsDefaultBrowser) {
            let date = Date.fromTimestamp(timestamp)
            GleanMetrics.App.lastOpenedAsDefaultBrowser.set(date)
        }

        // Get the legacy telemetry ID and record it in Glean for the deletion-request ping
        if let uuidString = UserDefaults.standard.string(forKey: "telemetry-key-prefix-clientId"),
           let uuid = UUID(uuidString: uuidString) {
            GleanMetrics.LegacyIds.clientId.set(uuid)
        }

        GleanMetrics.Pings.shared.usageDeletionRequest.setEnabled(enabled: true)
        GleanMetrics.Pings.shared.onboardingOptOut.setEnabled(enabled: true)

        let shouldSendUsagePing: Bool

        if let dailyUsagePing = profile.prefs.boolForKey(AppConstants.prefSendDailyUsagePing) {
            // If SendDailyUsagePing is explicitly set, use its value
            shouldSendUsagePing = dailyUsagePing
        } else if let usageData = profile.prefs.boolForKey(AppConstants.prefSendUsageData) {
            // If SendDailyUsagePing is not set, follow SendUsageData
            shouldSendUsagePing = usageData

            // Persist the SendDailyUsagePing value to ensure it is explicitly set for future launches
            profile.prefs.setBool(usageData, forKey: AppConstants.prefSendDailyUsagePing)
        } else {
            // Default to true if neither is set
            shouldSendUsagePing = true

            // Persist the default to ensure consistency on subsequent launches
            profile.prefs.setBool(true, forKey: AppConstants.prefSendDailyUsagePing)
        }

        if shouldSendUsagePing {
            gleanUsageReportingMetricsService.start()
        } else {
            gleanUsageReportingMetricsService.unsetUsageProfileId()
        }

        glean.registerPings(GleanMetrics.Pings.shared)

        // Initialize Glean telemetry
        let gleanConfig = Configuration(
            channel: AppConstants.buildChannel.rawValue,
            logLevel: .off
        )
        glean.initialize(uploadEnabled: sendUsageData,
                         configuration: gleanConfig,
                         buildInfo: GleanMetrics.GleanBuild.info)

        // Set the metric configuration from Nimbus.
        glean.applyServerKnobsConfig(FxNimbus.shared.features.gleanServerKnobs.value().toJSONString())

        // Save the profile so we can record settings from it when the notification below fires.
        self.profile = profile

        TelemetryContextualIdentifier.setupContextId()

        // Register an observer to record settings and other metrics that are more appropriate to
        // record on going to background rather than during initialization.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordEnteredBackgroundPreferenceMetrics(notification:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordFinishedLaunchingPreferenceMetrics(notification:)),
            name: UIApplication.didFinishLaunchingNotification,
            object: nil
        )
    }

    func recordStartUpTelemetry() {
        let isEnabled: Bool = (profile?.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.SponsoredShortcuts) ?? true) &&
                               (profile?.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.TopSiteSection) ?? true)
        recordEvent(category: .information,
                    method: .view,
                    object: .sponsoredShortcuts,
                    extras: [EventExtraKey.preference.rawValue: isEnabled])

        if logger.crashedLastLaunch {
            recordEvent(category: .information,
                        method: .error,
                        object: .app,
                        value: .crashedLastLaunch)
        }
    }

    @objc
    func recordFinishedLaunchingPreferenceMetrics(notification: NSNotification) {
        guard let profile = self.profile else { return }
        // Pocket stories visible
        if let pocketStoriesVisible = profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) {
            GleanMetrics.FirefoxHomePage.pocketStoriesVisible.set(pocketStoriesVisible)
        } else {
            GleanMetrics.FirefoxHomePage.pocketStoriesVisible.set(true)
        }
    }

    // Function for recording metrics that are better recorded when going to background due
    // to the particular measurement, or availability of the information.
    @objc
    func recordEnteredBackgroundPreferenceMetrics(notification: NSNotification) {
        guard let profile = self.profile else {
            assertionFailure("Error unwrapping profile")
            return
        }

        // Record default search engine setting
        let defaultEngine = profile.searchEnginesManager.defaultEngine
        GleanMetrics.Search.defaultEngine.set(defaultEngine?.engineID ?? "custom")

        // Record the open tab count
        let windowManager: WindowManager = AppContainer.shared.resolve()
        let tabCount = windowManager.allWindowTabManagers().map({ $0.count }).reduce(0, +)
        GleanMetrics.Tabs.cumulativeCount.add(Int32(tabCount))

        // Record other preference settings.
        // If the setting exists at the key location, use that value. Otherwise record the default
        // value for that preference to ensure it makes it into the metrics ping.
        let prefs = profile.prefs

        // FxA Account Login status
        GleanMetrics.Preferences.fxaLoggedIn.set(profile.hasSyncableAccount())

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

        // Notifications
        GleanMetrics.Preferences.tipsAndFeaturesNotifs.set(UserDefaults.standard.bool(forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications))
        GleanMetrics.Preferences.syncNotifs.set(UserDefaults.standard.bool(forKey: PrefsKeys.Notifications.SyncNotifications))

        // Save logins
        if let saveLogins = prefs.boolForKey(PrefsKeys.LoginsSaveEnabled) {
            GleanMetrics.Preferences.saveLogins.set(saveLogins)
        } else {
            GleanMetrics.Preferences.saveLogins.set(true)
        }

        // Show clipboard bar
        if let showClipboardBar = prefs.boolForKey(PrefsKeys.ShowClipboardBar) {
            GleanMetrics.Preferences.showClipboardBar.set(showClipboardBar)
        } else {
            GleanMetrics.Preferences.showClipboardBar.set(false)
        }

        // Close private tabs
        if let closePrivateTabs = prefs.boolForKey(PrefsKeys.Settings.closePrivateTabs) {
            GleanMetrics.Preferences.closePrivateTabs.set(closePrivateTabs)
        } else {
            GleanMetrics.Preferences.closePrivateTabs.set(false)
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

        // Installed Mozilla applications
        GleanMetrics.InstalledMozillaProducts.focus.set(UIApplication.shared.canOpenURL(URL(string: "firefox-focus://")!))
        GleanMetrics.InstalledMozillaProducts.klar.set(UIApplication.shared.canOpenURL(URL(string: "firefox-klar://")!))

        // Device Authentication
        GleanMetrics.Device.authentication.set(AppAuthenticator().canAuthenticateDeviceOwner)

        // Wallpapers
        let currentWallpaper = WallpaperManager().currentWallpaper

        if case .other = currentWallpaper.type {
            // Need to lowercase the name for labeled counter. Ref:
            // https://mozilla.github.io/glean/book/reference/metrics/index.html#label-format)
            GleanMetrics.WallpaperAnalytics.themedWallpaper[currentWallpaper.id.lowercased()].add()
        }

        // Homepage section preferences
        let isJumpBackInEnabled = featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildAndUser)
        GleanMetrics.Preferences.jumpBackIn.set(isJumpBackInEnabled)

        let isRecentlyVisitedEnabled = featureFlags.isFeatureEnabled(.historyHighlights, checking: .buildAndUser)
        GleanMetrics.Preferences.recentlyVisited.set(isRecentlyVisitedEnabled)

        let isBookmarksEnabled = prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.BookmarksSection) ?? true
        GleanMetrics.Preferences.recentlySaved.set(isBookmarksEnabled)

        let isFeatureEnabled = prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        let isPocketEnabled = isFeatureEnabled && PocketProvider.islocaleSupported(Locale.current.identifier)
        GleanMetrics.Preferences.pocket.set(isPocketEnabled)

        let startAtHomeOption = prefs.stringForKey(PrefsKeys.UserFeatureFlagPrefs.StartAtHome) ?? StartAtHomeSetting.afterFourHours.rawValue
        GleanMetrics.Preferences.openingScreen.set(startAtHomeOption)
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
        case information = "information"
        case firefoxSuggest = "fx-suggest"
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
        case detect = "detect"
        case drag = "drag"
        case drop = "drop"
        case foreground = "foreground"
        case swipe = "swipe"
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
        case application = "application"
        case voiceOver = "voice-over"
        case reduceTransparency = "reduce-transparency"
        case reduceMotion = "reduce-motion"
        case invertColors = "invert-colors"
        case switchControl = "switch-control"
        case dynamicTextSize = "dynamic-text-size"
        case error = "error"
    }

    public enum EventObject: String {
        case app = "app"
        case bookmark = "bookmark"
        case awesomebarResults = "awesomebar-results"
        case recordSearch = "record-search"
        case bookmarksPanel = "bookmarks-panel"
        case mobileBookmarks = "has-mobile-bookmarks"
        case download = "download"
        case downloadLinkButton = "download-link-button"
        case downloadNowButton = "download-now-button"
        case downloadsPanel = "downloads-panel"
        case defaultSearchEngine = "default-search-engine"
        case showPullRefreshEasterEgg = "show-pull-refresh-easter-egg"
        // MARK: Fakespot
        case shoppingButton = "shopping-button"
        case shoppingBottomSheet = "shopping-bottom-sheet"
        case shoppingProductPageVisits = "product_page_visits"
        case shoppingRecentReviews = "shopping-recent-reviews"
        case shoppingSettingsChevronButton = "shopping-settings-chevron-button"
        case shoppingOnboarding = "shopping-onboarding"
        case shoppingOptIn = "shopping-opt-in"
        case shoppingNotNowButton = "shopping-not-now-button"
        case shoppingTermsOfUseButton = "shopping-terms-of-use-button"
        case shoppingPrivacyPolicyButton = "shopping-privacy-policy-button"
        case shoppingLearnMoreButton = "shopping-learn-more-button"
        case shoppingLearnMoreReviewQualityButton = "shopping-learn-more-review-quality-button"
        case shoppingPoweredByFakespotLabel = "shopping-powered-by-fakespot-label"
        case shoppingNoAnalysisCardViewPrimaryButton = "shopping-no-analysis-card-view-primary-button"
        case shoppingNeedsAnalysisCardViewPrimaryButton = "shopping-needs-analysis-card-view-primary-button"
        case shoppingProductBackInStockButton = "shopping-product-back-in-stock-button"
        case shoppingSurfaceStaleAnalysisShown = "shopping-surface-stale-analysis-shown"
        case shoppingNimbusDisabled = "shopping-nimbus-disabled"
        case shoppingComponentOptedOut = "shopping-component-opted-out"
        case shoppingUserHasOnboarded = "shopping-user-has-onboarded"
        case shoppingAdsOptedOut = "shopping-ads-opted-out"
        case shoppingAdsSettingToggle = "shopping-ads-setting-toggle"
        case keyCommand = "key-command"
        case locationBar = "location-bar"
        case messaging = "messaging"
        case qrCodeText = "qr-code-text"
        case qrCodeURL = "qr-code-url"
        case readerModeCloseButton = "reader-mode-close-button"
        case readerModeOpenButton = "reader-mode-open-button"
        case readingListItem = "reading-list-item"
        case setting = "setting"
        case tab = "tab"
        case tabTray = "tab-tray"
        case tabNormalQuantity = "normal-tab-quantity"
        case tabPrivateQuantity = "private-tab-quantity"
        case tabInactiveQuantity = "inactive-tab-quantity"
        case iPadWindowCount = "ipad-window-count"
        case groupedTab = "grouped-tab"
        case groupedTabPerformSearch = "grouped-tab-perform-search"
        case trackingProtectionStatistics = "tracking-protection-statistics"
        case trackingProtectionSafelist = "tracking-protection-safelist"
        case trackingProtectionMenu = "tracking-protection-menu"
        case url = "url"
        case searchText = "searchText"
        case whatsNew = "whats-new"
        case help = "menu-help"
        case customizeHomePage = "menu-customize-home-page"
        case dismissUpdateCoverSheetAndStartBrowsing = "dismissed-update-cover_sheet_and_start_browsing"
        case dismissedUpdateCoverSheet = "dismissed-update-cover-sheet"
        case dismissedETPCoverSheet = "dismissed-etp-sheet"
        case dismissETPCoverSheetAndStartBrowsing = "dismissed-etp-cover-sheet-and-start-browsing"
        case dismissETPCoverSheetAndGoToSettings = "dismissed-update-cover-sheet-and-go-to-settings"
        case privateBrowsingButton = "private-browsing-button"
        case privateBrowsingIcon = "private-browsing-icon"
        case newPrivateTab = "new-private-tab"
        case startSearchButton = "start-search-button"
        case addNewTabButton = "add-new-tab-button"
        case removeUnVerifiedAccountButton = "remove-unverified-account-button"
        case tabSearch = "tab-search"
        case tabToolbar = "tab-toolbar"
        case chinaServerSwitch = "china-server-switch"
        case appMenu = "app_menu"
        case settings = "settings"
        case settingsMenuSetAsDefaultBrowser = "set-as-default-browser-menu-go-to-settings"
        case settingsMenuShowTour = "show-tour"
        case settingsMenuPasswords = "passwords"
        // MARK: Logins and Passwords
        case loginsAutofillPromptDismissed = "logins-autofill-prompt-dismissed"
        case loginsAutofillPromptExpanded = "logins-autofill-prompt-expanded"
        case loginsAutofillPromptShown = "logins-autofill-prompt-shown"
        case loginsAutofilled = "logins-autofilled"
        case loginsAutofillFailed = "logins-autofill-failed"
        case loginsManagementAddTapped = "logins-management-add-tapped"
        case loginsManagementLoginsTapped = "logins-management-logins-tapped"
        case loginsSaved = "logins-saved"
        case loginsSavedAll = "logins-saved-all"
        case loginsDeleted = "logins-deleted"
        case loginsModified = "logins-modified"
        case loginsSyncEnabled = "logins-sync-enabled"
        // MARK: Address
        case addressForm = "address-form"
        case addressFormFilled = "address-form-filled"
        case addressFormFilledModified = "address-form-filled-modified"
        case addressAutofillSettings = "address-autofill-settings"
        case addressAutofillPromptShown = "address-autofill-popup-shown"
        case addressAutofillPromptExpanded = "address-autofill-popup-expanded"
        case addressAutofillPromptDismissed = "address-autofill-popup-dismissed"

        // MARK: Credit Card
        case creditCardAutofillSettings = "creditCardAutofillSettings"
        case creditCardFormDetected = "creditCardFormDetected"
        case creditCardAutofilled = "creditCardAutofilled"
        case creditCardAutofillFailed = "creditCardAutofillFailed"
        case creditCardSavePromptCreate = "creditCardSavePromptCreate"
        case creditCardAutofillEnabled = "creditCardAutofillEnabled"
        case creditCardSyncEnabled = "creditCardSyncEnabled"
        case creditCardAutofillToggle = "creditCardAutofillToggle"
        case creditCardSyncToggle = "creditCardSyncToggle"
        case creditCardAutofillPromptShown = "creditCard-autofill-prompt-shown"
        case creditCardAutofillPromptExpanded = "creditCard-autofill-prompt-expanded"
        case creditCardAutofillPromptDismissed = "creditCard-autofill-prompt-dismissed"
        case creditCardSavePromptShown = "creditCard-save-prompt-shown"
        case creditCardSavePromptUpdate = "creditCard-save-prompt-update"
        case creditCardManagementAddTapped = "creditCard-management-add-tapped"
        case creditCardManagementCardTapped = "creditCard-management-card-tapped"
        case creditCardSaved = "creditCard-saved"
        case creditCardSavedAll = "creditCard-saved-all"
        case creditCardDeleted = "creditCard-deleted"
        case creditCardModified = "creditCard-modified"
        case notificationPermission = "notificationPermission"
        case defaultBrowser = "defaultBrowser"
        case choiceScreenAcquisition = "choiceScreenAcquisition"
        case engagementNotification = "engagementNotification"
        // MARK: New Onboarding
        case onboardingCardView = "onboarding-card-view"
        case onboardingPrimaryButton = "onboarding-card-primary-button"
        case onboardingSecondaryButton = "onboarding-card-secondary-button"
        case onboardingMultipleChoiceButton = "onboarding-multiple-choice-button"
        case onboardingClose = "onboarding-close"
        case onboardingWallpaperSelector = "onboarding-wallpaper-selector"
        case onboardingSelectWallpaper = "onboarding-select-wallpaper"
        // MARK: FXASignIn
        case onboarding = "onboarding"
        case upgradeOnboarding = "upgrade-onboarding"
        // MARK: New Upgrade screen
        case dismissDefaultBrowserCard = "default-browser-card"
        case goToSettingsDefaultBrowserCard = "default-browser-card-go-to-settings"
        case dismissDefaultBrowserOnboarding = "default-browser-onboarding"
        case goToSettingsDefaultBrowserOnboarding = "default-browser-onboarding-go-to-settings"
        case homeTabBannerEvergreen = "home-tab-banner-evergreen"
        case asDefaultBrowser = "as-default-browser"
        case mediumTabsOpenUrl = "medium-tabs-widget-url"
        case largeTabsOpenUrl = "large-tabs-widget-url"
        case smallQuickActionSearch = "small-quick-action-search"
        case smallQuickActionClosePrivate = "small-quick-action-close-private"
        case smallQuickActionCopiedLink = "small-quick-action-copied-link"
        case mediumQuickActionSearch = "medium-quick-action-search"
        case mediumQuickActionPrivateSearch = "medium-quick-action-private-search"
        case mediumQuickActionCopiedLink = "medium-quick-action-copied-link"
        case mediumQuickActionClosePrivate = "medium-quick-action-close-private"
        case mediumTopSitesWidget = "medium-top-sites-widget"
        case topSiteTile = "top-site-tile"
        case topSiteContextualMenu = "top-site-contextual-menu"
        case historyHighlightContextualMenu = "history-highlights-contextual-menu"
        case pocketStory = "pocket-story"
        case pocketSectionImpression = "pocket-section-impression"
        // MARK: - App menu
        case homePageMenu = "homepage-menu"
        case siteMenu = "site-menu"
        case home = "home-page"
        case blockImagesEnabled = "block-images-enabled"
        case blockImagesDisabled = "block-images-disabled"
        case navigateTabHistoryBack = "navigate-tab-history-back"
        case navigateTabHistoryBackSwipe = "navigate-tab-history-back-swipe"
        case navigateTabHistoryForward = "navigate-tab-history-forward"
        case nightModeEnabled = "night-mode-enabled"
        case nightModeDisabled = "night-mode-disabled"
        case logins = "logins-and-passwords"
        case signIntoSync = "sign-into-sync"
        case syncTab = "sync-tab"
        case syncSignIn = "sync-sign-in"
        case syncSignInUseEmail = "sync-sign-in-use-email"
        case syncSignInScanQRCode = "sync-sign-in-scan-qr-code"
        case syncUserLoggedOut = "sync-user-logged-out"
        case syncCreateAccount = "sync-create-account"
        case libraryPanel = "library-panel"
        case navigateToGroupHistory = "navigate-to-group-history"
        case selectedHistoryItem = "selected-history-item"
        case openedHistoryItem = "opened-item"
        case searchHistory = "search-history"
        case deleteHistory = "delete-history"
        case historySingleItemRemoved = "history-single-item-removed"
        case historyPanelOpened = "history-panel-opened"
        case historyRemovedToday = "history-removed-today"
        case historyRemovedTodayAndYesterday = "history-removed-today-and-yesterday"
        case historyRemovedAll = "history-removed-all"
        case shareSheet = "share-sheet"
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
        case wallpaperSettings = "wallpaper-settings"
        case contextualHint = "contextual-hint"
        case jumpBackInTileImpressions = "jump-back-in-tile-impressions"
        case syncedTabTileImpressions = "synced-tab-tile-impressions"
        case historyImpressions = "history-highlights-impressions"
        case bookmarkImpressions = "bookmark-impressions"
        case reload = "reload"
        case reloadFromUrlBar = "reload-from-url-bar"
        case fxaLoginWebpage = "fxa-login-webpage"
        case fxaLoginCompleteWebpage = "fxa-login-complete-webpage"
        case fxaRegistrationWebpage = "fxa-registration-webpage"
        case fxaRegistrationCompletedWebpage = "fxa-registration-completed-webpage"
        case fxaConfirmSignUpCode = "fxa-confirm-signup-code"
        case fxaConfirmSignInToken = "fxa-confirm-signin-token"
        case awesomebarLocation = "awesomebar-position"
        case searchHighlights = "search-highlights"
        case viewDownloadsPanel = "view-downloads-panel"
        case viewHistoryPanel = "view-history-panel"
        case createNewTab = "create-new-tab"
        case sponsoredShortcuts = "sponsored-shortcuts"
        case fxSuggest = "fx-suggest"
        case webview = "webview"
        case urlbarImpression = "urlbar-impression"
        case urlbarEngagement = "urlbar-engagement"
        case urlbarAbandonment = "urlbar-abandonment"
    }

    public enum EventValue: String {
        case activityStream = "activity-stream"
        case appIcon = "app-icon"
        case appMenu = "app-menu"
        case bookmarkItemAction = "bookmark-item-action"
        case bookmarkSectionShowAll = "bookmark-section-show-all"
        case bookmarkItemView = "bookmark-item-view"
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
        case shareSendToDevice = "share-send-to-device"
        case sharePocketIcon = "share-pocket-icon"
        case shareSaveToPocket = "save-to-pocket-share-action"
        case tabTray = "tab-tray"
        case topTabs = "top-tabs"
        case themeModeManually = "theme-manually"
        case themeModeAutomatically = "theme-automatically"
        case themeLight = "theme-light"
        case themeDark = "theme-dark"
        case privateTab = "private-tab"
        case normalTab = "normal-tab"
        case tabView = "tab-view"
        case bookmarksPanel = "bookmarks-panel"
        case doesHaveMobileBookmarks = "does-have-mobile-bookmarks"
        case doesNotHaveMobileBookmarks = "does-not-have-mobile-bookmarks"
        case mobileBookmarksCount = "mobile-bookmarks-count"
        case bookmarkAddFolder = "bookmark-add-folder"
        case openBookmarksFromTopSites = "top-sites"
        case historyPanel = "history-panel"
        case historyPanelNonGroupItem = "history-panel-non-grouped-item"
        case historyPanelGroupedItem = "history-panel-grouped-item"
        case readingPanel = "reading-panel"
        case downloadsPanel = "downloads-panel"
        case syncPanel = "sync-panel"
        case yourLibrarySection = "your-library-section"
        case jumpBackInSectionShowAll = "jump-back-in-section-show-all"
        case jumpBackInSectionTabOpened = "jump-back-in-section-tab-opened"
        case jumpBackInSectionGroupOpened = "jump-back-in-section-group-opened"
        case jumpBackInSectionSyncedTabShowAll = "jump-back-in-section-synced-tab-show-all"
        case jumpBackInSectionSyncedTabOpened = "jump-back-in-section-synced-tab-opened"
        case historyHighlightsShowAll = "history-highlights-show-all"
        case historyHighlightsItemOpened = "history-highlights-item-opened"
        case historyHighlightsGroupOpen = "history-highlights-group-open"
        case topSite = "top-site"
        case pocketSite = "pocket-site"
        case customizeHomepageButton = "customize-homepage-button"
        case wallpaperSelected = "wallpaper-selected"
        case dismissCFRFromButton = "dismiss-cfr-from-button"
        case dismissCFRFromOutsideTap = "dismiss-cfr-from-outside-tap"
        case pressCFRActionButton = "press-cfr-action-button"
        case fxHomepageOrigin = "firefox-homepage-origin"
        case fxHomepageOriginZeroSearch = "zero-search"
        case fxHomepageOriginOther = "origin-other"
        case addBookmarkToast = "add-bookmark-toast"
        case openHomeFromAwesomebar = "open-home-from-awesomebar"
        case openHomeFromPhotonMenuButton = "open-home-from-photon-menu-button"
        case openRecentlyClosedTab = "openRecentlyClosedTab"
        case tabGroupWithExtras = "tabGroupWithExtras"
        case closeGroupedTab = "recordCloseGroupedTab"
        case messageImpression = "message-impression"
        case messageDismissed = "message-dismissed"
        case messageInteracted = "message-interacted"
        case messageExpired = "message-expired"
        case messageMalformed = "message-malformed"
        case historyItem =  "history-item"
        case remoteTab = "remote-tab"
        case openedTab = "opened-tab"
        case bookmarkItem = "bookmark-item"
        case searchSuggestion = "search-suggestion"
        case searchHighlights = "search-highlights"
        case shoppingCFRsDisplayed = "shopping-cfrs-displayed"
        case surfaceAdsClicked = "surface-ads-clicked"
        case shoppingAdsExposure = "shopping-ads-exposure"
        case shoppingAdsImpression = "shopping-ads-impression"
        case shoppingNoAdsAvailable = "shopping-no-ads-available"
        case awesomebarShareTap = "awesomebar-share-tap"
        case largeFileWrite = "large-file-write"
        case crashedLastLaunch = "crashed_last_launch"
        case cpuException = "cpu_exception"
        case hangException = "hang-exception"
        case tabLossDetected = "tab_loss_detected"
        case fxSuggestionTelemetryInfo = "fx-suggestion-telemetry-info"
        case fxSuggestionPosition = "fx-suggestion-position"
        case fxSuggestionDidTap = "fx-suggestion-did-tap"
        case fxSuggestionDidAbandonSearchSession = "fx-suggestion-did-abandon-search-session"
        case webviewFail = "webview-fail"
        case webviewFailProvisional = "webview-fail-provisional"
        case webviewShowErrorPage = "webview-show-error-page"
    }

    public enum EventExtraKey: String, CustomStringConvertible {
        case isDefaultBrowser = "is-default-browser"
        case didComeFromBrowserChoiceScreen = "did-come-from-browser-choice-screen"

        case topSitePosition = "tilePosition"
        case topSiteTileType = "tileType"
        case contextualMenuType = "contextualMenuType"
        case pocketTilePosition = "pocketTilePosition"
        case fxHomepageOrigin = "fxHomepageOrigin"
        case tabsQuantity = "tabsQuantity"
        case recordSearchLocation = "recordSearchLocation"
        case recordSearchEngineID = "recordSearchEngineID"
        case windowCount = "windowCount"

        case preference = "pref"
        case preferenceChanged = "to"
        case isPrivate = "is-private"
        case action = "action"
        case size = "size"
        case errorCode = "errorCode"

        case wallpaperName = "wallpaperName"
        case wallpaperType = "wallpaperType"

        case cfrType = "hintType"

        // Bookmarks
        case mobileBookmarksQuantity = "mobileBookmarksQuantity"

        // Grouped Tab
        case groupsWithTwoTabsOnly = "groupsWithTwoTabsOnly"
        case groupsWithTwoMoreTab = "groupsWithTwoMoreTab"
        case totalNumberOfGroups = "totalNumOfGroups"
        case averageTabsInAllGroups = "averageTabsInAllGroups"
        case totalTabsInAllGroups = "totalTabsInAllGroups"
        var description: String {
            return self.rawValue
        }

        // Tracking Protection
        case etpSetting = "etp_setting"
        case etpEnabled = "etp_enabled"

        // Tabs Tray
        case done = "done"

        // GleanPlumb
        case actionUUID = "action-uuid"
        case messageKey = "message-key"
        case messageSurface = "message-surface"
        // Accessibility
        case isVoiceOverRunning = "is-voice-over-running"
        case isSwitchControlRunning = "is-switch-control-running"
        case isReduceTransparencyEnabled = "is-reduce-transparency-enabled"
        case isReduceMotionEnabled = "is-reduce-motion-enabled"
        case isInvertColorsEnabled = "is-invert-colors-enabled"
        case isAccessibilitySizeEnabled = "is-accessibility-size-enabled"
        case preferredContentSizeCategory = "preferred-content-size-category"

        // Onboarding
        case cardType = "card-type"
        case sequenceID = "sequence-ID"
        case sequencePosition = "sequence-position"
        case flowType = "flow-type"
        case buttonAction = "button-action"
        case multipleChoiceButtonAction = "mutiple-choice-button-action"

        // Notification permission
        case notificationPermissionIsGranted = "is-granted"
        case notificationPermissionStatus = "status"
        case notificationPermissionAlertSetting = "alert-setting"

        // Credit card
        case isCreditCardAutofillToggleEnabled = "is-credit-card-autofill-toggle-enabled"
        case isCreditCardSyncToggleEnabled = "is-credit-card-sync-toggle-enabled"
        case isCreditCardAutofillEnabled = "is-credit-card-autofill-enabled"
        case isCreditCardSyncEnabled = "is-credit-card-sync-enabled"
        case creditCardsQuantity = "credit-cards-quantity"

        // Password Manager
        case loginsQuantity = "loginsQuantity"
        case isLoginSyncEnabled = "sync-enabled"
        // Shopping Experience
        public enum Shopping: String {
            // Extra Keys for `surface_closed` event
            case clickOutside = "click-outside"
            case interactionWithALink = "interaction-with-a-link"
            case swipingTheSurfaceHandle = "swiping-the-surface-handle"
            case optingOutOfTheFeature = "opting-out-of-the-feature"
            case adsSettingToggle = "ads-setting-toggle"
            case closeButton = "close-button"
            case isNimbusDisabled = "is-nimbus-disabled"
            case isComponentOptedOut = "is-component-opted-out"
            case isUserOnboarded = "is-user-onboarded"
            case areAdsDisabled = "are-ads-disabled"
            // Extra Keys for `surface_displayed` event
            case halfView = "half-view"
            case fullView = "full-view"
        }

        // Awesomebar
        public enum UrlbarTelemetry: String {
            case nChars = "n_chars"
            case nResults = "n_results"
            case nWords = "n_words"
            case selectedResult = "selected_result"
            case selectedResultSubtype = "selected_result_subtype"
            case engagementType = "engagement_type"
            case provider
            case reason
            case sap
            case interaction
            case searchMode = "search_mode"
            case groups
            case results
        }

        public enum AddressTelemetry: String {
            case count
        }
    }

    func recordEvent(category: EventCategory,
                     method: EventMethod,
                     object: EventObject,
                     value: EventValue? = nil,
                     extras: [String: Any]? = nil
    ) {
        TelemetryWrapper.recordEvent(category: category,
                                     method: method,
                                     object: object,
                                     value: value,
                                     extras: extras)
    }

    public static func recordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: EventValue? = nil, extras: [String: Any]? = nil) {
        gleanRecordEvent(category: category, method: method, object: object, value: value, extras: extras)
    }

    static func gleanRecordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: EventValue? = nil, extras: [String: Any]? = nil) {
        switch (category, method, object, value, extras) {
        // MARK: Bookmarks
        case (.action, .view, .bookmarksPanel, let from?, _):
            GleanMetrics.Bookmarks.viewList[from.rawValue].add()
        case (.action, .add, .bookmark, let from?, _):
            GleanMetrics.Bookmarks.add[from.rawValue].add()
        case(.information, .view, .mobileBookmarks, .doesHaveMobileBookmarks, _):
            GleanMetrics.Bookmarks.hasMobileBookmarks.set(true)
        case(.information, .view, .mobileBookmarks, .doesNotHaveMobileBookmarks, _):
            GleanMetrics.Bookmarks.hasMobileBookmarks.set(false)
        case(.information, .view, .mobileBookmarks, .mobileBookmarksCount, let extras):
            if let quantity = extras?[EventExtraKey.mobileBookmarksQuantity.rawValue] as? Int64 {
                GleanMetrics.Bookmarks.mobileBookmarksCount.set(quantity)
            }
        // MARK: Reader Mode
        case (.action, .tap, .readerModeOpenButton, _, _):
            GleanMetrics.ReaderMode.open.add()
        case (.action, .tap, .readerModeCloseButton, _, _):
            GleanMetrics.ReaderMode.close.add()
        // MARK: Reading List
        case (.action, .add, .readingListItem, let from?, _):
            GleanMetrics.ReadingList.add[from.rawValue].add()
        case (.action, .delete, .readingListItem, let from?, _):
            GleanMetrics.ReadingList.delete[from.rawValue].add()
        case (.action, .open, .readingListItem, _, _):
            GleanMetrics.ReadingList.open.add()

        // MARK: History
        case(.information, .view, .historyPanelOpened, _, _):
            GleanMetrics.History.opened.record()
        case(.action, .swipe, .historySingleItemRemoved, _, _):
            GleanMetrics.History.removed.record()

        // MARK: Top Site
        case (.action, .tap, .topSiteTile, _, let extras):
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.TopSites.pressedTileOrigin[homePageOrigin].add()
            }

            if let position = extras?[EventExtraKey.topSitePosition.rawValue] as? String, let tileType = extras?[EventExtraKey.topSiteTileType.rawValue] as? String {
                GleanMetrics.TopSites.tilePressed.record(GleanMetrics.TopSites.TilePressedExtra(position: position, tileType: tileType))
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }

        case (.action, .view, .topSiteContextualMenu, _, let extras):
            if let type = extras?[EventExtraKey.contextualMenuType.rawValue] as? String {
                GleanMetrics.TopSites.contextualMenu.record(GleanMetrics.TopSites.ContextualMenuExtra(type: type))
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .newPrivateTab, .topSite, _):
            GleanMetrics.TopSites.openInPrivateTab.record()
        // MARK: Preferences
        case (.action, .change, .setting, _, let extras):
            if let preference = extras?[EventExtraKey.preference.rawValue] as? String,
                let to = ((extras?[EventExtraKey.preferenceChanged.rawValue]) ?? "undefined") as? String {
                GleanMetrics.Preferences.changed.record(GleanMetrics.Preferences.ChangedExtra(changedTo: to,
                                                                                              preference: preference))
            } else if let preference = extras?[EventExtraKey.preference.rawValue] as? String,
                        let to = ((extras?[EventExtraKey.preferenceChanged.rawValue]) ?? "undefined") as? Bool {
                GleanMetrics.Preferences.changed.record(GleanMetrics.Preferences.ChangedExtra(changedTo: to.description,
                                                                                              preference: preference))
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .privateBrowsingButton, _, let extras):
            if let isPrivate = extras?[EventExtraKey.isPrivate.rawValue] as? String {
                let isPrivateExtra = GleanMetrics.Preferences.PrivateBrowsingButtonTappedExtra(isPrivate: isPrivate)
                GleanMetrics.Preferences.privateBrowsingButtonTapped.record(isPrivateExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }

        // MARK: - QR Codes
        case (.action, .scan, .qrCodeText, _, _),
             (.action, .scan, .qrCodeURL, _, _):
            GleanMetrics.QrCode.scanned.add()

        // MARK: Tabs
        case (.action, .add, .tab, let privateOrNormal?, _):
            GleanMetrics.Tabs.open[privateOrNormal.rawValue].add()
        case (.action, .close, .tab, let privateOrNormal?, _):
            GleanMetrics.Tabs.close[privateOrNormal.rawValue].add()
        case (.action, .closeAll, .tab, let privateOrNormal?, _):
            GleanMetrics.Tabs.closeAll[privateOrNormal.rawValue].add()
        case (.action, .tap, .addNewTabButton, _, _):
            GleanMetrics.Tabs.newTabPressed.add()
        case (.action, .tap, .tab, _, _):
            GleanMetrics.Tabs.clickTab.record()
        case (.action, .open, .tabTray, _, _):
            GleanMetrics.Tabs.openTabTray.record()
        case (.action, .close, .tabTray, _, _):
            GleanMetrics.Tabs.closeTabTray.record()
        case (.action, .press, .tabToolbar, .tabView, _):
            GleanMetrics.Tabs.pressTabToolbar.record()
        case (.action, .press, .tab, _, _):
            GleanMetrics.Tabs.pressTopTab.record()
        case (.action, .pull, .reload, _, _):
            GleanMetrics.Tabs.pullToRefresh.record()
        case (.action, .detect, .showPullRefreshEasterEgg, _, _):
            GleanMetrics.Tabs.pullToRefreshEasterEgg.record()
        case(.action, .navigate, .tab, _, _):
            GleanMetrics.Tabs.normalAndPrivateUriCount.add()
        case(.action, .tap, .navigateTabHistoryBack, _, _), (.action, .press, .navigateTabHistoryBack, _, _):
            GleanMetrics.Tabs.navigateTabHistoryBack.add()
        case(.action, .tap, .navigateTabHistoryForward, _, _), (.action, .press, .navigateTabHistoryForward, _, _):
            GleanMetrics.Tabs.navigateTabHistoryForward.add()
        case(.action, .swipe, .navigateTabHistoryBackSwipe, _, _):
            GleanMetrics.Tabs.navigateTabBackSwipe.add()
        case(.action, .tap, .reloadFromUrlBar, _, _):
            GleanMetrics.Tabs.reloadFromUrlBar.add()
        case(.information, .background, .iPadWindowCount, _, let extras):
            if let quantity = extras?[EventExtraKey.windowCount.rawValue] as? Int64 {
                GleanMetrics.Windows.ipadWindowCount.set(quantity)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case(.information, .background, .tabNormalQuantity, _, let extras):
            if let quantity = extras?[EventExtraKey.tabsQuantity.rawValue] as? Int64 {
                GleanMetrics.Tabs.normalTabsQuantity.set(quantity)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case(.information, .background, .tabPrivateQuantity, _, let extras):
            if let quantity = extras?[EventExtraKey.tabsQuantity.rawValue] as? Int64 {
                GleanMetrics.Tabs.privateTabsQuantity.set(quantity)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case(.information, .background, .tabInactiveQuantity, _, let extras):
            if let quantity = extras?[EventExtraKey.tabsQuantity.rawValue] as? Int64 {
                GleanMetrics.Tabs.inactiveTabsCount.set(quantity)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        // MARK: Address
        case(.information, .foreground, .addressAutofillSettings, _, let extras):
            if let quantity = extras?[TelemetryWrapper.EventExtraKey.AddressTelemetry.count.rawValue] as? Int64 {
                GleanMetrics.Addresses.savedAll.set(quantity)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case(.action, .tap, .addressAutofillSettings, _, _):
            GleanMetrics.Addresses.settingsAutofill.record()
        case(.action, .view, .addressAutofillPromptShown, _, _):
            GleanMetrics.Addresses.autofillPromptShown.record()
        case(.action, .tap, .addressAutofillPromptExpanded, _, _):
            GleanMetrics.Addresses.autofillPromptExpanded.record()
        case(.action, .close, .addressAutofillPromptDismissed, _, _):
            GleanMetrics.Addresses.autofillPromptDismissed.record()
        case(.action, .change, .addressFormFilledModified, _, _):
            GleanMetrics.Addresses.modified.record()
        case(.action, .detect, .addressFormFilled, _, _):
            GleanMetrics.Addresses.autofilled.record()
        case(.action, .detect, .addressForm, _, _):
            GleanMetrics.Addresses.formDetected.record()

        // MARK: Credit Card
        case(.action, .tap, .creditCardAutofillSettings, _, _):
            GleanMetrics.CreditCard.autofillSettingsTapped.record()
        case(.action, .tap, .creditCardFormDetected, _, _):
            GleanMetrics.CreditCard.formDetected.record()
        case(.action, .tap, .creditCardAutofilled, _, _):
            GleanMetrics.CreditCard.autofilled.record()
        case(.action, .tap, .creditCardAutofillFailed, _, _):
            GleanMetrics.CreditCard.autofillFailed.record()
        case(.action, .tap, .creditCardSavePromptCreate, _, _):
            GleanMetrics.CreditCard.savePromptCreate.record()
        case(.information, .settings, .creditCardAutofillEnabled, _, let extras):
            if let isEnabled = extras?[EventExtraKey.isCreditCardAutofillEnabled.rawValue]
                as? Bool {
                GleanMetrics.CreditCard.autofillEnabled.set(isEnabled)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.information, .settings, .creditCardSyncEnabled, _, let extras):
            if let isEnabled = extras?[EventExtraKey.isCreditCardSyncEnabled.rawValue]
                as? Bool {
                GleanMetrics.CreditCard.syncEnabled.set(isEnabled)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.action, .tap, .creditCardAutofillToggle, _, let extras):
            if let isEnabled = extras?[EventExtraKey.isCreditCardAutofillToggleEnabled.rawValue]
                as? Bool {
                let isEnabledExtra = GleanMetrics.CreditCard.AutofillToggleExtra(isEnabled: isEnabled)
                GleanMetrics.CreditCard.autofillToggle.record(isEnabledExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.action, .tap, .creditCardSyncToggle, _, let extras):
            if let isEnabled = extras?[EventExtraKey.isCreditCardSyncToggleEnabled.rawValue]
                as? Bool {
                let isEnabledExtra = GleanMetrics.CreditCard.SyncToggleExtra(isEnabled: isEnabled)
                GleanMetrics.CreditCard.syncToggle.record(isEnabledExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.action, .view, .creditCardAutofillPromptShown, _, _):
            GleanMetrics.CreditCard.autofillPromptShown.record()
        case(.action, .tap, .creditCardAutofillPromptExpanded, _, _):
            GleanMetrics.CreditCard.autofillPromptExpanded.record()
        case(.action, .close, .creditCardAutofillPromptDismissed, _, _):
            GleanMetrics.CreditCard.autofillPromptDismissed.record()
        case(.action, .view, .creditCardSavePromptShown, _, _):
            GleanMetrics.CreditCard.savePromptShown.record()
        case(.action, .tap, .creditCardSavePromptUpdate, _, _):
            GleanMetrics.CreditCard.savePromptUpdate.record()
        case(.action, .tap, .creditCardManagementAddTapped, _, _):
            GleanMetrics.CreditCard.managementAddTapped.record()
        case(.action, .tap, .creditCardManagementCardTapped, _, _):
            GleanMetrics.CreditCard.managementCardTapped.record()
        case(.action, .add, .creditCardSaved, _, _):
            GleanMetrics.CreditCard.saved.add()
        case(.information, .foreground, .creditCardSavedAll, _, let extras):
            if let quantity = extras?[EventExtraKey.creditCardsQuantity.rawValue] as? Int64 {
                GleanMetrics.CreditCard.savedAll.set(quantity)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case(.action, .delete, .creditCardDeleted, _, _):
            GleanMetrics.CreditCard.deleted.add()
        case(.action, .change, .creditCardModified, _, _):
            GleanMetrics.CreditCard.modified.add()
        // MARK: Settings Menu
        case (.action, .open, .settingsMenuSetAsDefaultBrowser, _, _):
            GleanMetrics.SettingsMenu.setAsDefaultBrowserPressed.add()
        case(.action, .open, .settingsMenuPasswords, _, _):
            GleanMetrics.SettingsMenu.passwords.record()
        case(.action, .tap, .settingsMenuShowTour, _, _):
            GleanMetrics.SettingsMenu.showTourPressed.record()

        // MARK: Logins and Passwords
        case(.action, .view, .loginsAutofillPromptShown, _, _):
            GleanMetrics.Logins.autofillPromptShown.record()
        case(.action, .tap, .loginsAutofillPromptExpanded, _, _):
            GleanMetrics.Logins.autofillPromptExpanded.record()
        case(.action, .close, .loginsAutofillPromptDismissed, _, _):
            GleanMetrics.Logins.autofillPromptDismissed.record()
        case(.action, .tap, .loginsAutofilled, _, _):
            GleanMetrics.Logins.autofilled.record()
        case(.action, .tap, .loginsAutofillFailed, _, _):
            GleanMetrics.Logins.autofillFailed.record()
        case(.action, .tap, .loginsManagementAddTapped, _, _):
            GleanMetrics.Logins.managementAddTapped.record()
        case(.action, .tap, .loginsManagementLoginsTapped, _, _):
            GleanMetrics.Logins.managementLoginsTapped.record()
        case(.action, .add, .loginsSaved, _, _):
            GleanMetrics.Logins.saved.add()
        case(.information, .foreground, .loginsSavedAll, _, let extras):
            if let quantity = extras?[EventExtraKey.loginsQuantity.rawValue] as? Int64 {
                GleanMetrics.Logins.savedAll.set(quantity)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case(.action, .delete, .loginsDeleted, _, _):
            GleanMetrics.Logins.deleted.add()
        case(.action, .change, .loginsModified, _, _):
            GleanMetrics.Logins.modified.add()
        case(.action, .tap, .loginsSyncEnabled, _, let extras):
            if let isEnabled = extras?[EventExtraKey.isLoginSyncEnabled.rawValue] as? Bool {
                let isEnabledExtra = GleanMetrics.Logins.SyncEnabledExtra(isEnabled: isEnabled)
                GleanMetrics.Logins.syncEnabled.record(isEnabledExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }

        // MARK: - Search Engine
        case(.information, .change, .defaultSearchEngine, _, let extras):
            if let searchEngineID = extras?[EventExtraKey.recordSearchEngineID.rawValue] as? String? ?? "custom" {
                GleanMetrics.Search.defaultEngine.set(searchEngineID)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        // MARK: Start Search Button
        case (.action, .tap, .startSearchButton, _, _):
            GleanMetrics.Search.startSearchPressed.add()
        case(.action, .tap, .recordSearch, _, let extras):
            if let searchLocation = extras?[EventExtraKey.recordSearchLocation.rawValue]
                as? SearchLocation,
               let searchEngineID = extras?[EventExtraKey.recordSearchEngineID.rawValue] as? String? ?? "custom" {
                GleanMetrics.Search.counts["\(searchEngineID).\(searchLocation.rawValue)"].add()
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }

        // MARK: Awesomebar Search Results
        case(.information, .view, .urlbarImpression, _, let extras):
            if let groups = extras?[EventExtraKey.UrlbarTelemetry.groups.rawValue] as? String,
               let interaction = extras?[EventExtraKey.UrlbarTelemetry.interaction.rawValue] as? String,
               let nChars = extras?[EventExtraKey.UrlbarTelemetry.nChars.rawValue] as? Int32,
               let nResults = extras?[EventExtraKey.UrlbarTelemetry.nResults.rawValue] as? Int32,
               let nWords = extras?[EventExtraKey.UrlbarTelemetry.nWords.rawValue] as? Int32,
               let reason = extras?[EventExtraKey.UrlbarTelemetry.reason.rawValue] as? String,
               let results = extras?[EventExtraKey.UrlbarTelemetry.results.rawValue] as? String,
               let sap = extras?[EventExtraKey.UrlbarTelemetry.sap.rawValue] as? String,
               let searchMode = extras?[EventExtraKey.UrlbarTelemetry.searchMode.rawValue] as? String {
                let extraDetails = GleanMetrics.Urlbar.ImpressionExtra(groups: groups,
                                                                       interaction: interaction,
                                                                       nChars: nChars,
                                                                       nResults: nResults,
                                                                       nWords: nWords,
                                                                       reason: reason,
                                                                       results: results,
                                                                       sap: sap,
                                                                       searchMode: searchMode)
                GleanMetrics.Urlbar.impression.record(extraDetails)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.action, .tap, .urlbarEngagement, _, let extras):
            if let groups = extras?[EventExtraKey.UrlbarTelemetry.groups.rawValue] as? String,
               let interaction = extras?[EventExtraKey.UrlbarTelemetry.interaction.rawValue] as? String,
               let nChars = extras?[EventExtraKey.UrlbarTelemetry.nChars.rawValue] as? Int32,
               let nResults = extras?[EventExtraKey.UrlbarTelemetry.nResults.rawValue] as? Int32,
               let nWords = extras?[EventExtraKey.UrlbarTelemetry.nWords.rawValue] as? Int32,
               let results = extras?[EventExtraKey.UrlbarTelemetry.results.rawValue] as? String,
               let sap = extras?[EventExtraKey.UrlbarTelemetry.sap.rawValue] as? String,
               let searchMode = extras?[EventExtraKey.UrlbarTelemetry.searchMode.rawValue] as? String,
               let engagementType = extras?[EventExtraKey.UrlbarTelemetry.engagementType.rawValue] as? String,
               let provider = extras?[EventExtraKey.UrlbarTelemetry.provider.rawValue] as? String,
               let selectedResult = extras?[EventExtraKey.UrlbarTelemetry.selectedResult.rawValue] as? String,
               let selectedResultSubtype = extras?[EventExtraKey.UrlbarTelemetry.selectedResultSubtype.rawValue] as? String {
                let extraDetails = GleanMetrics.Urlbar.EngagementExtra(engagementType: engagementType,
                                                                       groups: groups,
                                                                       interaction: interaction,
                                                                       nChars: nChars,
                                                                       nResults: nResults,
                                                                       nWords: nWords,
                                                                       provider: provider,
                                                                       results: results,
                                                                       sap: sap,
                                                                       searchMode: searchMode,
                                                                       selectedResult: selectedResult,
                                                                       selectedResultSubtype: selectedResultSubtype)
                GleanMetrics.Urlbar.engagement.record(extraDetails)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }

        case(.action, .close, .urlbarAbandonment, _, let extras):
            if let groups = extras?[EventExtraKey.UrlbarTelemetry.groups.rawValue] as? String,
               let interaction = extras?[EventExtraKey.UrlbarTelemetry.interaction.rawValue] as? String,
               let nChars = extras?[EventExtraKey.UrlbarTelemetry.nChars.rawValue] as? Int32,
               let nResults = extras?[EventExtraKey.UrlbarTelemetry.nResults.rawValue] as? Int32,
               let nWords = extras?[EventExtraKey.UrlbarTelemetry.nWords.rawValue] as? Int32,
               let results = extras?[EventExtraKey.UrlbarTelemetry.results.rawValue] as? String,
               let sap = extras?[EventExtraKey.UrlbarTelemetry.sap.rawValue] as? String,
               let searchMode = extras?[EventExtraKey.UrlbarTelemetry.searchMode.rawValue] as? String {
                let extraDetails = GleanMetrics.Urlbar.AbandonmentExtra(groups: groups,
                                                                        interaction: interaction,
                                                                        nChars: nChars,
                                                                        nResults: nResults,
                                                                        nWords: nWords,
                                                                        results: results,
                                                                        sap: sap,
                                                                        searchMode: searchMode)
                GleanMetrics.Urlbar.abandonment.record(extraDetails)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        // MARK: Default Browser
        case (.action, .tap, .dismissDefaultBrowserCard, _, _):
            GleanMetrics.DefaultBrowserCard.dismissPressed.add()
        case (.action, .tap, .goToSettingsDefaultBrowserCard, _, _):
            GleanMetrics.DefaultBrowserCard.goToSettingsPressed.add()
        case (.action, .open, .asDefaultBrowser, _, _):
            GleanMetrics.App.openedAsDefaultBrowser.add()
        case(.action, .view, .notificationPermission, _, let extras):
            if let status = extras?[EventExtraKey.notificationPermissionStatus.rawValue] as? String,
               let alertSetting = extras?[EventExtraKey.notificationPermissionAlertSetting.rawValue] as? String {
                let permissionExtra = GleanMetrics.App.NotificationPermissionExtra(alertSetting: alertSetting,
                                                                                   status: status)
                GleanMetrics.App.notificationPermission.record(permissionExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case (.action, .open, .defaultBrowser, _, let extras):
            if let isDefaultBrowser = extras?[EventExtraKey.isDefaultBrowser.rawValue] as? Bool {
                GleanMetrics.App.defaultBrowser.set(isDefaultBrowser)
            }
        case (.action, .open, .choiceScreenAcquisition, _, let extras):
            if let choiceScreen = extras?[EventExtraKey.didComeFromBrowserChoiceScreen.rawValue] as? Bool {
                GleanMetrics.App.choiceScreenAcquisition.set(choiceScreen)
            }
        case(.action, .tap, .engagementNotification, _, _):
            GleanMetrics.Onboarding.engagementNotificationTapped.record()
        case(.action, .cancel, .engagementNotification, _, _):
            GleanMetrics.Onboarding.engagementNotificationCancel.record()
        case (.action, .tap, .dismissDefaultBrowserOnboarding, _, _):
            GleanMetrics.DefaultBrowserOnboarding.dismissPressed.add()
        case (.action, .tap, .goToSettingsDefaultBrowserOnboarding, _, _):
            GleanMetrics.DefaultBrowserOnboarding.goToSettingsPressed.add()
        case (.information, .view, .homeTabBannerEvergreen, _, _):
            GleanMetrics.DefaultBrowserCard.evergreenImpression.record()
        // MARK: Downloads
        case(.action, .tap, .downloadNowButton, _, _):
            GleanMetrics.Downloads.downloadNowButtonTapped.record()
        case(.action, .tap, .download, .downloadsPanel, _):
            GleanMetrics.Downloads.downloadsPanelRowTapped.record()
        case(.action, .view, .downloadsPanel, .downloadCompleteToast, _):
            GleanMetrics.Downloads.viewDownloadCompleteToast.record()
        // MARK: Key Commands
        case(.action, .press, .keyCommand, _, let extras):
            if let action = extras?[EventExtraKey.action.rawValue] as? String {
                let actionExtra = GleanMetrics.KeyCommands.PressKeyCommandActionExtra(action: action)
                GleanMetrics.KeyCommands.pressKeyCommandAction.record(actionExtra)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }

        // MARK: Shopping Experience (Fakespot)
        case (.action, .view, .shoppingBottomSheet, .surfaceAdsClicked, _):
            GleanMetrics.Shopping.surfaceAdsClicked.record()
        case (.action, .tap, .shoppingButton, _, _):
            GleanMetrics.Shopping.addressBarIconClicked.record()
        case (.action, .view, .shoppingBottomSheet, .shoppingAdsExposure, _):
            GleanMetrics.Shopping.adsExposure.record()
        case (.action, .view, .shoppingBottomSheet, .shoppingAdsImpression, _):
            GleanMetrics.Shopping.surfaceAdsImpression.record()
        case (.action, .view, .shoppingBottomSheet, .shoppingNoAdsAvailable, _):
            GleanMetrics.Shopping.surfaceNoAdsAvailable.record()
        case (.action, .view, .shoppingButton, _, _):
            GleanMetrics.Shopping.addressBarIconDisplayed.record()
        case (.action, .close, .shoppingBottomSheet, _, let extras):
            if let action = extras?[EventExtraKey.action.rawValue] as? String {
                let actionExtra = GleanMetrics.Shopping.SurfaceClosedExtra(action: action)
                GleanMetrics.Shopping.surfaceClosed.record(actionExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case (.action, .tap, .shoppingRecentReviews, _, _):
            GleanMetrics.Shopping.surfaceShowMoreRecentReviewsClicked.record()
        case (.action, .view, .shoppingBottomSheet, _, let extras):
            if let size = extras?[EventExtraKey.size.rawValue] as? String {
                let sizeExtra = GleanMetrics.Shopping.SurfaceDisplayedExtra(size: size)
                GleanMetrics.Shopping.surfaceDisplayed.record(sizeExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case (.action, .view, .shoppingSettingsChevronButton, _, _):
            GleanMetrics.Shopping.surfaceSettingsExpandClicked.record()
        case (.action, .view, .shoppingOnboarding, _, _):
            GleanMetrics.Shopping.surfaceOnboardingDisplayed.record()
        case (.action, .tap, .shoppingOptIn, _, _):
            GleanMetrics.Shopping.surfaceOptInAccepted.record()
        case (.action, .tap, .shoppingNotNowButton, _, _):
            GleanMetrics.Shopping.surfaceNotNowClicked.record()
        case (.action, .tap, .shoppingTermsOfUseButton, _, _):
            GleanMetrics.Shopping.surfaceShowTermsClicked.record()
        case (.action, .tap, .shoppingPrivacyPolicyButton, _, _):
            GleanMetrics.Shopping.surfaceShowPrivacyPolicyClicked.record()
        case (.action, .tap, .shoppingLearnMoreButton, _, _):
            GleanMetrics.Shopping.surfaceLearnMoreClicked.record()
        case (.action, .tap, .shoppingLearnMoreReviewQualityButton, _, _):
            GleanMetrics.Shopping.surfaceShowQualityExplainerClicked.record()
        case (.action, .navigate, .shoppingButton, .shoppingCFRsDisplayed, _):
            GleanMetrics.Shopping.addressBarFeatureCalloutDisplayed.record()
        case (.information, .view, .shoppingProductPageVisits, _, _):
            GleanMetrics.Shopping.productPageVisits.add()
        case (.action, .tap, .shoppingPoweredByFakespotLabel, _, _):
            GleanMetrics.Shopping.surfacePoweredByFakespotLinkClicked.record()
        case (.action, .tap, .shoppingNoAnalysisCardViewPrimaryButton, _, _):
            GleanMetrics.Shopping.surfaceAnalyzeReviewsNoneAvailableClicked.record()
        case (.action, .tap, .shoppingNeedsAnalysisCardViewPrimaryButton, _, _):
            GleanMetrics.Shopping.surfaceReanalyzeClicked.record()
        case (.action, .tap, .shoppingProductBackInStockButton, _, _):
            GleanMetrics.Shopping.surfaceReactivatedButtonClicked.record()
        case(.action, .tap, .shoppingAdsSettingToggle, _, let extras):
            if let isEnabled = extras?[EventExtraKey.Shopping.adsSettingToggle.rawValue]
                as? Bool {
                let isEnabledExtra = GleanMetrics.Shopping.SurfaceAdsSettingToggledExtra(isEnabled: isEnabled)
                GleanMetrics.Shopping.surfaceAdsSettingToggled.record(isEnabledExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case (.action, .navigate, .shoppingBottomSheet, _, _):
            GleanMetrics.Shopping.surfaceNoReviewReliabilityAvailable.record()
        case (.action, .view, .shoppingSurfaceStaleAnalysisShown, _, _):
            GleanMetrics.Shopping.surfaceStaleAnalysisShown.record()
        case(.information, .settings, .shoppingNimbusDisabled, _, let extras):
            if let isDisabled = extras?[EventExtraKey.Shopping.isNimbusDisabled.rawValue]
                as? Bool {
                GleanMetrics.ShoppingSettings.nimbusDisabledShopping.set(isDisabled)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.information, .settings, .shoppingComponentOptedOut, _, let extras):
            if let isOptedOut = extras?[EventExtraKey.Shopping.isComponentOptedOut.rawValue]
                as? Bool {
                GleanMetrics.ShoppingSettings.componentOptedOut.set(isOptedOut)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.information, .settings, .shoppingUserHasOnboarded, _, let extras):
            if let isOnboarded = extras?[EventExtraKey.Shopping.isUserOnboarded.rawValue]
                as? Bool {
                GleanMetrics.ShoppingSettings.userHasOnboarded.set(isOnboarded)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.information, .settings, .shoppingAdsOptedOut, _, let extras):
            if let fakespotAdsEnabled = extras?[EventExtraKey.Shopping.areAdsDisabled.rawValue]
                as? Bool {
                GleanMetrics.ShoppingSettings.disabledAds.set(fakespotAdsEnabled)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        // MARK: Onboarding
        case (.action, .view, .onboardingCardView, _, let extras):
            if let type = extras?[ExtraKey.cardType.rawValue] as? String,
               let seqID = extras?[ExtraKey.sequenceID.rawValue] as? String,
               let seqPosition = extras?[ExtraKey.sequencePosition.rawValue] as? String,
               let flowType = extras?[ExtraKey.flowType.rawValue] as? String {
                let cardExtras = GleanMetrics.Onboarding.CardViewExtra(
                    cardType: type,
                    flowType: flowType,
                    sequenceId: seqID,
                    sequencePosition: seqPosition)
                GleanMetrics.Onboarding.cardView.record(cardExtras)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .onboardingPrimaryButton, _, let extras):
            if let type = extras?[ExtraKey.cardType.rawValue] as? String,
               let seqID = extras?[ExtraKey.sequenceID.rawValue] as? String,
               let seqPosition = extras?[ExtraKey.sequencePosition.rawValue] as? String,
               let action = extras?[ExtraKey.buttonAction.rawValue] as? String,
               let flowType = extras?[ExtraKey.flowType.rawValue] as? String {
                let cardExtras = GleanMetrics.Onboarding.PrimaryButtonTapExtra(
                    buttonAction: action,
                    cardType: type,
                    flowType: flowType,
                    sequenceId: seqID,
                    sequencePosition: seqPosition)
                GleanMetrics.Onboarding.primaryButtonTap.record(cardExtras)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .onboardingSecondaryButton, _, let extras):
            if let type = extras?[ExtraKey.cardType.rawValue] as? String,
               let seqID = extras?[ExtraKey.sequenceID.rawValue] as? String,
               let seqPosition = extras?[ExtraKey.sequencePosition.rawValue] as? String,
               let action = extras?[ExtraKey.buttonAction.rawValue] as? String,
               let flowType = extras?[ExtraKey.flowType.rawValue] as? String {
                let cardExtras = GleanMetrics.Onboarding.SecondaryButtonTapExtra(
                    buttonAction: action,
                    cardType: type,
                    flowType: flowType,
                    sequenceId: seqID,
                    sequencePosition: seqPosition)
                GleanMetrics.Onboarding.secondaryButtonTap.record(cardExtras)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .onboardingMultipleChoiceButton, _, let extras):
            if let type = extras?[ExtraKey.cardType.rawValue] as? String,
               let seqID = extras?[ExtraKey.sequenceID.rawValue] as? String,
               let seqPosition = extras?[ExtraKey.sequencePosition.rawValue] as? String,
               let action = extras?[ExtraKey.multipleChoiceButtonAction.rawValue] as? String,
               let flowType = extras?[ExtraKey.flowType.rawValue] as? String {
                let cardExtras = GleanMetrics.Onboarding.MultipleChoiceButtonTapExtra(
                    buttonAction: action,
                    cardType: type,
                    flowType: flowType,
                    sequenceId: seqID,
                    sequencePosition: seqPosition)
                GleanMetrics.Onboarding.multipleChoiceButtonTap.record(cardExtras)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .onboardingClose, _, let extras):
            if let type = extras?[ExtraKey.cardType.rawValue] as? String,
               let seqID = extras?[ExtraKey.sequenceID.rawValue] as? String,
               let seqPosition = extras?[ExtraKey.sequencePosition.rawValue] as? String,
               let flowType = extras?[ExtraKey.flowType.rawValue] as? String {
                let cardExtras = GleanMetrics.Onboarding.CloseTapExtra(
                    cardType: type,
                    flowType: flowType,
                    sequenceId: seqID,
                    sequencePosition: seqPosition)
                GleanMetrics.Onboarding.closeTap.record(cardExtras)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .onboardingSelectWallpaper, .wallpaperSelected, let extras):
            if let name = extras?[EventExtraKey.wallpaperName.rawValue] as? String,
               let type = extras?[EventExtraKey.wallpaperType.rawValue] as? String {
                let wallpaperExtra = GleanMetrics.Onboarding.WallpaperSelectedExtra(wallpaperName: name, wallpaperType: type)
                GleanMetrics.Onboarding.wallpaperSelected.record(wallpaperExtra)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .onboardingWallpaperSelector, .wallpaperSelected, let extras):
            if let name = extras?[EventExtraKey.wallpaperName.rawValue] as? String,
               let type = extras?[EventExtraKey.wallpaperType.rawValue] as? String {
                let wallpaperExtra = GleanMetrics.Onboarding.WallpaperSelectorSelectedExtra(wallpaperName: name, wallpaperType: type)
                GleanMetrics.Onboarding.wallpaperSelectorSelected.record(wallpaperExtra)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .view, .onboardingWallpaperSelector, _, _):
            GleanMetrics.Onboarding.wallpaperSelectorView.record()
        case (.action, .close, .onboardingWallpaperSelector, _, _):
            GleanMetrics.Onboarding.wallpaperSelectorClose.record()
        case(.prompt, .tap, .notificationPermission, _, let extras):
            if let isPermissionGranted = extras?[EventExtraKey.notificationPermissionIsGranted.rawValue] as? Bool {
                let permissionExtra = GleanMetrics.Onboarding.NotificationPermissionPromptExtra(granted: isPermissionGranted)
                GleanMetrics.Onboarding.notificationPermissionPrompt.record(permissionExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }

        // MARK: Widget
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

        // MARK: Pocket
        case (.action, .tap, .pocketStory, _, let extras):
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.Pocket.openStoryOrigin[homePageOrigin].add()
            }

            if let position = extras?[EventExtraKey.pocketTilePosition.rawValue] as? String {
                GleanMetrics.Pocket.openStoryPosition["position-"+position].add()
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .view, .pocketSectionImpression, _, _):
            GleanMetrics.Pocket.sectionImpressions.add()
        case (.action, .tap, .newPrivateTab, .pocketSite, _):
            GleanMetrics.Pocket.openInPrivateTab.record()

        // MARK: Library Panel
        case (.action, .tap, .libraryPanel, let type?, _):
            GleanMetrics.Library.panelPressed[type.rawValue].add()
        // History Panel related
        case (.action, .navigate, .navigateToGroupHistory, _, _):
            GleanMetrics.History.groupList.add()
        case (.action, .tap, .selectedHistoryItem, let type?, _):
            GleanMetrics.History.selectedItem[type.rawValue].add()
        case (.action, .tap, .openedHistoryItem, _, _):
            GleanMetrics.History.openedItem.record()
        case (.action, .tap, .searchHistory, _, _):
            GleanMetrics.History.searchTap.record()
        case (.action, .tap, .deleteHistory, _, _):
            GleanMetrics.History.deleteTap.record()
        // MARK: Sync
        case (.action, .open, .syncTab, _, _):
            GleanMetrics.Sync.openTab.add()
        case (.action, .tap, .syncSignIn, _, _):
            GleanMetrics.Sync.signInSyncPressed.add()
        case (.action, .tap, .syncCreateAccount, _, _):
            GleanMetrics.Sync.createAccountPressed.add()
        case (.firefoxAccount, .view, .fxaRegistrationWebpage, _, _):
            GleanMetrics.Sync.registrationView.record()
        case (.firefoxAccount, .view, .fxaRegistrationCompletedWebpage, _, _):
            GleanMetrics.Sync.registrationCompletedView.record()
        case (.firefoxAccount, .view, .fxaLoginWebpage, _, _):
            GleanMetrics.Sync.loginView.record()
        case (.firefoxAccount, .view, .fxaLoginCompleteWebpage, _, _):
            GleanMetrics.Sync.loginCompletedView.record()
            // record the same event for Nimbus' internal event store
            Experiments.events.recordEvent(BehavioralTargetingEvent.syncLoginCompletion)
        case (.firefoxAccount, .view, .fxaConfirmSignUpCode, _, _):
            GleanMetrics.Sync.registrationCodeView.record()
        case (.firefoxAccount, .view, .fxaConfirmSignInToken, _, _):
            GleanMetrics.Sync.loginTokenView.record()
        case (.firefoxAccount, .tap, .syncSignInUseEmail, _, _):
            GleanMetrics.Sync.useEmail.record()
        case (.firefoxAccount, .tap, .syncSignInScanQRCode, _, _):
            GleanMetrics.Sync.paired.record()
        case (.firefoxAccount, .tap, .syncUserLoggedOut, _, _):
            GleanMetrics.Sync.disconnect.record()
        // MARK: App cycle
        case(.action, .foreground, .app, _, _):
            GleanMetrics.AppCycle.foreground.record()
            GleanMetrics.ServerKnobs.validation.record()
            // record the same event for Nimbus' internal event store
            Experiments.events.recordEvent(BehavioralTargetingEvent.appForeground)
        case(.action, .background, .app, _, _):
            GleanMetrics.AppCycle.background.record()
        // MARK: App icon
        case (.action, .tap, .newPrivateTab, .appIcon, _):
            GleanMetrics.AppIcon.newPrivateTabTapped.record()
        // MARK: Accessibility
        case(.action, .voiceOver, .app, _, let extras):
            if let isRunning = extras?[EventExtraKey.isVoiceOverRunning.rawValue] as? String {
                let isRunningExtra = GleanMetrics.Accessibility.VoiceOverExtra(isRunning: isRunning)
                GleanMetrics.Accessibility.voiceOver.record(isRunningExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.action, .switchControl, .app, _, let extras):
            if let isRunning = extras?[EventExtraKey.isSwitchControlRunning.rawValue] as? String {
                let isRunningExtra = GleanMetrics.Accessibility.SwitchControlExtra(isRunning: isRunning)
                GleanMetrics.Accessibility.switchControl.record(isRunningExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.action, .reduceTransparency, .app, _, let extras):
            if let isEnabled = extras?[EventExtraKey.isReduceTransparencyEnabled.rawValue] as? String {
                let isEnabledExtra = GleanMetrics.Accessibility.ReduceTransparencyExtra(isEnabled: isEnabled)
                GleanMetrics.Accessibility.reduceTransparency.record(isEnabledExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.action, .reduceMotion, .app, _, let extras):
            if let isEnabled = extras?[EventExtraKey.isReduceMotionEnabled.rawValue] as? String {
                let isEnabledExtra = GleanMetrics.Accessibility.ReduceMotionExtra(isEnabled: isEnabled)
                GleanMetrics.Accessibility.reduceMotion.record(isEnabledExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.action, .invertColors, .app, _, let extras):
            if let isEnabled = extras?[EventExtraKey.isInvertColorsEnabled.rawValue] as? String {
                let isEnabledExtra = GleanMetrics.Accessibility.InvertColorsExtra(isEnabled: isEnabled)
                GleanMetrics.Accessibility.invertColors.record(isEnabledExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case(.action, .dynamicTextSize, .app, _, let extras):
            if let isAccessibilitySizeEnabled = extras?[EventExtraKey.isAccessibilitySizeEnabled.rawValue] as? String,
               let preferredSize = extras?[EventExtraKey.preferredContentSizeCategory.rawValue] as? String {
                let dynamicTextExtra = GleanMetrics.Accessibility.DynamicTextExtra(
                    isAccessibilitySizeEnabled: isAccessibilitySizeEnabled,
                    preferredSize: preferredSize)
                GleanMetrics.Accessibility.dynamicText.record(dynamicTextExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        // MARK: App menu
        case (.action, .tap, .homePageMenu, _, _):
            GleanMetrics.AppMenu.homepageMenu.add()
        case (.action, .tap, .siteMenu, _, _):
            GleanMetrics.AppMenu.siteMenu.add()
        case (.action, .tap, .logins, _, _):
            GleanMetrics.AppMenu.logins.add()
        case (.action, .tap, .signIntoSync, _, _):
            GleanMetrics.AppMenu.signIntoSync.add()
        case (.action, .tap, .home, _, _):
            GleanMetrics.AppMenu.home.add()
        case (.action, .tap, .blockImagesEnabled, _, _):
            GleanMetrics.AppMenu.blockImagesEnabled.add()
        case (.action, .tap, .blockImagesDisabled, _, _):
            GleanMetrics.AppMenu.blockImagesDisabled.add()
        case (.action, .tap, .nightModeEnabled, _, _):
            GleanMetrics.AppMenu.nightModeEnabled.add()
        case (.action, .tap, .nightModeDisabled, _, _):
            GleanMetrics.AppMenu.nightModeDisabled.add()
        case (.action, .open, .whatsNew, _, _):
            GleanMetrics.AppMenu.whatsNew.add()
        case (.action, .tap, .help, _, _):
            GleanMetrics.AppMenu.help.add()
        case (.action, .tap, .customizeHomePage, _, _):
            GleanMetrics.AppMenu.customizeHomepage.add()
        case (.action, .open, .settings, _, _):
            GleanMetrics.AppMenu.settings.add()
        case(.action, .open, .logins, _, _):
            GleanMetrics.AppMenu.passwords.record()

        // MARK: Page Menu
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
        case (.action, .tap, .viewDownloadsPanel, _, _):
            GleanMetrics.PageActionMenu.viewDownloadsPanel.add()
        case (.action, .tap, .viewHistoryPanel, _, _):
            GleanMetrics.PageActionMenu.viewHistoryPanel.add()
        case (.action, .tap, .createNewTab, _, _):
            GleanMetrics.PageActionMenu.createNewTab.add()

        // MARK: Tracking Protection
        case (.action, .tap, .trackingProtectionMenu, _, let extras):
            if let action = extras?[EventExtraKey.etpSetting.rawValue] as? String {
                let actionExtra = GleanMetrics.TrackingProtection.EtpSettingChangedExtra(etpSetting: action)
                GleanMetrics.TrackingProtection.etpSettingChanged.record(actionExtra)
            } else if let action = extras?[EventExtraKey.etpEnabled.rawValue] as? Bool {
                let actionExtra = GleanMetrics.TrackingProtection.EtpSettingChangedExtra(etpEnabled: action)
                GleanMetrics.TrackingProtection.etpSettingChanged.record(actionExtra)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        // MARK: Tabs Tray
        case (.action, .tap, .privateBrowsingIcon, .tabTray, let extras):
            if let action = extras?[EventExtraKey.action.rawValue] as? String {
                let actionExtra = GleanMetrics.TabsTray.PrivateBrowsingIconTappedExtra(action: action)
                GleanMetrics.TabsTray.privateBrowsingIconTapped.record(actionExtra)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .newPrivateTab, .tabTray, _):
            GleanMetrics.TabsTray.newPrivateTabTapped.record()

        // MARK: Tab Groups
        case (.action, .view, .tabTray, .tabGroupWithExtras, let extras):
           let groupedTabExtras = GleanMetrics.Tabs.GroupedTabExtra(
            averageTabsInAllGroups: extras?["\(EventExtraKey.averageTabsInAllGroups)"] as? Int32,
            groupsTwoTabsOnly: extras?["\(EventExtraKey.groupsWithTwoTabsOnly)"] as? Int32,
            groupsWithMoreThanTwoTab: extras?["\(EventExtraKey.groupsWithTwoMoreTab)"] as? Int32,
            totalNumOfGroups: extras?["\(EventExtraKey.totalNumberOfGroups)"] as? Int32,
            totalTabsInAllGroups: extras?["\(EventExtraKey.totalTabsInAllGroups)"] as? Int32)
            GleanMetrics.Tabs.groupedTab.record(groupedTabExtras)
        case (.action, .tap, .groupedTab, .closeGroupedTab, _):
            GleanMetrics.Tabs.groupedTabClosed.add()
        case (.action, .tap, .groupedTabPerformSearch, _, _):
            GleanMetrics.Tabs.groupedTabSearch.add()

        // MARK: Firefox Homepage
        case (.action, .view, .firefoxHomepage, .fxHomepageOrigin, let extras):
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.firefoxHomepageOrigin[homePageOrigin].add()
            }
        case (.action, .open, .firefoxHomepage, .openHomeFromAwesomebar, _):
            GleanMetrics.FirefoxHomePage.openFromAwesomebar.add()
        case (.action, .open, .firefoxHomepage, .openHomeFromPhotonMenuButton, _):
            GleanMetrics.FirefoxHomePage.openFromMenuHomeButton.add()

        case (.action, .view, .firefoxHomepage, .bookmarkItemView, let extras):
            if let bookmarksCount = extras?[EventObject.bookmarkImpressions.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.recentlySavedBookmarkView.record(GleanMetrics.FirefoxHomePage.RecentlySavedBookmarkViewExtra(bookmarkCount: bookmarksCount))
            }
        case (.action, .tap, .firefoxHomepage, .bookmarkSectionShowAll, let extras):
            GleanMetrics.FirefoxHomePage.recentlySavedShowAll.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.recentlySavedShowAllOrigin[homePageOrigin].add()
            }
        case (.action, .tap, .firefoxHomepage, .bookmarkItemAction, let extras):
            GleanMetrics.FirefoxHomePage.recentlySavedBookmarkItem.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.recentlySavedBookmarkOrigin[homePageOrigin].add()
            }
        case (.action, .tap, .firefoxHomepage, .jumpBackInSectionShowAll, let extras):
            GleanMetrics.FirefoxHomePage.jumpBackInShowAll.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.jumpBackInShowAllOrigin[homePageOrigin].add()
            }
        case (.action, .view, .jumpBackInTileImpressions, _, _):
            GleanMetrics.FirefoxHomePage.jumpBackInTileView.add()
        case (.action, .tap, .firefoxHomepage, .jumpBackInSectionTabOpened, let extras):
            GleanMetrics.FirefoxHomePage.jumpBackInTabOpened.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.jumpBackInTabOpenedOrigin[homePageOrigin].add()
            }
        case (.action, .tap, .firefoxHomepage, .jumpBackInSectionGroupOpened, let extras):
            GleanMetrics.FirefoxHomePage.jumpBackInGroupOpened.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.jumpBackInGroupOpenOrigin[homePageOrigin].add()
            }
        case (.action, .tap, .firefoxHomepage, .jumpBackInSectionSyncedTabShowAll, let extras):
            GleanMetrics.FirefoxHomePage.syncedTabShowAll.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.syncedTabShowAllOrigin[homePageOrigin].add()
            }
        case (.action, .tap, .firefoxHomepage, .jumpBackInSectionSyncedTabOpened, let extras):
            GleanMetrics.FirefoxHomePage.syncedTabOpened.add()
            if let homePageOrigin = extras?[EventExtraKey.fxHomepageOrigin.rawValue] as? String {
                GleanMetrics.FirefoxHomePage.syncedTabOpenedOrigin[homePageOrigin].add()
            }
        case (.action, .view, .syncedTabTileImpressions, _, _):
            GleanMetrics.FirefoxHomePage.syncedTabTileView.add()

        case (.action, .tap, .firefoxHomepage, .customizeHomepageButton, _):
            GleanMetrics.FirefoxHomePage.customizeHomepageButton.add()

        // MARK: - History Highlights
        case (.action, .tap, .firefoxHomepage, .historyHighlightsShowAll, _):
            GleanMetrics.FirefoxHomePage.historyHighlightsShowAll.add()
        case (.action, .tap, .firefoxHomepage, .historyHighlightsItemOpened, _):
            GleanMetrics.FirefoxHomePage.historyHighlightsItemOpened.record()
        case (.action, .tap, .firefoxHomepage, .historyHighlightsGroupOpen, _):
            GleanMetrics.FirefoxHomePage.historyHighlightsGroupOpen.record()
        case (.action, .view, .historyImpressions, _, _):
            GleanMetrics.FirefoxHomePage.historyImpressions.record()
        case (.action, .view, .historyHighlightContextualMenu, _, let extras):
            if let type = extras?[EventExtraKey.contextualMenuType.rawValue] as? String {
                let contextExtra = GleanMetrics.FirefoxHomePage.HistoryHighlightsContextExtra(type: type)
                GleanMetrics.FirefoxHomePage.historyHighlightsContext.record(contextExtra)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }

        // MARK: - Wallpaper related
        case (.action, .tap, .wallpaperSettings, .wallpaperSelected, let extras):
            if let name = extras?[EventExtraKey.wallpaperName.rawValue] as? String,
               let type = extras?[EventExtraKey.wallpaperType.rawValue] as? String {
                GleanMetrics.WallpaperAnalytics.wallpaperSelected.record(
                    GleanMetrics.WallpaperAnalytics.WallpaperSelectedExtra(
                        wallpaperName: name,
                        wallpaperType: type
                    )
                )
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }

        // MARK: - Contextual Hints
        case (.action, .tap, .contextualHint, .dismissCFRFromButton, let extras):
            if let hintType = extras?[EventExtraKey.cfrType.rawValue] as? String {
                GleanMetrics.CfrAnalytics.dismissCfrFromButton.record(
                    GleanMetrics.CfrAnalytics.DismissCfrFromButtonExtra(hintType: hintType))
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .contextualHint, .dismissCFRFromOutsideTap, let extras):
            if let hintType = extras?[EventExtraKey.cfrType.rawValue] as? String {
                GleanMetrics.CfrAnalytics.dismissCfrFromOutsideTap.record(
                    GleanMetrics.CfrAnalytics.DismissCfrFromOutsideTapExtra(hintType: hintType))
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case (.action, .tap, .contextualHint, .pressCFRActionButton, let extras):
            if let hintType = extras?[EventExtraKey.cfrType.rawValue] as? String {
                GleanMetrics.CfrAnalytics.pressCfrActionButton.record(
                    GleanMetrics.CfrAnalytics.PressCfrActionButtonExtra(hintType: hintType))
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        // MARK: - Sponsored Shortcuts
        case (.information, .view, .sponsoredShortcuts, _, let extras):
            if let enabled = extras?[EventExtraKey.preference.rawValue] as? Bool {
                GleanMetrics.TopSites.sponsoredShortcuts.set(enabled)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        // MARK: - Awesomebar
        case (.information, .view, .awesomebarLocation, _, let extras):
            if let location = extras?[EventExtraKey.preference.rawValue] as? String {
                let locationExtra = GleanMetrics.Awesomebar.LocationExtra(location: location)
                GleanMetrics.Awesomebar.location.record(locationExtra)
            } else {
                recordUninstrumentedMetrics(
                    category: category,
                    method: method,
                    object: object,
                    value: value,
                    extras: extras)
            }
        case (.action, .tap, .awesomebarLocation, .awesomebarShareTap, _):
            GleanMetrics.Awesomebar.shareButtonTapped.record()
        case (.action, .drag, .locationBar, _, _):
            GleanMetrics.Awesomebar.dragLocationBar.record()
        // MARK: - GleanPlumb Messaging
        case (.information, .view, .messaging, .messageImpression, let extras):
            guard let messageSurface = extras?[EventExtraKey.messageSurface.rawValue] as? String,
                  let messageId = extras?[EventExtraKey.messageKey.rawValue] as? String
            else { return }

            GleanMetrics.Messaging.shown.record(
                GleanMetrics.Messaging.ShownExtra(
                    messageKey: messageId,
                    messageSurface: messageSurface
                )
            )
        case(.action, .tap, .messaging, .messageDismissed, let extras):
            guard let messageSurface = extras?[EventExtraKey.messageSurface.rawValue] as? String,
                  let messageId = extras?[EventExtraKey.messageKey.rawValue] as? String
            else { return }

            GleanMetrics.Messaging.dismissed.record(
                GleanMetrics.Messaging.DismissedExtra(
                    messageKey: messageId,
                    messageSurface: messageSurface
                )
            )
        case(.action, .tap, .messaging, .messageInteracted, let extras):
            guard let messageSurface = extras?[EventExtraKey.messageSurface.rawValue] as? String,
                  let messageId = extras?[EventExtraKey.messageKey.rawValue] as? String
            else { return }

            if let actionUUID = extras?[EventExtraKey.actionUUID.rawValue] as? String {
                GleanMetrics.Messaging.clicked.record(
                    GleanMetrics.Messaging.ClickedExtra(
                        actionUuid: actionUUID,
                        messageKey: messageId,
                        messageSurface: messageSurface
                    )
                )
            } else {
                GleanMetrics.Messaging.clicked.record(
                    GleanMetrics.Messaging.ClickedExtra(
                        messageKey: messageId,
                        messageSurface: messageSurface
                    )
                )
            }
        case(.information, .view, .messaging, .messageExpired, let extras):
            guard let messageSurface = extras?[EventExtraKey.messageSurface.rawValue] as? String,
                  let messageId = extras?[EventExtraKey.messageKey.rawValue] as? String
            else { return }

            GleanMetrics.Messaging.expired.record(
                GleanMetrics.Messaging.ExpiredExtra(
                    messageKey: messageId,
                    messageSurface: messageSurface
                )
            )
        case(.information, .application, .messaging, .messageMalformed, let extras):
            guard let messageSurface = extras?[EventExtraKey.messageSurface.rawValue] as? String,
                  let messageId = extras?[EventExtraKey.messageKey.rawValue] as? String
            else { return }

            GleanMetrics.Messaging.malformed.record(
                GleanMetrics.Messaging.MalformedExtra(
                    messageKey: messageId,
                    messageSurface: messageSurface
                )
            )
        // MARK: - Share sheet actions
        case (.action, .tap, .shareSheet, .shareSendToDevice, _):
            GleanMetrics.ShareSheet.sendDeviceTapped.record()
        case (.action, .tap, .shareSheet, .sharePocketIcon, _):
            GleanMetrics.ShareSheet.pocketActionTapped.record()
        case (.action, .tap, .shareSheet, .shareSaveToPocket, _):
            GleanMetrics.ShareSheet.saveToPocketTapped.record()

        // MARK: - App Errors
        case(.information, .error, .app, .largeFileWrite, let extras):
            if let quantity = extras?[EventExtraKey.size.rawValue] as? Int32 {
                let properties = GleanMetrics.AppErrors.LargeFileWriteExtra(size: quantity)
                GleanMetrics.AppErrors.largeFileWrite.record(properties)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case(.information, .error, .app, .crashedLastLaunch, _):
            GleanMetrics.AppErrors.crashedLastLaunch.record()
        case(.information, .error, .app, .tabLossDetected, _):
            GleanMetrics.AppErrors.tabLossDetected.record()
        case(.information, .error, .app, .cpuException, let extras):
            if let quantity = extras?[EventExtraKey.size.rawValue] as? Int32 {
                let properties = GleanMetrics.AppErrors.CpuExceptionExtra(size: quantity)
                GleanMetrics.AppErrors.cpuException.record(properties)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }
        case(.information, .error, .app, .hangException, let extras):
            if let quantity = extras?[EventExtraKey.size.rawValue] as? Int32 {
                let properties = GleanMetrics.AppErrors.HangExceptionExtra(size: quantity)
                GleanMetrics.AppErrors.hangException.record(properties)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }

        // MARK: Webview
        case(.information, .error, .webview, .webviewFail, _):
            GleanMetrics.Webview.didFail.record()
        case(.information, .error, .webview, .webviewFailProvisional, _):
            GleanMetrics.Webview.didFailProvisional.record()
        case(.information, .error, .webview, .webviewShowErrorPage, let extras):
            if let errorCode = extras?[EventExtraKey.errorCode.rawValue] as? String {
                let errorCodeExtra = GleanMetrics.Webview.ShowErrorPageExtra(errorCode: errorCode)
                GleanMetrics.Webview.showErrorPage.record(errorCodeExtra)
            } else {
                recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }

        // MARK: - FX Suggest
        case(.action, .tap, .fxSuggest, _, let extras):
            guard let contextIdString = TelemetryContextualIdentifier.contextId,
                  let contextId = UUID(uuidString: contextIdString),
                  let telemetryInfo = extras?[EventValue.fxSuggestionTelemetryInfo.rawValue] as? RustFirefoxSuggestionTelemetryInfo,
                  let position = extras?[EventValue.fxSuggestionPosition.rawValue] as? Int else {
                return recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }

            // Record an event for this tap in the `events` ping.
            // These events include the `client_id`.
            let searchResultTapExtra = switch telemetryInfo {
            case .amp: GleanMetrics.Awesomebar.SearchResultTapExtra(type: "amp-suggestion")
            case .wikipedia: GleanMetrics.Awesomebar.SearchResultTapExtra(type: "wikipedia-suggestion")
            }
            GleanMetrics.Awesomebar.searchResultTap.record(searchResultTapExtra)

            // Submit a separate `fx-suggest` ping for this tap.
            // These pings do not include the `client_id`.
            GleanMetrics.FxSuggest.contextId.set(contextId)
            GleanMetrics.FxSuggest.pingType.set("fxsuggest-click")
            GleanMetrics.FxSuggest.isClicked.set(true)
            GleanMetrics.FxSuggest.position.set(Int64(position))
            switch telemetryInfo {
            case let .amp(blockId, advertiser, iabCategory, _, clickReportingURL):
                GleanMetrics.FxSuggest.blockId.set(blockId)
                GleanMetrics.FxSuggest.advertiser.set(advertiser)
                GleanMetrics.FxSuggest.iabCategory.set(iabCategory)
                if let clickReportingURL {
                    GleanMetrics.FxSuggest.reportingUrl.set(url: clickReportingURL)
                }
            case .wikipedia:
                GleanMetrics.FxSuggest.advertiser.set("wikipedia")
            }
            GleanMetrics.Pings.shared.fxSuggest.submit()

        case(.action, .view, .fxSuggest, _, let extras):
            guard let contextIdString = TelemetryContextualIdentifier.contextId,
                  let contextId = UUID(uuidString: contextIdString),
                  let telemetryInfo = extras?[EventValue.fxSuggestionTelemetryInfo.rawValue] as? RustFirefoxSuggestionTelemetryInfo,
                  let position = extras?[EventValue.fxSuggestionPosition.rawValue] as? Int,
                  let didTap = extras?[EventValue.fxSuggestionDidTap.rawValue] as? Bool,
                  let didAbandonSearchSession = extras?[EventValue.fxSuggestionDidAbandonSearchSession.rawValue] as? Bool else {
                return recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
            }

            // Record an event for this impression in the `events` ping.
            // These events include the `client_id`, and we record them for
            // engaged and abandoned search sessions.
            let searchResultImpressionExtra = switch telemetryInfo {
            case .amp: GleanMetrics.Awesomebar.SearchResultImpressionExtra(type: "amp-suggestion")
            case .wikipedia: GleanMetrics.Awesomebar.SearchResultImpressionExtra(type: "wikipedia-suggestion")
            }
            GleanMetrics.Awesomebar.searchResultImpression.record(searchResultImpressionExtra)

            // Submit a separate `fx-suggest` ping for this impression.
            // These pings do not include the `client_id`, and we only submit
            // them for engaged search sessions.
            if didAbandonSearchSession { break }
            GleanMetrics.FxSuggest.contextId.set(contextId)
            GleanMetrics.FxSuggest.pingType.set("fxsuggest-impression")
            GleanMetrics.FxSuggest.isClicked.set(didTap)
            GleanMetrics.FxSuggest.position.set(Int64(position))
            switch telemetryInfo {
            case let .amp(blockId, advertiser, iabCategory, impressionReportingURL, _):
                GleanMetrics.FxSuggest.blockId.set(blockId)
                GleanMetrics.FxSuggest.advertiser.set(advertiser)
                GleanMetrics.FxSuggest.iabCategory.set(iabCategory)
                if let impressionReportingURL {
                    GleanMetrics.FxSuggest.reportingUrl.set(url: impressionReportingURL)
                }
            case .wikipedia:
                GleanMetrics.FxSuggest.advertiser.set("wikipedia")
            }
            GleanMetrics.Pings.shared.fxSuggest.submit()

        // MARK: - Uninstrumented
        default:
            recordUninstrumentedMetrics(category: category, method: method, object: object, value: value, extras: extras)
        }
    }

    private static func recordUninstrumentedMetrics(
        category: EventCategory,
        method: EventMethod,
        object: EventObject,
        value: EventValue?,
        extras: [String: Any]?
    ) {
        DefaultLogger.shared.log("Uninstrumented metric recorded",
                                 level: .info,
                                 category: .lifecycle,
                                 description: "\(category), \(method), \(object), \(String(describing: value)), \(String(describing: extras))")
    }
}

// MARK: - Firefox Home Page
extension TelemetryWrapper {
    /// Bundle the extras dictionary for the home page origin
    static func getOriginExtras(isZeroSearch: Bool) -> [String: String] {
        let origin = isZeroSearch ? TelemetryWrapper.EventValue.fxHomepageOriginZeroSearch : TelemetryWrapper.EventValue.fxHomepageOriginOther
        return [TelemetryWrapper.EventExtraKey.fxHomepageOrigin.rawValue: origin.rawValue]
    }
}

// swiftlint:enable line_length
