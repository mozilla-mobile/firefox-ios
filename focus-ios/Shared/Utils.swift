/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SafariServices

class Utils {
    static func reloadSafariContentBlocker() {
        let identifier = AppInfo.ContentBlockerBundleIdentifier
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier) { error in
            if let error = error {
                NSLog("Failed to reload \(identifier): \(error.localizedDescription)")
            }
        }
    }

    private static let lists: [SettingsToggle: String] = [
        .blockAds: "disconnect-advertising",
        .blockAnalytics: "disconnect-analytics",
        .blockSocial: "disconnect-social",
        .blockOther: "disconnect-content",
        .blockFonts: "web-fonts",
    ]

    static func getEnabledLists() -> [String] {
        return lists.flatMap { toggle, list in
            return Settings.getToggle(toggle) ? list : nil
        }
    }
}
