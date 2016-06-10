/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

///
struct NewTabAccessors {
    static let PrefKey = "NewTabPrefKey"
    static let Default = NewTabPage.TopSites

    static func getNewTabPage(prefs: Prefs) -> NewTabPage {
        guard let raw = prefs.stringForKey(PrefKey) else {
            return Default
        }
        let option = NewTabPage(rawValue: raw) ?? Default
        // Check if the user has chosen to open a homepage, but no homepage is set,
        // then use the default.
        if option == .HomePage && HomePageAccessors.getHomePage(prefs) == nil {
            return Default
        }
        return option
    }
}