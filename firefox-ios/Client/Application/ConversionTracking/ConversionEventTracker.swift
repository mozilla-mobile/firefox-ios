// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct ConversionEventTracker {
    static let attributionHorizonDays = 35

    let dataManager: ConversionDataManager
    let conversionValueUpdater: ConversionValueUpdater

    init(dataManager: ConversionDataManager = ConversionDataManager(),
         conversionValueUpdater: ConversionValueUpdater = SKAdNetworkUpdater()) {
        self.dataManager = dataManager
        self.conversionValueUpdater = conversionValueUpdater
    }

    func recordURILoadConversionEvent(now: Timestamp = Date.now()) {
        guard let install = dataManager.installTimestamp else { return }
        let dayIndex = Date.now().daysSince(timestamp: install)
        guard dayIndex >= 1, dayIndex <= 28 else { return }
        ConversionEventTracker().record(.uriLoadDay2Plus)
    }

    func recordActivityEvents(now: Timestamp = Date.now()) {
        guard let install = dataManager.installTimestamp else { return }
        let dayIndex = now.daysSince(timestamp: install)
        guard dayIndex <= ConversionEventTracker.attributionHorizonDays else { return }

        if dayIndex == 0 {
            record(.activeFirstDay)
        } else if dayIndex >= 1 && dayIndex <= 28 {
            record(.appOpenDay2Plus)
        }

        let active = dataManager.activeDayIndices
        let searched = dataManager.searchedDayIndices
        let defaulted = dataManager.defaultBrowserDayIndices

        let week1Active = active.intersection(0...6)
        let firstFourActive = active.intersection(0...3)
        let lastThreeActive = active.intersection(4...6)

        if week1Active.count >= 3 {
            record(.thirdActivityFirstWeek)
        }
        if !lastThreeActive.isEmpty {
            record(.activeLastThreeWeek1)
        }
        if firstFourActive.count >= 2 && lastThreeActive.count >= 2 {
            record(.activeTwoOfFourAndThreeWeek1)
        }
        if Set(0...6).isSubset(of: active) && defaulted.intersection(0...3).count == 4 {
            record(.dailyActiveWeek1DefaultFirst4)
        }
        if week1Active.count >= 3 && !searched.intersection(3...6).isEmpty {
            record(.activated)
        }
    }

    func record(_ event: ConversionEvent) {
        let cv = event.conversionValue
        conversionValueUpdater.update(conversionValue: cv)
    }
}

enum ConversionEvent {
    case activeFirstDay
    case appOpenDay2Plus
    case uriLoadDay2Plus
    case firstAdClick
    case thirdActivityFirstWeek
    case activeLastThreeWeek1
    case activeTwoOfFourAndThreeWeek1
    case activated
    case dailyActiveWeek1DefaultFirst4
    case setAsDefault

    var conversionValue: ConversionValue {
        switch self {
        case .activeFirstDay:
            return .init(fine: 5, coarse: .low, lockWindow: false)
        case .appOpenDay2Plus:
            return .init(fine: 15, coarse: .medium, lockWindow: false)
        case .uriLoadDay2Plus:
            return .init(fine: 25, coarse: .medium, lockWindow: false)
        case .firstAdClick:
            return .init(fine: 35, coarse: .medium, lockWindow: false)
        case .thirdActivityFirstWeek:
            return .init(fine: 0, coarse: .medium, lockWindow: false)
        case .activeLastThreeWeek1:
            return .init(fine: 0, coarse: .medium, lockWindow: false)
        case .activeTwoOfFourAndThreeWeek1:
            return .init(fine: 0, coarse: .medium, lockWindow: false)
        case .activated:
            return .init(fine: 0, coarse: .high, lockWindow: false)
        case .dailyActiveWeek1DefaultFirst4:
            return .init(fine: 0, coarse: .high, lockWindow: false)
        case .setAsDefault:
            return .init(fine: 60, coarse: .high, lockWindow: true)
        }
    }
}
