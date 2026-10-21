// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct ConversionEventTracker {
    let dataManager: ConversionDataManager
    let conversionValueUpdater: ConversionValueUpdater

    init(dataManager: ConversionDataManager = ConversionDataManager(),
         conversionValueUpdater: ConversionValueUpdater = SKAdNetworkUpdater()) {
        self.dataManager = dataManager
        self.conversionValueUpdater = conversionValueUpdater
    }

    func recordURILoadConversionEvent(now: Timestamp = Date.now()) {
        guard let dayIndex = currentDayIndex(from: now),
            dayIndex >= 1, dayIndex <= 28 else { return }
        record(.uriLoadDay2Plus, now: now)
    }

    func recordActivityEvents(now: Timestamp = Date.now()) {
        guard let dayIndex = currentDayIndex(from: now),
            ConversionWindow(dayIndex: dayIndex) != nil else { return }

        if dayIndex == 0 {
            record(.activeFirstDay, now: now)
        } else if dayIndex >= 1 && dayIndex <= 28 {
            // Days index starts at 0 so day 2 is index 1
            record(.appOpenDay2Plus, now: now)
        }

        let active = dataManager.activeDayIndices
        let searched = dataManager.searchedDayIndices

        let week1Active = active.intersection(0...6)
        let firstFourActive = active.intersection(0...3)
        let lastThreeActive = active.intersection(4...6)

        if week1Active.count >= 3 {
            record(.thirdActivityFirstWeek, now: now)
        }
        if !lastThreeActive.isEmpty {
            record(.activeLastThreeWeek1, now: now)
        }
        if firstFourActive.count >= 2 && lastThreeActive.count >= 2 {
            record(.activeTwoOfFourAndThreeWeek1, now: now)
        }
        if Set(0...6).isSubset(of: active) {
            record(.dailyActiveFirstWeek, now: now)
        }
        if week1Active.count >= 3 && !searched.intersection(3...6).isEmpty {
            record(.activated, now: now)
        }
    }

    /// Sends the event's conversion value if the event is mapped in the current window
    /// and its coarse value isn't lower than the last one sent in that window
    func record(_ event: ConversionEvent, now: Timestamp = Date.now()) {
        guard let dayIndex = currentDayIndex(from: now),
              let window = ConversionWindow(dayIndex: dayIndex),
              let coarse = event.coarseValue(in: window) else { return }

        let windowKey = String(window.rawValue)
        let lastRawValue = dataManager.lastCoarseValueByWindow[
            windowKey
        ] ?? ConversionValue.CoarseConversionValue.low.rawValue
        guard coarse.rawValue >= lastRawValue else { return }

        dataManager.lastCoarseValueByWindow[windowKey] = coarse.rawValue
        conversionValueUpdater.update(conversionValue: ConversionValue(fine: event.fineValue, coarse: coarse))
    }

    private func currentDayIndex(from now: Timestamp) -> Int? {
        guard let install = dataManager.firstDayAfterInstallTimestamp else { return nil }
        return now.daysSince(timestamp: install)
    }
}

/// SKAdNetwork 4 conversion windows, expressed in days since first launch
enum ConversionWindow: Int {
    case first
    case second
    case third

    init?(dayIndex: Int) {
        switch dayIndex {
        case 0...1: self = .first
        case 2...6: self = .second
        case 7...34: self = .third
        default: return nil
        }
    }
}

enum ConversionEvent {
    case activeFirstDay
    case setAsDefault
    case appOpenDay2Plus
    case uriLoadDay2Plus
    case firstAdClick
    case thirdActivityFirstWeek
    case activeLastThreeWeek1
    case dailyActiveFirstWeek
    case activated
    case activeTwoOfFourAndThreeWeek1

    /// Only reported in the first window's postback
    var fineValue: Int {
        switch self {
        case .activeFirstDay: return 5
        case .setAsDefault: return 10
        case .appOpenDay2Plus: return 15
        case .activeLastThreeWeek1: return 20
        case .thirdActivityFirstWeek: return 22
        case .uriLoadDay2Plus: return 25
        case .activeTwoOfFourAndThreeWeek1: return 30
        case .firstAdClick: return 35
        case .activated: return 45
        case .dailyActiveFirstWeek: return 55
        }
    }

    /// Returns nil when the event isn't mapped in the given window
    func coarseValue(in window: ConversionWindow) -> ConversionValue.CoarseConversionValue? {
        switch (window, self) {
        case (.first, .activeFirstDay), (.first, .setAsDefault), (.first, .firstAdClick):
            return .medium
        case (.first, .appOpenDay2Plus), (.first, .uriLoadDay2Plus):
            return .high
        case (.second, .activeLastThreeWeek1),
             (.second, .thirdActivityFirstWeek),
             (.second, .activeTwoOfFourAndThreeWeek1):
            return .medium
        case (.second, .activated), (.second, .dailyActiveFirstWeek):
            return .high
        case (.third, .appOpenDay2Plus), (.third, .uriLoadDay2Plus):
            return .medium
        case (.third, .activated):
            return .high
        default:
            return nil
        }
    }
}
