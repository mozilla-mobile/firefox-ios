// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

/* A utility for tracking the state of whether or not we're the default browser.

 The main public interface is `processUserDefaultState(isFirstRun:)`. Its flow:

 1. iOS 18.2+ check
 └─ Exit early API not available and we rely on deeplinks & others for the state
 2. Expire stale status one month after we last set `isDefaultBrowser` to `true`
 └─ If isDefaultBrowser == true AND defaultBrowserSetDate > 1mo then Set isDefaultBrowser = false
 3. Beta blocklist check
 └─ Exit if on blocklisted beta OS
 4. Should we query Apple API?
 (see decision tree below)
 └─ Exit if `false`
 5. Call Apple's isDefault(.webBrowser)
 └─ Record `appleAPILastUseDate` so we can make sure to check at least every 3 months
 └─ On success: update isDefaultBrowser with value
 └─ On error: record telemetry + dates

 - Apple API Query Decision Tree (`shouldQueryAppleDefaultBrowserAPI()`)

 ┌─ Never used API before? (no appleAPILastUseDate)
 │  └─ YES -> Query API
 │  * Basically, first time using the API
 │
 ├─ Not past Apple's retry date from previous error?
 │  └─ YES -> Skip API
 │  * Apple told us to wait till the retry date
 │
 ├─ Been 3+ months since last API use?
 │  └─ YES -> Query API
 │  * Refresh with the API at least every 3 months
 │
 ├─ Set as default within last month?
 │  └─ YES -> Skip API
 │  * We're generally confident we're default from deeplinks/other
 │
 └─ Otherwise -> Skip API

 - Status Expiration Logic

 When processUserDefaultState runs, it first checks if the current `isDefaultBrowser = true`
 status is stale (if isDefaultBrowser == true AND it's been more than 1 month since
 defaultBrowserSetDate), and then it sets `isDefaultBrowser` to `false`, to ensure we don't
 indefinitely claim default status without re-verification. This is a rolling expration,
 so, even though it checks all the time, technically, if we set `isDefaultBrowser` to `true`
 through deeplinks or other means frequently enough, then we never actually expire.
 */
@MainActor
class DefaultBrowserUtility {
    let userDefault: UserDefaultsInterface
    let telemetry: DefaultBrowserUtilityTelemetry
    let locale: LocaleProvider
    let application: UIApplicationInterface
    let dmaCountries = ["BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR", "IT", "CY", "LV",
                        "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI", "SK", "FI", "SE", "GR", "JP"]

    private let logger: Logger

