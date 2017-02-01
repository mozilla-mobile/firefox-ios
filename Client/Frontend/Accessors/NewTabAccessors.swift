/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

/// Accessors to find what a new tab should do when created without a URL.
struct NewTabAccessors {
    static let PrefKey = PrefsKeys.KeyNewTab
    static let Default = NewTabPage.TopSites

    static func getNewTabPage(_ prefs: Prefs) -> NewTabPage {
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

    static func getNewTabPage(_ state: AppState) -> NewTabPage {
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

    var homePanelType: HomePanelType? {
        switch self {
        case .TopSites:
            return HomePanelType.topSites
        case .Bookmarks:
            return HomePanelType.bookmarks
        case .History:
            return HomePanelType.history
        case .ReadingList:
            return HomePanelType.readingList
        default:
            return nil
        }
    }

    var url: URL? {
        guard let homePanel = self.homePanelType else {
            return nil
        }
        return homePanel.localhostURL as URL
    }

    static let allValues = [BlankPage, TopSites, Bookmarks, History, ReadingList, HomePage]
}
