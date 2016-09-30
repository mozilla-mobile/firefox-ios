/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct Settings {
    static let keyBlockAds = "BlockAds"
    static let keyBlockAnalytics = "BlockAnalytics"
    static let keyBlockSocial = "BlockSocial"
    static let keyBlockOther = "BlockOther"
    static let keyBlockFonts = "BlockFonts"

    // No longer used, but will be set to true in existing users' settings.
    static let keyIntroDone = "IntroDone"

    fileprivate static let defaults = UserDefaults(suiteName: AppInfo.SharedContainerIdentifier)!

    static func registerDefaults() {
        set(true, forKey: keyBlockAds)
        set(true, forKey: keyBlockAnalytics)
        set(true, forKey: keyBlockSocial)
        set(false, forKey: keyBlockOther)
        set(false, forKey: keyBlockFonts)
    }

    static func getBool(_ name: String) -> Bool? {
        return defaults.object(forKey: name) as? Bool
    }

    static func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }
}
