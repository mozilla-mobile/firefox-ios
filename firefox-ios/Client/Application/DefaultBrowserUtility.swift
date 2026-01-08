// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

@MainActor
class DefaultBrowserUtility {
    let userDefault: UserDefaultsInterface
    let telemetry: DefaultBrowserUtilityTelemetry
    let locale: LocaleProvider
    let application: UIApplicationInterface
    let dmaCountries = ["BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR", "IT", "CY", "LV",
                        "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI", "SK", "FI", "SE", "GR", "JP"]

    private let logger: Logger

    init(
        userDefault: UserDefaultsInterface = UserDefaults.standard,
        telemetry: DefaultBrowserUtilityTelemetry = DefaultBrowserUtilityTelemetry(),
        locale: LocaleProvider = SystemLocaleProvider(),
        application: UIApplicationInterface = UIApplication.shared,
        logger: Logger = DefaultLogger.shared
    ) {
        self.userDefault = userDefault
        self.telemetry = telemetry
        self.locale = locale
        self.application = application
        self.logger = logger
    }

    struct UserDefaultsKey {
        public static let isBrowserDefault = "com.moz.isBrowserDefault.key"
        public static let shouldNotPerformMigration = "com.moz.shouldNotPerformMigration.key"
        public static let retryDate = "com.moz.defaultBrowserAPIRetryDate.key"
        public static let apiQuery = "com.moz.defaultBrowserAPIQuery.key"
    }

    struct APIErrorDateKeys {
        static let retryDate = "UIApplicationCategoryDefaultRetryAvailabilityDateErrorKey"
        static let lastProvidedDate = "UIApplicationCategoryDefaultStatusLastProvidedDateErrorKey"
    }

    var isDefaultBrowser: Bool {
        get { userDefault.bool(forKey: UserDefaultsKey.isBrowserDefault) }
        set {
            logger.log(
                "Setting browser default status from \(self.isDefaultBrowser) to \(newValue)",
                level: .info,
                category: .setup
            )
            userDefault.set(newValue, forKey: UserDefaultsKey.isBrowserDefault)
        }
    }

    func processUserDefaultState(isFirstRun: Bool) {
        guard #available(iOS 18.2, *) else { return }

        guard !isRunningOnBlockListBetaOS() else {
            logger.log("Cannot run the isDefault since the device running a Beta on the block list",
                       level: .info,
                       category: .setup)
            return
        }

        logger.log(
            "Going to try UIApplicationInterface.isDefault",
            level: .info,
            category: .setup
        )

        do {
            trackNumberOfAPIQueries(forNewUsers: isFirstRun)
            let isDefault = try application.isDefault(.webBrowser)

            logger.log(
                "UIApplicationInterface.isDefault was successful",
                level: .info,
                category: .setup
            )
            trackIfUserIsDefault(isDefault)

            if isFirstRun {
                trackIfNewUserIsComingFromBrowserChoiceScreen(isDefault)
            }

            isDefaultBrowser = isDefault
        } catch let error as UIApplication.CategoryDefaultError {
            logger.log(
                "UIApplicationInterface.isDefault returned retry error: \(error.localizedDescription)",
                level: .info,
                category: .setup
            )

            let (retryDate, lastProvidedDate) = trackDatesForErrorReporting(error.userInfo)
            let apiQueryCount = userDefault.object(forKey: UserDefaultsKey.apiQuery) as? Int

            telemetry.recordDefaultBrowserAPIError(
                errorDescription: error.localizedDescription,
                retryDate: retryDate,
                lastProvidedDate: lastProvidedDate,
                apiQueryCount: apiQueryCount
            )
        } catch {
            logger.log(
                "UIApplicationInterface.isDefault was not present with error: \(error.localizedDescription)",
                level: .info,
                category: .setup
            )
        }
    }

    private func isRunningOnBlockListBetaOS() -> Bool {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let betaBlockLists: [String] = ["22C5109p", "22C5125e", "22C5131e", "22C5142a"]

        return betaBlockLists.contains { systemVersion.contains($0) }
    }

    private func trackIfUserIsDefault(_ isDefault: Bool) {
        userDefault.set(isDefault, forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser)
        telemetry.recordAppIsDefaultBrowser(isDefault)
    }

    private func trackIfNewUserIsComingFromBrowserChoiceScreen(_ isDefault: Bool) {
        // User is in a DMA effective region
        if dmaCountries.contains(locale.regionCode()) {
            telemetry.recordIsUserChoiceScreenAcquisition(isDefault)
        }
    }

    /// This function consolidates the two currently used states for determining
    /// whether we are the default browser, into a single state.
    func migrateDefaultBrowserStatusIfNeeded(isFirstRun: Bool) {
        // If this is the first run of the app, all of our information will be fresh,
        // and correct values will already be up to date, so no migration is required.
        if isFirstRun {
            userDefault.set(true, forKey: UserDefaultsKey.shouldNotPerformMigration)
            return
        }

        guard !userDefault.bool(forKey: UserDefaultsKey.shouldNotPerformMigration) else {
            logger.log(
                "Default browser status migration doesn't need to be performed",
                level: .info,
                category: .setup
            )
            return
        }

        // This comes from deeplinks
        let preAPIStatus = userDefault.bool(forKey: UserDefaultsKey.isBrowserDefault)
        // This comes from API OR the user having previously set the browser to true
        let postAPIStatus = userDefault.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage)

        logger.log(
            "Performing migration - current status info",
            level: .info,
            category: .setup,
            extra: [
                "currentDeeplink": "\(preAPIStatus)",
                "currentAPIOrUserSetToDefaultStatus": "\(postAPIStatus)"
            ]
        )

        // If either one of these statuses are true, meaning we have been set to default,
        // then we simply have to make sure that the source of truth has this value
        isDefaultBrowser = preAPIStatus || postAPIStatus

        userDefault.set(true, forKey: UserDefaultsKey.shouldNotPerformMigration)
    }

    // MARK: - API Tracking
    /// This tracks the number of times we've queried the `isDefault` API only for new
    /// users, in order to understand when the API returns an error. This number will only
    /// be sent when we receive the error.
    private func trackNumberOfAPIQueries(forNewUsers shouldStartTracking: Bool) {
        if shouldStartTracking {
            userDefault.set(1, forKey: UserDefaultsKey.apiQuery)
            return
        }

        // For existing users, if the key doesn't exist, do nothing
        guard let currentCount = userDefault.object(forKey: UserDefaultsKey.apiQuery) as? Int,
              userDefault.object(forKey: UserDefaultsKey.apiQuery) != nil
        else { return }

        userDefault.set(currentCount + 1, forKey: UserDefaultsKey.apiQuery)
    }

    private func trackDatesForErrorReporting(
        _ userInfoDict: [AnyHashable: Any]
    ) -> (retryDate: Date?, lastProvidedDate: Date?) {
        for (key, value) in userInfoDict {
            if let keyString = key as? String, let date = value as? Date {
                userDefault.set(date, forKey: keyString)
            }
        }

        let retryDate = userInfoDict[APIErrorDateKeys.retryDate] as? Date
        let lastProvidedDate = userInfoDict[APIErrorDateKeys.lastProvidedDate] as? Date

        return (retryDate, lastProvidedDate)
    }
}
