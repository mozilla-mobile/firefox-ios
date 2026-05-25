// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Storage for user activity information used for conversion funnelling
struct ConversionDataManager: Sendable {
    private struct Keys {
        static let installTimestamp = "skan.conversion.installTimestamp"
        static let activeDayIndices = "skan.conversion.activeDayIndices"
        static let searchedDayIndices = "skan.conversion.searchedDayIndices"
        static let defaultBrowserDayIndices = "skan.conversion.defaultBrowserDayIndices"
    }

    private let defaults: UserDefaultsInterface

    init(defaults: UserDefaultsInterface = UserDefaults.standard) {
        self.defaults = defaults
    }

    var installTimestamp: Timestamp? {
        get { defaults.object(forKey: Keys.installTimestamp) as? Timestamp }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.installTimestamp)
            } else {
                defaults.removeObject(forKey: Keys.installTimestamp)
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

    var defaultBrowserDayIndices: Set<Int> {
        get { Set(defaults.array(forKey: Keys.defaultBrowserDayIndices) as? [Int] ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.defaultBrowserDayIndices) }
    }
}
