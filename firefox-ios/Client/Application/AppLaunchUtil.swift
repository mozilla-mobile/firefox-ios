// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage
import Account
import Glean

class AppLaunchUtil {
    private var logger: Logger
//    private var adjustHelper: AdjustHelper
    private var profile: Profile
    private let introScreenManager: IntroScreenManager

    init(logger: Logger = DefaultLogger.shared,
         profile: Profile) {
        self.logger = logger
        self.profile = profile
//        self.adjustHelper = AdjustHelper(profile: profile)
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
    }

    func setUpPreLaunchDependencies() {
        // If the 'Save logs to Files app on next launch' toggle
        // is turned on in the Settings app, copy over old logs.
        if DebugSettingsBundleOptions.saveLogsToDocuments {
            logger.copyLogsToDocuments()
        }

        DefaultBrowserUtil().processUserDefaultState(isFirstRun: introScreenManager.shouldShowIntroScreen)

        TelemetryWrapper.shared.setup(profile: profile)
        recordStartUpTelemetry()

        // Need to get "settings.sendUsageData" this way so that Sentry can be initialized before getting the Profile.
        let sendUsageData = NSUserDefaultsPrefs(prefix: "profile").boolForKey(AppConstants.prefSendUsageData) ?? true
        logger.setup(sendUsageData: sendUsageData)

        setUserAgent()

        KeyboardHelper.defaultHelper.startObserving()
        LegacyDynamicFontHelper.defaultHelper.startObserving()

        setMenuItems()

        // Initialize conversion value by specifying fineValue and coarseValue.
        // Call update postback conversion value for install event.
        let conversionValue = ConversionValueUtil(fineValue: 0, coarseValue: .low, logger: logger)
        conversionValue.adNetworkAttributionUpdateConversionEvent()

        // Initialize the feature flag subsystem.
        // Among other things, it toggles on and off Nimbus, Contile, Adjust.
        // i.e. this must be run before initializing those systems.
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)

        // Start initializing the Nimbus SDK. This should be done after Glean
        // has been started.
        initializeExperiments()

        // We migrate history from browser db to places if it hasn't already
        DispatchQueue.global().async {
            self.runAppServicesHistoryMigration()
        }

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

        // Add swizzle on UIViewControllers to automatically log when there's a new view showing
        UIViewController.loggerSwizzle()

        // Add swizzle on top of UIControl to automatically log when there's an action sent
        UIControl.loggerSwizzle()

        logger.log("App version \(AppInfo.appVersion), Build number \(AppInfo.buildNumber)",
                   level: .debug,
                   category: .setup)

        logger.log("Prefs for migration is \(String(describing: profile.prefs.boolForKey(PrefsKeys.TabMigrationKey)))",
                   level: .debug,
                   category: .tabs)
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
        Experiments.intialize()
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
        let conversionMetrics = UserConversionMetrics()
        conversionMetrics.didStartNewSession()
    }

    // MARK: - Application Services History Migration

    private func runAppServicesHistoryMigration() {
        let browserProfile = self.profile as? BrowserProfile

        let migrationSucceeded = UserDefaults.standard.bool(forKey: PrefsKeys.PlacesHistoryMigrationSucceeded)
        let migrationAttemptNumber = UserDefaults.standard.integer(forKey: PrefsKeys.HistoryMigrationAttemptNumber)
        UserDefaults.standard.setValue(migrationAttemptNumber + 1, forKey: PrefsKeys.HistoryMigrationAttemptNumber)
        if !migrationSucceeded && migrationAttemptNumber < AppConstants.maxHistoryMigrationAttempt {
            logger.log("Migrating Application services history",
                       level: .info,
                       category: .sync)
            let id = GleanMetrics.PlacesHistoryMigration.duration.start()
            // We mark that the migration started
            // this will help us identify how often the migration starts, but never ends
            // additionally, we have a separate metric for error rates
            GleanMetrics.PlacesHistoryMigration.migrationEndedRate.addToNumerator(1)
            GleanMetrics.PlacesHistoryMigration.migrationErrorRate.addToNumerator(1)
            browserProfile?.migrateHistoryToPlaces(
            callback: { result in
                self.logger.log("Successful Migration took \(result.totalDuration / 1000) seconds",
                                level: .info,
                                category: .sync)
                // We record various success metrics here
                GleanMetrics.PlacesHistoryMigration.duration.stopAndAccumulate(id)
                GleanMetrics.PlacesHistoryMigration.numMigrated.set(Int64(result.numSucceeded))
                self.logger.log("Migrated \(result.numSucceeded) entries",
                                level: .info,
                                category: .sync)
                GleanMetrics.PlacesHistoryMigration.numToMigrate.set(Int64(result.numTotal))
                GleanMetrics.PlacesHistoryMigration.migrationEndedRate.addToDenominator(1)
                UserDefaults.standard.setValue(true, forKey: PrefsKeys.PlacesHistoryMigrationSucceeded)
                NotificationCenter.default.post(name: .TopSitesUpdated, object: nil)
            },
            errCallback: { err in
                let errDescription = err?.localizedDescription ?? "Unknown error during History migration"
                self.logger.log("Migration failed with \(errDescription)",
                                level: .warning,
                                category: .sync)

                GleanMetrics.PlacesHistoryMigration.duration.cancel(id)
                GleanMetrics.PlacesHistoryMigration.migrationEndedRate.addToDenominator(1)
                GleanMetrics.PlacesHistoryMigration.migrationErrorRate.addToDenominator(1)
            })
        } else {
            self.logger.log("History Migration skipped",
                            level: .debug,
                            category: .sync)
        }
    }

    private func recordStartUpTelemetry() {
        let isEnabled: Bool = (profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.SponsoredShortcuts) ?? true) &&
                               (profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.TopSiteSection) ?? true)
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .sponsoredShortcuts,
                                     extras: [TelemetryWrapper.EventExtraKey.preference.rawValue: isEnabled])

        if logger.crashedLastLaunch {
            TelemetryWrapper.recordEvent(category: .information,
                                         method: .error,
                                         object: .app,
                                         value: .crashedLastLaunch)
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
