// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// New keys should follow the name: "[nameOfTheFeature]Key" written with camel case
public struct PrefsKeys {
    // When this pref is set (by the user) it overrides default behaviour which is just based on app locale.
    public static let KeyEnableChinaSyncService = "useChinaSyncService"
    public static let KeyLastRemoteTabSyncTime = "lastRemoteTabSyncTime"

    // Global sync state for rust sync manager
    public static let RustSyncManagerPersistedState = "rustSyncManagerPersistedStateKey"

    public static let KeyLastSyncFinishTime = "lastSyncFinishTime"
    public static let KeyDefaultHomePageURL = "KeyDefaultHomePageURL"
    public static let KeyNoImageModeStatus = "NoImageModeStatus"
    public static let KeyMailToOption = "MailToOption"
    public static let HasFocusInstalled = "HasFocusInstalled"
    public static let HasPocketInstalled = "HasPocketInstalled"
    public static let IntroSeen = "IntroViewControllerSeen"
    public static let TermsOfServiceAccepted = "TermsOfServiceAccepted"
    public static let HomePageTab = "HomePageTab"
    public static let HomeButtonHomePageURL = "HomeButtonHomepageURL"
    public static let NumberOfTopSiteRows = "NumberOfTopSiteRows"
    public static let LoginsSaveEnabled = "saveLogins"
    public static let LoginsShowShortcutMenuItem = "showLoginsInAppMenu"
    public static let KeyInstallSession = "installSessionNumber"
    public static let KeyDefaultBrowserCardShowType = "defaultBrowserCardShowType"
    public static let DidDismissDefaultBrowserMessage = "DidDismissDefaultBrowserCard"
    public static let KeyDidShowDefaultBrowserOnboarding = "didShowDefaultBrowserOnboarding"
    public static let ContextMenuShowLinkPreviews = "showLinkPreviews"
    public static let ShowClipboardBar = "showClipboardBar"
    public static let BlockOpeningExternalApps = "blockOpeningExternalApps"
    public static let NewTabCustomUrlPrefKey = "HomePageURLPref"
    public static let GoogleTopSiteAddedKey = "googleTopSiteAddedKey"
    public static let GoogleTopSiteHideKey = "googleTopSiteHideKey"
    public static let InstallType = "InstallType"
    public static let KeyCurrentInstallVersion = "KeyCurrentInstallVersion"
    public static let KeySecondRun = "SecondRun"
    public static let KeyAutofillCreditCardStatus = "KeyAutofillCreditCardStatus"
    public static let KeyAutofillAddressStatus = "KeyAutofillAddressStatus"
    public static let ReaderModeProfileKeyStyle = "readermode.style"

    // Only set if we get an actual response, no assumptions, nil otherwise
    public static let AppleConfirmedUserIsDefaultBrowser = "AppleConfirmedUserIsDefaultBrowser"

    public struct Session {
        public static let FirstAppUse = "firstAppUse"
        public static let Last = "lastSession"
        public static let Count = "sessionCount"
        public static let firstWeekAppOpenTimestamps = "firstWeekAppOpenTimestamps"
        public static let firstWeekSearchesTimestamps = "firstWeekSearchesTimestamps"
        public static let didUpdateConversionValue = "didUpdateConversionValue"
        public static let InternalURLUUID = "InternalURLUUID"
    }

    public struct AppVersion {
        public static let Latest = "latestAppVersion"
    }

    public struct Wallpapers {
        public static let MetadataLastCheckedDate = "WallpaperMetadataLastCheckedUserPrefsKey"
        public static let CurrentWallpaper = "CurrentWallpaperUserPrefsKey"
        public static let ThumbnailsAvailable = "ThumbnailsAvailableUserPrefsKey"
        public static let OnboardingSeenKey = "WallpaperOnboardingSeenKeyUserPrefsKey"

        public static let legacyAssetMigrationCheck = "legacyAssetMigrationCheckUserPrefsKey"
        public static let v1MigrationCheck = "v1MigrationCheckUserPrefsKey"
    }

    public struct Notifications {
        public static let SyncNotifications = "SyncNotificationsUserPrefsKey"
        public static let TipsAndFeaturesNotifications = "TipsAndFeaturesNotificationsUserPrefsKey"
    }

