// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Counter to know if a user has used the app a certain number of days in a row, used for `RatingPromptManager` requirements.
class CumulativeDaysOfUseCounter {

    private let calendar = Calendar.current
    private let maximumNumberOfDaysToCollect = 7
    private let requiredCumulativeDaysOfUseCount = 5

    private enum UserDefaultsKey: String {
        case keyArrayDaysOfUse = "com.moz.arrayDaysOfUse.key"
        case keyRequiredCumulativeDaysOfUseCount = "com.moz.hasRequiredCumulativeDaysOfUseCount.key"
    }

    private(set) var hasRequiredCumulativeDaysOfUse: Bool {
        get { UserDefaults.standard.object(forKey: UserDefaultsKey.keyRequiredCumulativeDaysOfUseCount.rawValue) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyRequiredCumulativeDaysOfUseCount.rawValue) }
    }

    private var daysOfUse: [Date]? {
        get { UserDefaults.standard.array(forKey: UserDefaultsKey.keyArrayDaysOfUse.rawValue) as? [Date] }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyArrayDaysOfUse.rawValue) }
    }

    func updateCounter(currentDate: Date = Date()) {
        // If there's no data, add current day of usage
        guard var daysOfUse = daysOfUse, let lastDayOfUse = daysOfUse.last else {
            daysOfUse = [currentDate]
            return
        }

        // Append usage days that are not already saved
        let numberOfDaysSinceLastUse = calendar.numberOfDaysBetween(lastDayOfUse, and: currentDate)
        if numberOfDaysSinceLastUse >= 1 {
            daysOfUse.append(currentDate)
            self.daysOfUse = daysOfUse
        }

        // Check if we have 5 consecutive days in the last 7 days
        hasRequiredCumulativeDaysOfUse = hasRequiredCumulativeDaysOfUse(daysOfUse: daysOfUse)

        // Clean data older than 7 days
        cleanDaysOfUseData(daysOfUse: daysOfUse, currentDate: currentDate)
    }

    private func hasRequiredCumulativeDaysOfUse(daysOfUse: [Date]) -> Bool {
        var cumulativeDaysCount = 0
        var previousDay: Date?
        var maxNumberOfConsecutiveDays = 0

        daysOfUse.forEach { dayOfUse in
            if let previousDay = previousDay {
                let numberOfDaysBetween = calendar.numberOfDaysBetween(previousDay, and: dayOfUse)
                cumulativeDaysCount = numberOfDaysBetween == 1 ? cumulativeDaysCount + 1 : 0
            } else {
                cumulativeDaysCount += 1
            }

            maxNumberOfConsecutiveDays = max(cumulativeDaysCount, maxNumberOfConsecutiveDays)
            previousDay = dayOfUse
        }

        return maxNumberOfConsecutiveDays >= requiredCumulativeDaysOfUseCount
    }

    private func cleanDaysOfUseData(daysOfUse: [Date], currentDate: Date) {
        var cleanedDaysOfUse = daysOfUse
        cleanedDaysOfUse.removeAll(where: {
            let numberOfDays = calendar.numberOfDaysBetween($0, and: currentDate)
            return numberOfDays >= maximumNumberOfDaysToCollect
        })

        self.daysOfUse = cleanedDaysOfUse
    }

    func reset() {
        hasRequiredCumulativeDaysOfUse = false
        daysOfUse = nil
    }
}
