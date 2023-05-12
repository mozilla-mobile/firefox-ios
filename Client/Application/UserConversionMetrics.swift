// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import StoreKit

class UserConversionMetrics {
    private static var appOpenTimestamps: [Date] {
        get { return UserDefaults.standard.array(forKey: "appOpenTimestamps") as? [Date] ?? [Date]() }
        set { UserDefaults.standard.set(newValue, forKey: "appOpenTimestamps") }
    }

    private static var searchesTimestamps: [Date] {
        get { return UserDefaults.standard.array(forKey: "searchesTimestamps") as? [Date] ?? [Date]() }
        set { UserDefaults.standard.set(newValue, forKey: "searchesTimestamps") }
    }

    public static func didStartNewSession() {
        UserConversionMetrics.appOpenTimestamps.append(Date())
        UserConversionMetrics.checkProfileActivation()
    }

    public static func didPerformSearch() {
        UserConversionMetrics.searchesTimestamps.append(Date())
        UserConversionMetrics.checkProfileActivation()
    }

    private static func checkProfileActivation() {
        guard let firstAppUse = UserDefaults.standard.object(forKey: PrefsKeys.Session.FirstAppUse) as? UInt64 else {
            return
        }
        let firstAppUseDate = Date.fromTimestamp(firstAppUse)
        let oneWeekSinceFirstUse = Calendar.current.date(byAdding: .day, value: 7, to: firstAppUseDate)!

        let appOpenInWeek = self.appOpenTimestamps.filter { $0 < oneWeekSinceFirstUse }
        let distinctDaysOpened = Set(appOpenInWeek.map { Calendar.current.startOfDay(for: $0) }).count

        // last three days of the first week of usage
        let searchInLastThreeDays = self.searchesTimestamps.filter { $0 > Calendar.current.date(byAdding: .day, value: -3, to: oneWeekSinceFirstUse)! }

        if distinctDaysOpened >= 3 && !searchInLastThreeDays.isEmpty {
            UserConversionMetrics.adNetworkUpdateActivationConversionEvent()
            UserDefaults.standard.setValue(true, forKey: "didUpdateConversionValue")
        }
    }
    private static func adNetworkUpdateActivationConversionEvent() {
        if #available(iOS 16.1, *) {
            SKAdNetwork.updatePostbackConversionValue(1, coarseValue: .low) { error in
                UserConversionMetrics.handleUpdateConversionInstallEvent(error: error)
            }
        } else if #available(iOS 15.4, *) {
            SKAdNetwork.updatePostbackConversionValue(1) { error in
                UserConversionMetrics.handleUpdateConversionInstallEvent(error: error)
            }
        } else {
            SKAdNetwork.updateConversionValue(1)
        }
    }

    private static func handleUpdateConversionInstallEvent(error: Error?) {
        let logger: Logger = DefaultLogger.shared
        if let error = error {
            logger.log("Postback Conversion Install Error",
                       level: .warning,
                       category: .setup,
                       description: "Update conversion value failed with error - \(error.localizedDescription)")
        } else {
            logger.log("Update install conversion success",
                       level: .debug,
                       category: .setup,
                       description: "Update conversion value was successful for Install Event")
        }
    }
}
