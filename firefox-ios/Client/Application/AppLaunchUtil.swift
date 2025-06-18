// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Account
import Glean
import MozillaAppServices

final class AppLaunchUtil {
    private var logger: Logger
//    private var adjustHelper: AdjustHelper
    private var profile: Profile
    private let introScreenManager: IntroScreenManager
    private let termsOfServiceManager: TermsOfServiceManager

    init(
        logger: Logger = DefaultLogger.shared,
        profile: Profile
    ) {
        self.logger = logger
        self.profile = profile
//        self.adjustHelper = AdjustHelper(profile: profile)
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        self.termsOfServiceManager = TermsOfServiceManager(prefs: profile.prefs)
    }

    func setUpPreLaunchDependencies() {
        // If the 'Save logs to Files app on next launch' toggle
        // is turned on in the Settings app, copy over old logs.
        if DebugSettingsBundleOptions.saveLogsToDocuments {
            logger.copyLogsToDocuments()
        }

        DefaultBrowserUtil().processUserDefaultState(isFirstRun: introScreenManager.shouldShowIntroScreen)

        // Need to get "settings.sendCrashReports" this way so that Sentry can be initialized before getting the Profile.
        let sendCrashReports = NSUserDefaultsPrefs(prefix: "profile").boolForKey(AppConstants.prefSendCrashReports) ?? true

        if termsOfServiceManager.isAffectedUser {
            logger.setup(sendCrashReports: sendCrashReports)
            TelemetryWrapper.shared.setup(profile: profile)
            TelemetryWrapper.shared.recordStartUpTelemetry()
        }

        if termsOfServiceManager.isFeatureEnabled {
            // Two cases:
            // 1. when ToS screen has been presented and user accepted it
            // 2. or when ToS screen is not presented because is not fresh install
            let isTermsOfServiceAccepted = termsOfServiceManager.isAccepted || !introScreenManager.shouldShowIntroScreen
            logger.setup(sendCrashReports: sendCrashReports && isTermsOfServiceAccepted)
            if isTermsOfServiceAccepted {
                TelemetryWrapper.shared.setup(profile: profile)
                TelemetryWrapper.shared.recordStartUpTelemetry()
            } else {
                // If ToS are not accepted, we still need to setup the Contextual Identifier for
                // the Unified Ads Sponsored tiles
                TelemetryContextualIdentifier.setupContextId(isGleanMetricsAllowed: false)
            }
        } else {
            logger.setup(sendCrashReports: sendCrashReports)
            TelemetryWrapper.shared.setup(profile: profile)
            TelemetryWrapper.shared.recordStartUpTelemetry()
        }

        setUserAgent()

        KeyboardHelper.defaultHelper.startObserving()

        setMenuItems()

        // Initialize conversion value by specifying fineValue and coarseValue.
        // Call update postback conversion value for install event.
        let conversionValue = ConversionValueUtil(fineValue: 0, coarseValue: .low, logger: logger)
        conversionValue.adNetworkAttributionUpdateConversionEvent()

        // Used by share extension to determine if the bookmarks refactor feature flag is enabled
        profile.prefs.setBool(LegacyFeatureFlagsManager.shared.isFeatureEnabled(.bookmarksRefactor,
                                                                                checking: .buildOnly),
                              forKey: PrefsKeys.IsBookmarksRefactorEnabled)

        // Initialize app services ( including NSS ). Must be called before any other calls to rust components.
        MozillaAppServices.initialize()

        // Start initializing the Nimbus SDK. This should be done after Glean
        // has been started.
        initializeExperiments()

        // We migrate history from browser db to places if it hasn't already
        DispatchQueue.global().async {
            self.runAppServicesHistoryMigration()
        }

        // Save toolbar position to user prefs
        SearchBarLocationSaver().saveUserSearchBarLocation(profile: profile)

        NotificationCenter.default.addObserver(
            forName: .FSReadingListAddReadingListItem,
            object: nil,
            queue: nil
        ) { (notification) in
            if let userInfo = notification.userInfo, let url = userInfo["URL"] as? URL {
                let title = (userInfo["Title"] as? String) ?? ""
                self.profile.readingList.createRecordWithURL(
                    url.absoluteString,
                    title: title,
                    addedBy: UIDevice.current.name
                )
            }
        }

        RustFirefoxAccounts.startup(prefs: profile.prefs) { _ in
            self.logger.log("RustFirefoxAccounts started", level: .info, category: .sync)
            AppEventQueue.signal(event: .accountManagerInitialized)
        }

        // Add swizzle on UIViewControllers to automatically log when there's a new view appearing or disappearing
        UIViewController.loggerSwizzle()

        // Add swizzle on top of UIControl to automatically log when there's an action sent
        UIControl.loggerSwizzle()

        logger.log("App version \(AppInfo.appVersion), Build number \(AppInfo.buildNumber)",
                   level: .debug,
                   category: .setup)

        AppEventQueue.signal(event: .preLaunchDependenciesComplete)
    }

