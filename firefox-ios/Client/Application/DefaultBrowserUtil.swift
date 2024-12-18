// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

struct DefaultBrowserUtil {
    let userDefault: UserDefaultsInterface
    let telemtryWrapper: TelemetryWrapperProtocol
    let locale: LocaleInterface
    let application: UIApplicationInterface
    let dmaCountries = ["BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR", "IT", "CY", "LV",
                        "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI", "SK", "FI", "SE", "GR"]
    private let logger: Logger
    init(userDefault: UserDefaultsInterface = UserDefaults.standard,
         telemetryWrapper: TelemetryWrapperProtocol = TelemetryWrapper.shared,
         locale: LocaleInterface = Locale.current,
         application: UIApplicationInterface = UIApplication.shared,
         logger: Logger = DefaultLogger.shared) {
        self.userDefault = userDefault
        self.telemtryWrapper = telemetryWrapper
        self.locale = locale
        self.application = application
        self.logger = logger
    }

    func processUserDefaultState(isFirstRun: Bool) {
        guard #available(iOS 18.2, *) else { return }

        guard !isRunningOnBlockListBetaOS() else {
            logger.log("Cannot run the isDefault since the device running a Beta on the block list",
                       level: .info,
                       category: .setup)
            return
        }

        logger.log("Going to try UIApplicationInterface.isDefault", level: .info, category: .setup)
        guard let isDefault = try? application.isDefault(.webBrowser) else {
            logger.log("UIApplicationInterface.isDefault was not present", level: .info, category: .setup)
            return
        }

        logger.log("UIApplicationInterface.isDefault was successful", level: .info, category: .setup)
        trackIfUserIsDefault(isDefault)

        if isFirstRun {
            trackIfNewUserIsComingFromBrowserChoiceScreen(isDefault)

            if isDefault {
                // If the user is set to default don't ask on the home page later
                // This is temporary until we can refactor set to default flows now that we have the ability to check
                userDefault.set(true, forKey: PrefsKeys.DidDismissDefaultBrowserMessage)
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
}
