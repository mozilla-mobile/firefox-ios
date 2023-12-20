// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum InactiveTabStatus: String, Codable {
    case normal
    case inactive
    case shouldBecomeInactive
}

struct InactiveTabStates: Codable {
    var currentState: InactiveTabStatus?
    var nextState: InactiveTabStatus?
}

struct LegacyInactiveTabModel: Codable {
    // Contains [TabUUID String : InactiveTabState current or for next launch]
    var tabWithStatus: [String: InactiveTabStates] = [String: InactiveTabStates]()

    static let userDefaults = UserDefaults()

    /// Check to see if we ever ran this feature before, this is mainly
    /// to avoid tabs automatically going to their state on their first ever run
    static var hasRunInactiveTabFeatureBefore: Bool {
        get { return userDefaults.bool(forKey: PrefsKeys.KeyInactiveTabsFirstTimeRun) }
        set(value) { userDefaults.setValue(value, forKey: PrefsKeys.KeyInactiveTabsFirstTimeRun) }
    }

    static func save(tabModel: LegacyInactiveTabModel) {
        userDefaults.removeObject(forKey: PrefsKeys.KeyInactiveTabsModel)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(tabModel) {
            userDefaults.set(encoded, forKey: PrefsKeys.KeyInactiveTabsModel)
        }
    }

    static func get() -> LegacyInactiveTabModel? {
        if let inactiveTabsModel = userDefaults.object(forKey: PrefsKeys.KeyInactiveTabsModel) as? Data {
            do {
                let jsonDecoder = JSONDecoder()
                let inactiveTabModel = try jsonDecoder.decode(LegacyInactiveTabModel.self, from: inactiveTabsModel)
                return inactiveTabModel
            } catch {}
        }
        return nil
    }

    static func clear() {
        userDefaults.removeObject(forKey: PrefsKeys.KeyInactiveTabsModel)
    }
}