    struct UserDefaultsKey {
        public static let isBrowserDefault = "com.moz.isBrowserDefault.key"
        public static let shouldNotPerformMigration = "com.moz.shouldNotPerformMigration.key"
        public static let retryDate = "com.moz.defaultBrowserAPIRetryDate.key"
        public static let apiQuery = "com.moz.defaultBrowserAPIQuery.key"
        public static let defaultBrowserSetDate = "com.moz.defaultBrowserSetDate.key"
        public static let appleAPILastUseDate = "com.moz.appleDefaultBrowerAPILastUseDate.key"
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
            telemetry.recordAppIsDefaultBrowser(newValue)
            if newValue { defaultBrowserSetDate = Date() }
        }
    }

    private var defaultBrowserSetDate: Date? {
        get { userDefault.object(forKey: UserDefaultsKey.defaultBrowserSetDate) as? Date }
        set { userDefault.set(newValue, forKey: UserDefaultsKey.defaultBrowserSetDate) }
    }

    private var appleAPILastUseDate: Date? {
        get { userDefault.object(forKey: UserDefaultsKey.appleAPILastUseDate) as? Date }
        set { userDefault.set(newValue, forKey: UserDefaultsKey.appleAPILastUseDate) }
    }

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

    func processUserDefaultState(isFirstRun: Bool) {
        guard #available(iOS 18.2, *) else { return }

        expireDefaultStatusIfStale()

        guard !isRunningOnBlockListBetaOS() else {
            logger.log("Cannot run the isDefault since the device running a Beta on the block list",
                       level: .info,
                       category: .setup)
            return
        }

        guard shouldQueryAppleDefaultBrowserAPI() else {
            logger.log("Skipping isDefault API call based on timing conditions",
                       level: .info,
                       category: .setup)
            return
        }

        do {
            try performAPICheck(isFirstRun: isFirstRun)
        } catch {
            handleAPICheckError(error)
        }
    }

    private func isRunningOnBlockListBetaOS() -> Bool {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let betaBlockLists: [String] = ["22C5109p", "22C5125e", "22C5131e", "22C5142a"]

        return betaBlockLists.contains { systemVersion.contains($0) }
    }

    private func performAPICheck(isFirstRun: Bool) throws {
        guard #available(iOS 18.2, *) else { return }

        logger.log(
            "Going to try UIApplicationInterface.isDefault",
            level: .info,
            category: .setup
        )

        trackNumberOfAPIQueries(forNewUsers: isFirstRun)
        let isDefault = try application.isDefault(.webBrowser)
        appleAPILastUseDate = Date()

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
    }

    private func handleAPICheckError(_ error: Error) {
        guard #available(iOS 18.2, *) else { return }

        if let categoryError = error as? UIApplication.CategoryDefaultError {
            logger.log(
                "UIApplicationInterface.isDefault returned retry error: \(categoryError.localizedDescription)",
                level: .info,
                category: .setup
            )

            let (retryDate, lastProvidedDate) = trackDatesForErrorReporting(categoryError.userInfo)
            let apiQueryCount = userDefault.object(forKey: UserDefaultsKey.apiQuery) as? Int

            telemetry.recordDefaultBrowserAPIError(
                errorDescription: categoryError.localizedDescription,
                retryDate: retryDate,
                lastProvidedDate: lastProvidedDate,
                apiQueryCount: apiQueryCount
            )
        } else {
            logger.log(
                "UIApplicationInterface.isDefault was not present with error: \(error.localizedDescription)",
                level: .info,
                category: .setup
            )
        }
    }

    private func trackIfUserIsDefault(_ isDefault: Bool) {
        userDefault.set(isDefault, forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser)
    }

    private func trackIfNewUserIsComingFromBrowserChoiceScreen(_ isDefault: Bool) {
        // User is in a DMA effective region
        if dmaCountries.contains(locale.regionCode()) {
            telemetry.recordIsUserChoiceScreenAcquisition(isDefault)
        }
    }

    // MARK: - Migration

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

    // MARK: - Default Browser Status Management

    private func expireDefaultStatusIfStale() {
        if isDefaultBrowser && !wasSetAsDefaultWithinLastMonth() {
            isDefaultBrowser = false
        }
    }

    private func shouldQueryAppleDefaultBrowserAPI() -> Bool {
        let hasLastUseDate = appleAPILastUseDate != nil

        if !hasLastUseDate { return true }
        if !isPastRetryDate() { return false }
        if hasBeenAtLeastThreeMonthsSinceLastAPIUse() { return true }
        if wasSetAsDefaultWithinLastMonth() { return false }

        return false
    }

    private func wasSetAsDefaultWithinLastMonth() -> Bool {
        guard let setDate = defaultBrowserSetDate,
              let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        else { return false }

        return setDate > oneMonthAgo
    }

    private func hasBeenAtLeastThreeMonthsSinceLastAPIUse() -> Bool {
        guard let lastUseDate = appleAPILastUseDate,
              let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        else { return true }

        return lastUseDate < threeMonthsAgo
    }

    private func isPastRetryDate() -> Bool {
        guard let retryDate = userDefault.object(forKey: APIErrorDateKeys.retryDate) as? Date else {
            return true
        }
        return Date() > retryDate
    }
}