    // For ease of use, please list keys alphabetically.
    public struct FeatureFlags {
        public static let DebugSuffixKey = "DebugKey"
        public static let FirefoxSuggest = "FirefoxSuggest"
        public static let HistoryHighlightsSection = "HistoryHighlightsSectionUserPrefsKey"
        public static let InactiveTabs = "InactiveTabsUserPrefsKey"
        public static let JumpBackInSection = "JumpBackInSectionUserPrefsKey"
        public static let SearchBarPosition = "SearchBarPositionUsersPrefsKey"
        public static let SentFromFirefox = "SentFromFirefoxUserPrefsKey"
    }

    public struct SearchSettings {
        public static let showFirefoxBrowsingHistorySuggestions = "FirefoxSuggestBrowsingHistorySuggestions"
        public static let showFirefoxBookmarksSuggestions = "FirefoxSuggestBookmarksSuggestions"
        public static let showFirefoxSyncedTabsSuggestions = "FirefoxSuggestSyncedTabsSuggestions"
        public static let showFirefoxNonSponsoredSuggestions = "FirefoxSuggestShowNonSponsoredSuggestions"
        public static let showFirefoxSponsoredSuggestions = "FirefoxSuggestShowSponsoredSuggestions"
        public static let showPrivateModeFirefoxSuggestions = "ShowPrivateModeFirefoxSuggestionsKey"
        public static let showPrivateModeSearchSuggestions = "ShowPrivateModeSearchSuggestionsKey"
        public static let showSearchSuggestions = "FirefoxSuggestShowSearchSuggestions"
    }

    public struct RemoteSettings {
        public static let lastRemoteSettingsServiceSyncTimestamp =
        "LastRemoteSettingsServiceSyncTimestamp"
    }

    public struct Sync {
        public static let numberOfSyncedDevices = "numberOfSyncedDevicesKey"
        public static let signedInFxaAccount = "signedInFxaAccountKey"
    }

    public struct UserFeatureFlagPrefs {
        public static let ASPocketStories = "ASPocketStoriesUserPrefsKey"
        public static let BookmarksSection = "BookmarksSectionUserPrefsKey"
        public static let SponsoredShortcuts = "SponsoredShortcutsUserPrefsKey"
        public static let StartAtHome = "StartAtHomeUserPrefsKey"
        public static let TopSiteSection = "TopSitesUserPrefsKey"
        public static let TabsAndAddressBarAutoHide = "TabsAndAddressBarAutoHidePrefsKey"
    }

    // Firefox contextual hint
    public enum ContextualHints: String, CaseIterable {
        case dataClearanceKey = "ContextualHintDataClearance"
        case jumpBackinKey = "ContextualHintJumpBackin"
        case jumpBackInConfiguredKey = "JumpBackInConfigured"
        case jumpBackInSyncedTabKey = "ContextualHintJumpBackInSyncedTab"
        case jumpBackInSyncedTabConfiguredKey = "JumpBackInSyncedTabConfigured"
        case inactiveTabsKey = "ContextualHintInactiveTabs"
        case toolbarOnboardingKey = "ContextualHintToolbarOnboardingKey"
        case mainMenuKey = "MainMenuHintKey"
        case shoppingOnboardingKey = "ShoppingOnboardingCFRKey"
        case shoppingOnboardingCFRsCounterKey = "ShoppingOnboardingCFRsCounterKey"
        case navigationKey = "ContextualHintNavigation"
    }

    // Firefox settings
    public struct Settings {
        public static let closePrivateTabs = "ClosePrivateTabs"
        public static let sentFromFirefoxWhatsApp = "SentFromFirefoxWhatsApp"
    }

    // Activity Stream
    public static let KeyTopSitesCacheIsValid = "topSitesCacheIsValid"
    public static let KeyTopSitesCacheSize = "topSitesCacheSize"
    public static let KeyNewTab = "NewTabPrefKey"
    public static let ASLastInvalidation = "ASLastInvalidation"
    public static let KeyUseCustomSyncTokenServerOverride = "useCustomSyncTokenServerOverride"
    public static let KeyCustomSyncTokenServerOverride = "customSyncTokenServerOverride"
    public static let KeyUseCustomFxAContentServer = "useCustomFxAContentServer"
    public static let KeyUseReactFxA = "useReactFxA"
    public static let KeyCustomFxAContentServer = "customFxAContentServer"
    public static let UseStageServer = "useStageSyncService"
    public static let KeyFxALastCommandIndex = "FxALastCommandIndex"
    public static let KeyFxAHandledCommands = "FxAHandledCommands"
    public static let AppExtensionTelemetryOpenUrl = "AppExtensionTelemetryOpenUrl"
    public static let AppExtensionTelemetryEventArray = "AppExtensionTelemetryEvents"
    public static let KeyBlockPopups = "blockPopups"
    public static let AutoplayMediaKey = "autoplayMedia"

