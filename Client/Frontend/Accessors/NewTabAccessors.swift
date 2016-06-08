/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

/// Accessors to find what a new tab should do when created without a URL.
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

    static func getNewTabPage(state: AppState) -> NewTabPage {
        return getNewTabPage(Accessors.getPrefs(state))
    }
}

/// Enum to encode what should happen when the user opens a new tab without a URL.
enum NewTabPage: String {
    case BlankPage = "Blank"
    case HomePage = "HomePage"
    case TopSites = "TopSites"
    case Bookmarks = "Bookmarks"
    case History = "History"
    case ReadingList = "ReadingList"

    var settingTitle: String {
        switch self {
        case .BlankPage:
            return Strings.SettingsNewTabBlankPage
        case .HomePage:
            return Strings.SettingsNewTabHomePage
        case .TopSites:
            return Strings.SettingsNewTabTopSites
        case .Bookmarks:
            return Strings.SettingsNewTabBookmarks
        case .History:
            return Strings.SettingsNewTabHistory
        case .ReadingList:
            return Strings.SettingsNewTabReadingList
        }
    }

    var url: NSURL? {
        switch self {
        case .BlankPage:
            return nil
        case .HomePage:
            return nil
        case .TopSites:
            return NSURL(string:"#panel=0", relativeToURL: UIConstants.AboutHomePage)
        case .Bookmarks:
            return NSURL(string:"#panel=1", relativeToURL: UIConstants.AboutHomePage)
        case .History:
            return NSURL(string:"#panel=2", relativeToURL: UIConstants.AboutHomePage)
        case .ReadingList:
            return NSURL(string:"#panel=3", relativeToURL: UIConstants.AboutHomePage)
        }
    }

    static let allValues = [BlankPage, TopSites, Bookmarks, History, ReadingList, HomePage]
}