    func setUpPostLaunchDependencies() {
        let persistedCurrentVersion = InstallType.persistedCurrentVersion()
        // upgrade install - Intro screen shown & persisted current version does not match
        if !introScreenManager.shouldShowIntroScreen && persistedCurrentVersion != AppInfo.appVersion {
            InstallType.set(type: .upgrade)
            InstallType.updateCurrentVersion(version: AppInfo.appVersion)
        }

        // We need to check if the app is a clean install to use for
        // preventing the What's New URL from appearing.
        if introScreenManager.shouldShowIntroScreen {
            // fresh install - Intro screen not yet shown
            InstallType.set(type: .fresh)
            InstallType.updateCurrentVersion(version: AppInfo.appVersion)

            // Profile setup
            profile.prefs.setString(AppInfo.appVersion, forKey: PrefsKeys.AppVersion.Latest)
            UserDefaults.standard.set(Date.now(), forKey: PrefsKeys.Session.FirstAppUse)
        } else if profile.prefs.boolForKey(PrefsKeys.KeySecondRun) == nil {
            profile.prefs.setBool(true, forKey: PrefsKeys.KeySecondRun)
        }

        updateSessionCount()
//        adjustHelper.setupAdjust()
        AppEventQueue.signal(event: .postLaunchDependenciesComplete)
    }

    private func setUserAgent() {
        // Record the user agent for use by search suggestion clients.
        SearchViewModel.userAgent = UserAgent.getUserAgent()
    }

    private func initializeExperiments() {
        Experiments.initialize()
    }

    private func updateSessionCount() {
        var sessionCount: Int32 = 0

        // Get the session count from preferences
        if let currentSessionCount = profile.prefs.intForKey(PrefsKeys.Session.Count) {
            sessionCount = currentSessionCount
        }
        // increase session count value
        profile.prefs.setInt(sessionCount + 1, forKey: PrefsKeys.Session.Count)
        UserDefaults.standard.set(Date.now(), forKey: PrefsKeys.Session.Last)
    }

    // MARK: - Application Services History Migration

    private func runAppServicesHistoryMigration() {
        let isFirstRun = introScreenManager.shouldShowIntroScreen

        // If this is a first run, there won't be history to migrate since we are far past v110
        guard !isFirstRun else {
            // Mark migration as succeeded and return early
            UserDefaults.standard.setValue(true, forKey: PrefsKeys.PlacesHistoryMigrationSucceeded)
            return
        }

        let browserProfile = self.profile as? BrowserProfile

        let migrationSucceeded = UserDefaults.standard.bool(forKey: PrefsKeys.PlacesHistoryMigrationSucceeded)
        let migrationAttemptNumber = UserDefaults.standard.integer(forKey: PrefsKeys.HistoryMigrationAttemptNumber)
        UserDefaults.standard.setValue(migrationAttemptNumber + 1, forKey: PrefsKeys.HistoryMigrationAttemptNumber)

        if !migrationSucceeded && migrationAttemptNumber < AppConstants.maxHistoryMigrationAttempt {
            HistoryTelemetry().attemptedApplicationServicesMigration()
            logger.log("Migrating Application Services history",
                       level: .info,
                       category: .sync)

            browserProfile?.migrateHistoryToPlaces(
                callback: { result in
                    self.logger.log("Successfully migrated history",
                                    level: .info,
                                    category: .sync,
                                    extra: ["durationSeconds": "\(result.totalDuration / 1000)"])

                    UserDefaults.standard.setValue(true, forKey: PrefsKeys.PlacesHistoryMigrationSucceeded)
                    NotificationCenter.default.post(name: .TopSitesUpdated, object: nil)
                },
                errCallback: { err in
                    let errDescription = err?.localizedDescription ?? "Unknown error during History migration"
                    self.logger.log("History migration failed",
                                    level: .fatal,
                                    category: .sync,
                                    extra: ["error": errDescription])
                }
            )
        } else {
            self.logger.log("History migration skipped",
                            level: .debug,
                            category: .sync)
        }
    }

    private func setMenuItems() {
        let webViewModel = MenuHelperWebViewModel(searchTitle: .MenuHelperSearchWithFirefox,
                                                  findInPageTitle: .MenuHelperFindInPage)
        let loginModel = MenuHelperLoginModel(revealPasswordTitle: .MenuHelperReveal,
                                              hidePasswordTitle: .MenuHelperHide,
                                              copyItemTitle: .MenuHelperCopy,
                                              openAndFillTitle: .MenuHelperOpenAndFill)
        let urlBarModel = MenuHelperURLBarModel(pasteAndGoTitle: .MenuHelperPasteAndGo)

        DefaultMenuHelper().setItems(webViewModel: webViewModel,
                                     loginModel: loginModel,
                                     urlBarModel: urlBarModel)
    }
}
