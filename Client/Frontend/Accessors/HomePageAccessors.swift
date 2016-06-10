/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

/// Accessors for homepage details from the app state.
/// These are pure functions, so it's quite ok to have them
/// as static.
class HomePageAccessors {
    private static let getPrefs = Accessors.getPrefs

    static func getHomePage(state: AppState) -> NSURL? {
        return getHomePage(getPrefs(state))
    }

    static func hasHomePage(state: AppState) -> Bool {
        return getHomePage(state) != nil
    }

    static func isButtonInMenu(state: AppState) -> Bool {
        return isButtonInMenu(getPrefs(state))
    }

    static func isButtonEnabled(state: AppState) -> Bool {
        switch state.ui {
        case .Tab:
            return true
        case .HomePanels, .Loading:
            return hasHomePage(state)
        default:
            return false
        }
    }
}

extension HomePageAccessors {
    static func isButtonInMenu(prefs: Prefs) -> Bool {
        return prefs.boolForKey(HomePageConstants.HomePageButtonIsInMenuPrefKey) ?? true
    }

    static func getHomePage(prefs: Prefs) -> NSURL? {
        let string = prefs.stringForKey(HomePageConstants.HomePageURLPrefKey) ?? getDefaultHomePageString(prefs)
        guard let urlString = string else {
            return nil
        }
        return NSURL(string: urlString)
    }

    static func getDefaultHomePageString(prefs: Prefs) -> String? {
        return prefs.stringForKey(HomePageConstants.DefaultHomePageURLPrefKey)
    }
}