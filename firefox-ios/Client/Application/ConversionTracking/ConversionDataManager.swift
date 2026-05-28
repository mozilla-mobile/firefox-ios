// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Storage for user activity information used for conversion funnelling
struct ConversionDataManager: Sendable {
    private struct Keys {
        static let firstDayAfterInstallTimestamp = "com.moz.conversion.firstDayAfterInstallTimestamp"
        static let activeDayIndices = "com.moz.conversion.activeDayIndices"
        static let searchedDayIndices = "com.moz.conversion.searchedDayIndices"
    }

    private let defaults: UserDefaultsInterface

    init(defaults: UserDefaultsInterface = UserDefaults.standard) {
        self.defaults = defaults
    }

    var firstDayAfterInstallTimestamp: Timestamp? {
        get { defaults.object(forKey: Keys.firstDayAfterInstallTimestamp) as? Timestamp }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.firstDayAfterInstallTimestamp)
            } else {
                defaults.removeObject(forKey: Keys.firstDayAfterInstallTimestamp)
            }
        }
    }

    var activeDayIndices: Set<Int> {
        get { Set(defaults.array(forKey: Keys.activeDayIndices) as? [Int] ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.activeDayIndices) }
    }

    var searchedDayIndices: Set<Int> {
        get { Set(defaults.array(forKey: Keys.searchedDayIndices) as? [Int] ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.searchedDayIndices) }
    }
}
