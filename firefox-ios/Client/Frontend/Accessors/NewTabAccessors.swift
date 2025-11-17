// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Accessors to find what a new tab should do when created without a URL.
struct NewTabAccessors {
    static let NewTabPrefKey = PrefsKeys.KeyNewTab
    static let HomePrefKey = PrefsKeys.HomePageTab
    static let Default = NewTabPage.topSites

    static func getNewTabPage(_ prefs: Prefs) -> NewTabPage {
        guard let raw = prefs.stringForKey(NewTabPrefKey) else { return Default }

        let option = NewTabPage(rawValue: raw) ?? Default
        // Check if the user has chosen to open a homepage, but no homepage is set,
        // then use the default.
        if option == .homePage && NewTabHomePageAccessors.getHomePage(prefs) == nil {
            return Default
        }
        return option
    }

    /// Retrieves the user's preference for the new tab page.
    /// If the preference value is invalid or missing, the default firefox homepage is returned.
    /// Additionally, if the user has selected the custom URL option, `.homePage`,
    /// but no homepage URL is configured, the method falls back to the default to ensure a valid tab experience.
    ///
    /// - Parameter prefs: The preferences object containing the user's settings.
    /// - Returns: The resolved `NewTabPage` value based on the user's preferences or default fallback.
    static func getHomePage(_ prefs: Prefs) -> NewTabPage {
        guard let raw = prefs.stringForKey(HomePrefKey) else { return Default }

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
    /// Custom Firefox homepage (URL set by user)
    case homePage = "HomePage"
    /// Firefox homepage
    case topSites = "TopSites"

    var settingTitle: String {
        switch self {
        case .blankPage:
            return .SettingsNewTabBlankPage
        case .homePage:
            return .SettingsNewTabCustom
        case .topSites:
            return .SettingsNewTabTopSites
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
        guard let homePanel = self.homePanelType else { return nil }
        return homePanel.internalUrl as URL
    }

    static func fromAboutHomeURL(url: URL) -> NewTabPage? {
        guard let internalUrl = InternalURL(url),
              internalUrl.isAboutHomeURL,
              let panelNumber = url.fragment?.split(separator: "=").last
        else { return nil }

        switch panelNumber {
        case "0":
            return NewTabPage.topSites
        default:
            return nil
        }
    }

    static let allValues = [blankPage, topSites, homePage]
}
