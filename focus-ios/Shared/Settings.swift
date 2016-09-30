/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct Settings {
    static let KeyBlockAds = "BlockAds"
    static let KeyBlockAnalytics = "BlockAnalytics"
    static let KeyBlockSocial = "BlockSocial"
    static let KeyBlockOther = "BlockOther"
    static let KeyBlockFonts = "BlockFonts"

    // No longer used, but will be set to true in existing users' settings.
    static let KeyIntroDone = "IntroDone"

    fileprivate static let defaults = UserDefaults(suiteName: AppInfo.SharedContainerIdentifier)!

    static func registerDefaults() {
        set(true, forKey: KeyBlockAds)
        set(true, forKey: KeyBlockAnalytics)
        set(true, forKey: KeyBlockSocial)
        set(false, forKey: KeyBlockOther)
        set(false, forKey: KeyBlockFonts)
    }

    static func getBool(_ name: String) -> Bool? {
        return defaults.object(forKey: name) as? Bool
    }

    static func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }
}
