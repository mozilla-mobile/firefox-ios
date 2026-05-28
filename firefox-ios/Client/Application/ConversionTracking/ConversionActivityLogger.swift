// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Records per-day activity signals that are used for event calculation for conversion events.
/// Each record is based on day-since-install so the activity log is independent of wall-clock date.
final class ConversionActivityLogger {
    private var dataManager: ConversionDataManager

    init(dataManager: ConversionDataManager = ConversionDataManager()) {
        self.dataManager = dataManager
    }

    func recordActiveToday(now: Timestamp = Date.now()) {
        guard let dayIndex = dayIndex(at: now) else { return }
        var indices = dataManager.activeDayIndices
        indices.insert(dayIndex)
        dataManager.activeDayIndices = indices
    }

    func recordSearchedToday(now: Timestamp = Date.now()) {
        guard let dayIndex = dayIndex(at: now) else { return }
        var indices = dataManager.searchedDayIndices
        indices.insert(dayIndex)
        dataManager.searchedDayIndices = indices
    }

    func recordFirstDayAfterInstallTimestampIfNeeded(now: Timestamp = Date.now()) {
        if dataManager.firstDayAfterInstallTimestamp == nil { dataManager.firstDayAfterInstallTimestamp = now }
    }

    private func dayIndex(at now: Timestamp) -> Int? {
        guard let install = dataManager.firstDayAfterInstallTimestamp else { return nil }
        let dayIndex = now.daysSince(timestamp: install)
        // Conversion windows only span 35 days. No need to log after that
        guard dayIndex <= 35 else { return nil }
        return dayIndex
    }
}