    // Tabs Tray
    public static let KeyTabDisplayOrder = "KeyTabDisplayOrderKey"
    public static let TabMigrationKey = "TabMigrationKey"
    public static let TabSyncEnabled = "sync.engine.tabs.enabled"

    // Widgetkit Key
    public static let WidgetKitSimpleTabKey = "WidgetKitSimpleTabKey"
    public static let WidgetKitSimpleTopTab = "WidgetKitSimpleTopTab"

    // Shopping Keys
    public static let Shopping2023EnableAds = "Shopping2023EnableAdsKey"
    public static let Shopping2023OptIn = "Shopping2023OptInKey"
    public static let Shopping2023OptInSeen = "Shopping2023OptInSeenKey"
    public static let Shopping2023ExplicitOptOut = "Shopping2023ExplicitOptOutKey"

    // WallpaperManager Keys - Legacy
    public static let WallpaperManagerCurrentWallpaperObject = "WallpaperManagerCurrentWallpaperObject"
    public static let WallpaperManagerCurrentWallpaperImage = "WallpaperManagerCurrentWallpaperImage"
    public static let WallpaperManagerCurrentWallpaperImageLandscape = "WallpaperManagerCurrentWallpaperImageLandscape"
    public static let WallpaperManagerLogoSwitchPreference = "WallpaperManagerLogoSwitchPreference"

    // Application Services migrated to Places DB Successfully
    public static let PlacesHistoryMigrationSucceeded = "PlacesHistoryMigrationSucceeded"

    // The number of times we have attempted the Application Services to Places DB migration
    public static let HistoryMigrationAttemptNumber = "HistoryMigrationAttemptNumber"

    // The last timestamp we polled FxA for missing send tabs
    public static let PollCommandsTimestamp = "PollCommandsTimestamp"

    // The last recorded CFR timestamp
    public static let FakespotLastCFRTimestamp = "FakespotLastCFRTimestamp"

    // Representing whether or not the last user session was private
    public static let LastSessionWasPrivate = "wasLastSessionPrivate"

    // Only used in unit tests to override the user's setting for nimbus features
    public static let NimbusUserEnabledFeatureTestsOverride = "NimbusUserEnabledFeatureTestsOverride"

    // Only used to force faster transition of tabs to the inactive state (10 seconds)
    public static let FasterInactiveTabsOverride = "FasterInactiveTabsOverride"

    // Only used to force showing the App Store review dialog for debugging purposes
    public static let ForceShowAppReviewPromptOverride = "ForceShowAppReviewPromptOverride"

    // Used to show splash screen only during first time on fresh install
    public static let splashScreenShownKey = "splashScreenShownKey"

    public static let PasswordGeneratorShown = "PasswordGeneratorShown"

    // Represents whether or not the user has seen the photon main menu once, at least.
    public static let PhotonMainMenuShown = "PhotonMainMenuShown"

    // The guid of the bookmark folder that was most recently created or saved to by the user.
    // Used to indicate where we should save the next bookmark by default.
    public static let RecentBookmarkFolder = "RecentBookmarkFolder"
    // Represents whether or not the bookmark refactor feature flag is enabled
    // Used in the share extension
    public static let IsBookmarksRefactorEnabled = "IsBookmarksRefactorEnabled"

    // The timestamp where the app was last opened as default browser
    public static let LastOpenedAsDefaultBrowser = "LastOpenedAsDefaultBrowser"

    public struct Usage {
        public static let profileId = "profileId"
    }
}

