// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

@MainActor
class DefaultBrowserUtility {
    let userDefault: UserDefaultsInterface
    let telemtryWrapper: TelemetryWrapperProtocol
    let locale: LocaleProvider
    let application: UIApplicationInterface
    let dmaCountries = ["BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR", "IT", "CY", "LV",
                        "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI", "SK", "FI", "SE", "GR", "JP"]

    private let logger: Logger

    init(
        userDefault: UserDefaultsInterface = UserDefaults.standard,
        telemetryWrapper: TelemetryWrapperProtocol = TelemetryWrapper.shared,
        locale: LocaleProvider = SystemLocaleProvider(),
        application: UIApplicationInterface = UIApplication.shared,
        logger: Logger = DefaultLogger.shared
    ) {
        self.userDefault = userDefault
        self.telemtryWrapper = telemetryWrapper
        self.locale = locale
        self.application = application
        self.logger = logger
    }

    struct UserDefaultsKey {
        public static let isBrowserDefault = "com.moz.isBrowserDefault.key"
        public static let shouldNotPerformMigration = "com.moz.shouldNotPerformMigration.key"
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
        guard let isDefault = try? application.isDefault(.webBrowser) else {
            logger.log(
                "UIApplicationInterface.isDefault was not present",
                level: .info,
                category: .setup
            )
            return
        }

        logger.log(
            "UIApplicationInterface.isDefault was successful",
            level: .info,
            category: .setup
        )
        trackIfUserIsDefault(isDefault)

        if isFirstRun {
            trackIfNewUserIsComingFromBrowserChoiceScreen(isDefault)

            if isDefault {
                isDefaultBrowser = true
            }
        }
    }

    private func isRunningOnBlockListBetaOS() -> Bool {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let betaBlockLists: [String] = ["22C5109p", "22C5125e", "22C5131e", "22C5142a"]

        return betaBlockLists.contains { systemVersion.contains($0) }
    }

    private func trackIfUserIsDefault(_ isDefault: Bool) {
        userDefault.set(isDefault, forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser)

        telemtryWrapper.recordEvent(category: .action,
                                    method: .open,
                                    object: .defaultBrowser,
                                    extras: [TelemetryWrapper.EventExtraKey.isDefaultBrowser.rawValue: isDefault])
    }

    private func trackIfNewUserIsComingFromBrowserChoiceScreen(_ isDefault: Bool) {
        guard let regionCode = locale.localeRegionCode else { return }
        // User is in a DMA effective region
        if dmaCountries.contains(regionCode) {
            let key = TelemetryWrapper.EventExtraKey.didComeFromBrowserChoiceScreen.rawValue
            telemtryWrapper.recordEvent(category: .action,
                                        method: .open,
                                        object: .choiceScreenAcquisition,
                                        extras: [key: isDefault])
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
}
