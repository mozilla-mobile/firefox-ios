/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

/// Accessors for homepage details from the app state.
/// These are pure functions, so it's quite ok to have them
/// as static.

// This HomePagePref is only used when setting the HomePage on the newTab and not setting a custom URL for the Home button.
class NewTabHomePageAccessors {

    static func getHomePage(_ prefs: Prefs) -> URL? {
        let string = prefs.stringForKey(HomePageConstants.NewTabCustomUrlPrefKey) ?? getDefaultHomePageString(prefs)
        guard let urlString = string else {
            return nil
        }
        return URL(string: urlString)
    }

    static func getDefaultHomePageString(_ prefs: Prefs) -> String? {
        return prefs.stringForKey(HomePageConstants.DefaultHomePageURLPrefKey)
    }
}

class HomeButtonHomePageAccessors {

    static func getHomePage(_ prefs: Prefs) -> URL? {
        let string = prefs.stringForKey(PrefsKeys.HomeButtonHomePageURL)
        guard let urlString = string else {
            return nil
        }
        return URL(string: urlString)
    }
}