public protocol Prefs {
    func getBranchPrefix() -> String
    func branch(_ branch: String) -> Prefs
    func setTimestamp(_ value: Timestamp, forKey defaultName: String)
    func setLong(_ value: UInt64, forKey defaultName: String)
    func setLong(_ value: Int64, forKey defaultName: String)
    func setInt(_ value: Int32, forKey defaultName: String)
    func setString(_ value: String, forKey defaultName: String)
    func setBool(_ value: Bool, forKey defaultName: String)
    func setObject(_ value: Any?, forKey defaultName: String)
    func stringForKey(_ defaultName: String) -> String?
    func objectForKey<T: Any>(_ defaultName: String) -> T?
    func hasObjectForKey(_ defaultName: String) -> Bool
    func boolForKey(_ defaultName: String) -> Bool?
    func intForKey(_ defaultName: String) -> Int32?
    func timestampForKey(_ defaultName: String) -> Timestamp?
    func longForKey(_ defaultName: String) -> Int64?
    func unsignedLongForKey(_ defaultName: String) -> UInt64?
    func stringArrayForKey(_ defaultName: String) -> [String]?
    func arrayForKey(_ defaultName: String) -> [Any]?
    func dictionaryForKey(_ defaultName: String) -> [String: Any]?
    func removeObjectForKey(_ defaultName: String)
    func clearAll()
}

open class MockProfilePrefs: Prefs {
    let prefix: String

    open func getBranchPrefix() -> String {
        return self.prefix
    }

    // Public for testing.
    open var things = NSMutableDictionary()

    public init(things: NSMutableDictionary, prefix: String) {
        self.things = things
        self.prefix = prefix
    }

    public init() {
        self.prefix = ""
    }

    open func branch(_ branch: String) -> Prefs {
        return MockProfilePrefs(things: self.things, prefix: self.prefix + branch + ".")
    }

    private func name(_ name: String) -> String {
        return self.prefix + name
    }

    open func setTimestamp(_ value: Timestamp, forKey defaultName: String) {
        self.setLong(value, forKey: defaultName)
    }

    open func setLong(_ value: UInt64, forKey defaultName: String) {
        setObject(NSNumber(value: value as UInt64), forKey: defaultName)
    }

    open func setLong(_ value: Int64, forKey defaultName: String) {
        setObject(NSNumber(value: value as Int64), forKey: defaultName)
    }

    open func setInt(_ value: Int32, forKey defaultName: String) {
        things[name(defaultName)] = NSNumber(value: value as Int32)
    }

    open func setString(_ value: String, forKey defaultName: String) {
        things[name(defaultName)] = value
    }

    open func setBool(_ value: Bool, forKey defaultName: String) {
        things[name(defaultName)] = value
    }

    open func setObject(_ value: Any?, forKey defaultName: String) {
        things[name(defaultName)] = value
    }

    open func stringForKey(_ defaultName: String) -> String? {
        return things[name(defaultName)] as? String
    }

    open func boolForKey(_ defaultName: String) -> Bool? {
        return things[name(defaultName)] as? Bool
    }

    open func objectForKey<T: Any>(_ defaultName: String) -> T? {
        return things[name(defaultName)] as? T
    }

    open func hasObjectForKey(_ defaultName: String) -> Bool {
        return (things[name(defaultName)] != nil)
    }

    open func timestampForKey(_ defaultName: String) -> Timestamp? {
        return unsignedLongForKey(defaultName)
    }

    open func unsignedLongForKey(_ defaultName: String) -> UInt64? {
        return things[name(defaultName)] as? UInt64
    }

    open func longForKey(_ defaultName: String) -> Int64? {
        return things[name(defaultName)] as? Int64
    }

    open func intForKey(_ defaultName: String) -> Int32? {
        return things[name(defaultName)] as? Int32
    }

    open func stringArrayForKey(_ defaultName: String) -> [String]? {
        if let arr = self.arrayForKey(defaultName) {
            if let arr = arr as? [String] {
                return arr
            }
        }
        return nil
    }

    open func arrayForKey(_ defaultName: String) -> [Any]? {
        let r: Any? = things.object(forKey: name(defaultName)) as Any?
        if r == nil {
            return nil
        }
        if let arr = r as? [Any] {
            return arr
        }
        return nil
    }

    open func dictionaryForKey(_ defaultName: String) -> [String: Any]? {
        return things.object(forKey: name(defaultName)) as? [String: Any]
    }

    open func removeObjectForKey(_ defaultName: String) {
        self.things.removeObject(forKey: name(defaultName))
    }

    open func clearAll() {
        guard let dictionary = things as? [String: Any] else { return }
        let keysToDelete: [String] = dictionary.keys.filter { $0.hasPrefix(self.prefix) }
        things.removeObjects(forKeys: keysToDelete)
    }
}
