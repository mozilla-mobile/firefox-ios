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
    static let KeyIntroDone = "IntroDone"

    private static let defaults = NSUserDefaults(suiteName: AppInfo.SharedContainerIdentifier)!

    static func registerDefaults() {
        set(true, forKey: KeyBlockAds)
        set(true, forKey: KeyBlockAnalytics)
        set(true, forKey: KeyBlockSocial)
        set(false, forKey: KeyBlockOther)
        set(false, forKey: KeyBlockFonts)
    }

    static func getBool(name: String) -> Bool? {
        return defaults.objectForKey(name) as? Bool
    }

    static func set(value: Bool, forKey key: String) {
        defaults.setBool(value, forKey: key)
        defaults.synchronize()
    }
}
