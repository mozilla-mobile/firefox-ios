// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import Account
import Glean

// A convinient mapping, `Profile.swift` can't depend
// on `PlacesMigrationConfiguration` directly since
// the FML is only usable from `Client` at the moment
extension PlacesMigrationConfiguration {
    func into() -> HistoryMigrationConfiguration {
        switch self {
        case .disabled:
            return .disabled
        case .dryRun:
            return .dryRun
        case .real:
            return .real
        }
    }
}

class AppLaunchUtil {

    private var log: RollingFileLogger
    private var adjustHelper: AdjustHelper
    private var profile: Profile

    init(log: RollingFileLogger = Logger.browserLogger,
         profile: Profile) {
        self.log = log
        self.profile = profile
        self.adjustHelper = AdjustHelper(profile: profile)
    }

    func setUpPreLaunchDependencies() {
        // If the 'Save logs to Files app on next launch' toggle
        // is turned on in the Settings app, copy over old logs.
        if DebugSettingsBundleOptions.saveLogsToDocuments {
            Logger.copyPreviousLogsToDocuments()
        }

        // Now roll logs.
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            Logger.syncLogger.deleteOldLogsDownToSizeLimit()
            Logger.browserLogger.deleteOldLogsDownToSizeLimit()
        }

        TelemetryWrapper.shared.setup(profile: profile)

        // Need to get "settings.sendUsageData" this way so that Sentry can be initialized
        // before getting the Profile.
        let sendUsageData = NSUserDefaultsPrefs(prefix: "profile").boolForKey(AppConstants.PrefSendUsageData) ?? true
        SentryIntegration.shared.setup(sendUsageData: sendUsageData)

        setUserAgent()

        KeyboardHelper.defaultHelper.startObserving()
        DynamicFontHelper.defaultHelper.startObserving()
        MenuHelper.defaultHelper.setItems()

        let logDate = Date()
        // Create a new sync log file on cold app launch. Note that this doesn't roll old logs.
        Logger.syncLogger.newLogWithDate(logDate)
        Logger.browserLogger.newLogWithDate(logDate)

        // Initialize the feature flag subsystem.
        // Among other things, it toggles on and off Nimbus, Contile, Adjust.
        // i.e. this must be run before initializing those systems.
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        FeatureFlagUserPrefsMigrationUtility(with: profile).attemptMigration()

        // Migrate wallpaper folder
        LegacyWallpaperMigrationUtility(with: profile).attemptMigration()
        WallpaperManager().migrateLegacyAssets()

        // Start initializing the Nimbus SDK. This should be done after Glean
        // has been started.
        initializeExperiments()

        NotificationCenter.default.addObserver(forName: .FSReadingListAddReadingListItem, object: nil, queue: nil) { (notification) -> Void in
            if let userInfo = notification.userInfo, let url = userInfo["URL"] as? URL {
                let title = (userInfo["Title"] as? String) ?? ""
                self.profile.readingList.createRecordWithURL(url.absoluteString, title: title, addedBy: UIDevice.current.name)
            }
        }

        SystemUtils.onFirstRun()

