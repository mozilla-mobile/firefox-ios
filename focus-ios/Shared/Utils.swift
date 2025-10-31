/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SafariServices

final class Utils {
    static func reloadSafariContentBlocker() {
        let identifier = AppInfo.contentBlockerBundleIdentifier
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier) { error in
            if let error = error {
                NSLog("Failed to reload \(identifier): \(error.localizedDescription)")
            }
        }
    }

    private static let lists: [SettingsToggle: String] = [
        .blockAds: "disconnect-block-advertising",
        .blockAnalytics: "disconnect-block-analytics",
        .blockSocial: "disconnect-block-social",
        .blockOther: "disconnect-block-content",
        .blockFonts: "web-fonts"
    ]

    static func getEnabledLists() -> [String] {
        return lists.compactMap { (toggle, list) -> String? in
            return Settings.getToggle(toggle) ? list : nil
        }
    }
}
