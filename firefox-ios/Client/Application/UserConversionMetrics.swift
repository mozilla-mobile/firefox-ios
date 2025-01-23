// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import StoreKit

class UserConversionMetrics {
    private var appOpenTimestamps: [Date] {
        get { return userDefaults.array(forKey: PrefsKeys.Session.firstWeekAppOpenTimestamps) as? [Date] ?? [Date]() }
        set { userDefaults.set(newValue, forKey: PrefsKeys.Session.firstWeekAppOpenTimestamps) }
    }

    private var searchesTimestamps: [Date] {
        get { return userDefaults.array(forKey: PrefsKeys.Session.firstWeekSearchesTimestamps) as? [Date] ?? [Date]() }
        set { userDefaults.set(newValue, forKey: PrefsKeys.Session.firstWeekSearchesTimestamps) }
    }
    var userDefaults: UserDefaultsInterface = UserDefaults.standard

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func didStartNewSession() {
        guard shouldRecordMetric() else { return }
        appOpenTimestamps.append(Date())
        if shouldActivateProfile() {
            sendActivationEvent()
        }
    }

    func didPerformSearch() {
        guard shouldRecordMetric() else { return }
        searchesTimestamps.append(Date())
        if shouldActivateProfile() {
            sendActivationEvent()
        }
    }

    /// there shouldn't be more records added to UserDefaults once this event happens
    /// and it should not affect existing users
    func shouldRecordMetric() -> Bool {
        guard let firstAppUse = userDefaults.object(forKey: PrefsKeys.Session.FirstAppUse) as? UInt64,
              !userDefaults.bool(forKey: PrefsKeys.Session.didUpdateConversionValue) else { return false }

        let firstAppUseDate = Date.fromTimestamp(firstAppUse)
        guard let oneWeekSinceFirstUse = Calendar.current.date(
            byAdding: .day,
            value: 7,
            to: firstAppUseDate
        ) else { return false }
        if Date() > oneWeekSinceFirstUse {
            return false
        }
        return true
    }

///    The criteria for this event is:
///    * The user needs to open the app on at least 3 distinct days during their first week (days 1-7)
///    * Perform at least one search between days 4-7
    func shouldActivateProfile() -> Bool {
        guard let firstAppUse = userDefaults.object(forKey: PrefsKeys.Session.FirstAppUse) as? UInt64 else {
            return false
        }
        let firstAppUseDate = Date.fromTimestamp(firstAppUse)
        if let oneWeekSinceFirstUse = Calendar.current.date(byAdding: .day, value: 7, to: firstAppUseDate),
            let lastThreeDaysOfFirstWeek = Calendar.current.date(byAdding: .day, value: -3, to: oneWeekSinceFirstUse) {
            let appOpensInWeek = appOpenTimestamps.filter { $0 < oneWeekSinceFirstUse }
            let distinctDaysOpened = Set(appOpensInWeek.map { Calendar.current.startOfDay(for: $0) }).count

            // last three days of the first week of usage
            let searchInLastThreeDays = searchesTimestamps.filter {
                $0 > lastThreeDaysOfFirstWeek && $0 < oneWeekSinceFirstUse
            }
            let shouldActivateProfile = distinctDaysOpened >= 3 && !searchInLastThreeDays.isEmpty
            return shouldActivateProfile
        } else {
            return false
        }
    }

    private func sendActivationEvent() {
        let logger: Logger = DefaultLogger.shared
        let conversionValue = ConversionValueUtil(fineValue: 0, coarseValue: .high, logger: logger)
        conversionValue.adNetworkAttributionUpdateConversionEvent()
        userDefaults.set(true, forKey: PrefsKeys.Session.didUpdateConversionValue)
    }
}
