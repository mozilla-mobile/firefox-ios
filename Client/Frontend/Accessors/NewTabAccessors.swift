/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

/// Accessors to find what a new tab should do when created without a URL.
struct NewTabAccessors {
    static let NewTabPrefKey = PrefsKeys.KeyNewTab
    static let HomePrefKey = PrefsKeys.HomePageTab
    static let Default = NewTabPage.topSites

    static func getNewTabPage(_ prefs: Prefs) -> NewTabPage {
        guard let raw = prefs.stringForKey(NewTabPrefKey) else {
            return Default
        }
        let option = NewTabPage(rawValue: raw) ?? Default
        // Check if the user has chosen to open a homepage, but no homepage is set,
        // then use the default.
        if option == .homePage && NewTabHomePageAccessors.getHomePage(prefs) == nil {
            return Default
        }
        return option
    }

    static func getHomePage(_ prefs: Prefs) -> NewTabPage {
        guard let raw = prefs.stringForKey(HomePrefKey) else {
            return Default
        }
        let option = NewTabPage(rawValue: raw) ?? Default
        // Check if the user has chosen to open a homepage, but no homepage is set,
        // then use the default.
        if option == .homePage && HomeButtonHomePageAccessors.getHomePage(prefs) == nil {
            return Default
        }
        return option
    }

}

/// Enum to encode what should happen when the user opens a new tab without a URL.
enum NewTabPage: String {
    case blankPage = "Blank"
    case homePage = "HomePage"
    case topSites = "TopSites"

    var settingTitle: String {
        switch self {
        case .blankPage:
            return Strings.SettingsNewTabBlankPage
        case .homePage:
            return Strings.SettingsNewTabHomePage
        case .topSites:
            return Strings.SettingsNewTabTopSites
        }
    }

    var homePanelType: HomePanelType? {
        switch self {
        case .topSites:
            return HomePanelType.topSites
        default:
            return nil
        }
    }

    var url: URL? {
        guard let homePanel = self.homePanelType else {
            return nil
        }
        return homePanel.internalUrl as URL
    }

    static func fromAboutHomeURL(url: URL) -> NewTabPage? {
        guard let internalUrl = InternalURL(url), internalUrl.isAboutHomeURL else { return nil}
        guard let panelNumber = url.fragment?.split(separator: "=").last else { return nil }
        switch panelNumber {
        case "0":
            return NewTabPage.topSites
        default:
            return nil
        }
    }

    static let allValues = [blankPage, topSites, homePage]
}