        RustFirefoxAccounts.startup(prefs: profile.prefs).uponQueue(.main) { _ in
            print("RustFirefoxAccounts started")
        }
    }

    func setUpPostLaunchDependencies() {

        let persistedCurrentVersion = InstallType.persistedCurrentVersion()
        let introScreen = profile.prefs.intForKey(PrefsKeys.IntroSeen)
        // upgrade install - Intro screen shown & persisted current version does not match
        if introScreen != nil && persistedCurrentVersion != AppInfo.appVersion {
            InstallType.set(type: .upgrade)
            InstallType.updateCurrentVersion(version: AppInfo.appVersion)
        }

        // We need to check if the app is a clean install to use for
        // preventing the What's New URL from appearing.
        if introScreen == nil {
            // fresh install - Intro screen not yet shown
            InstallType.set(type: .fresh)
            InstallType.updateCurrentVersion(version: AppInfo.appVersion)
            // Profile setup
            profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)

        } else if profile.prefs.boolForKey(PrefsKeys.KeySecondRun) == nil {
            profile.prefs.setBool(true, forKey: PrefsKeys.KeySecondRun)
        }

        updateSessionCount()
        adjustHelper.setupAdjust()
    }

    private func setUserAgent() {
        let firefoxUA = UserAgent.getUserAgent()

        // Record the user agent for use by search suggestion clients.
        SearchViewController.userAgent = firefoxUA

        // Some sites will only serve HTML that points to .ico files.
        // The FaviconFetcher is explicitly for getting high-res icons, so use the desktop user agent.
        FaviconFetcher.userAgent = UserAgent.desktopUserAgent()
    }

    private func initializeExperiments() {
        // We initialize the generated FxNimbus singleton very early on with a lazily
        // constructed singleton.
        FxNimbus.shared.initialize(with: { Experiments.shared })
        // We also make sure that any cache invalidation happens after each applyPendingExperiments().
        NotificationCenter.default.addObserver(forName: .nimbusExperimentsApplied, object: nil, queue: nil) { _ in
            FxNimbus.shared.invalidateCachedValues()
            self.runEarlyExperimentDependencies()
        }

        let defaults = UserDefaults.standard
        let nimbusFirstRun = "NimbusFirstRun"
        let isFirstRun = defaults.object(forKey: nimbusFirstRun) == nil
        defaults.set(false, forKey: nimbusFirstRun)
        Experiments.customTargetingAttributes =  ["isFirstRun": "\(isFirstRun)"]
        let initialExperiments = Bundle.main.url(forResource: "initial_experiments", withExtension: "json")
        let serverURL = Experiments.remoteSettingsURL
        let savedOptions = Experiments.getLocalExperimentData()
        let options: Experiments.InitializationOptions
        switch (savedOptions, isFirstRun, initialExperiments, serverURL) {
        // QA testing case: experiments come from the Experiments setting screen.
        case (let payload, _, _, _) where payload != nil:
            log.info("Nimbus: Loading from experiments provided by settings screen")
            options = Experiments.InitializationOptions.testing(localPayload: payload!)
        // First startup case:
        case (nil, true, let file, _) where file != nil:
            log.info("Nimbus: Loading from experiments from bundle, at first startup")
            options = Experiments.InitializationOptions.preload(fileUrl: file!)
        // Local development case: load from the bundled initial_experiments.json
        case (_, _, let file, let url) where file != nil && url == nil:
            log.info("Nimbus: Loading from experiments from bundle, with no URL")
            options = Experiments.InitializationOptions.preload(fileUrl: file!)
        case (_, _, _, let url) where url != nil:
            log.info("Nimbus: server exists")
            options = Experiments.InitializationOptions.normal
        default:
            log.info("Nimbus: server does not exist")
            options = Experiments.InitializationOptions.normal
        }

        Experiments.intialize(options)
    }

    private func updateSessionCount() {
        var sessionCount: Int32 = 0

        // Get the session count from preferences
        if let currentSessionCount = profile.prefs.intForKey(PrefsKeys.SessionCount) {
            sessionCount = currentSessionCount
        }
        // increase session count value
        profile.prefs.setInt(sessionCount + 1, forKey: PrefsKeys.SessionCount)
    }

    private func runEarlyExperimentDependencies() {
        runAppServicesHistoryMigration()
    }

    // MARK: - Application Services History Migration

    private func runAppServicesHistoryMigration() {
        let placesHistory = FxNimbus.shared.features.placesHistory.value()
        FxNimbus.shared.features.placesHistory.recordExposure()
        guard placesHistory.migration != .disabled else {
            log.info("Migration disabled, won't run migration")
            return
        }
        let browserProfile = self.profile as? BrowserProfile
        let migrationRanKey = "PlacesHistoryMigrationRan" + placesHistory.migration.rawValue
        let migrationRan = UserDefaults.standard.bool(forKey: migrationRanKey)
        UserDefaults.standard.setValue(true, forKey: migrationRanKey)
        if !migrationRan {
            log.info("Migrating Application services history")
            let id = GleanMetrics.PlacesHistoryMigration.duration.start()
            // We mark that the migration started
            // this will help us identify how often the migration starts, but never ends
            // additionally, we have a seperate metric for error rates
            GleanMetrics.PlacesHistoryMigration.migrationEndedRate.addToNumerator(1)
            GleanMetrics.PlacesHistoryMigration.migrationErrorRate.addToNumerator(1)
            browserProfile?.migrateHistoryToPlaces(
            migrationConfig: placesHistory.migration.into(),
            callback: { result in
                self.log.info("Successful Migration took \(result.totalDuration / 1000) seconds")
                // We record various success metrics here
                GleanMetrics.PlacesHistoryMigration.duration.stopAndAccumulate(id)
                GleanMetrics.PlacesHistoryMigration.numMigrated.set(Int64(result.numSucceeded))
                self.log.info("Migrated \(result.numSucceeded) entries")
                GleanMetrics.PlacesHistoryMigration.numToMigrate.set(Int64(result.numTotal))
                GleanMetrics.PlacesHistoryMigration.migrationEndedRate.addToDenominator(1)
            },
            errCallback: { err in
                let errDescription = err?.localizedDescription ?? "Unknown error during History migration"
                self.log.error(errDescription)

                GleanMetrics.PlacesHistoryMigration.duration.cancel(id)
                GleanMetrics.PlacesHistoryMigration.migrationEndedRate.addToDenominator(1)
                GleanMetrics.PlacesHistoryMigration.migrationErrorRate.addToDenominator(1)
                // We also send the error to sentry
                SentryIntegration.shared.sendWithStacktrace(message: "Error executing application services history migration", tag: SentryTag.rustPlaces, severity: .error, description: errDescription)
            })
        } else {
            log.info("History Migration skipped, already migrated")
        }
    }
}
