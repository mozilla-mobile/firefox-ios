// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class InAppMessagingStorage {
    private enum Keys {
        static let impressionCounts = "InAppMessaging.impressionCounts"
        static let dismissedIDs = "InAppMessaging.dismissedIDs"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func impressionCount(for messageID: String) -> Int {
        let counts = userDefaults.dictionary(forKey: Keys.impressionCounts) as? [String: Int] ?? [:]
        return counts[messageID] ?? 0
    }

    func incrementImpressionCount(for messageID: String) {
        var counts = userDefaults.dictionary(forKey: Keys.impressionCounts) as? [String: Int] ?? [:]
        counts[messageID] = (counts[messageID] ?? 0) + 1
        userDefaults.set(counts, forKey: Keys.impressionCounts)
    }

    func isDismissed(_ messageID: String) -> Bool {
        let dismissed = userDefaults.stringArray(forKey: Keys.dismissedIDs) ?? []
        return dismissed.contains(messageID)
    }

    func markDismissed(_ messageID: String) {
        var dismissed = userDefaults.stringArray(forKey: Keys.dismissedIDs) ?? []
        if !dismissed.contains(messageID) {
            dismissed.append(messageID)
            userDefaults.set(dismissed, forKey: Keys.dismissedIDs)
        }
    }
}
