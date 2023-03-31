// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Enumeration representing different navigational routes in an application.
enum Route {
    /// Represents a search route that takes a URL string and a boolean value indicating whether the search is private or not.
    case search(url: String, isPrivate: Bool)

    /// Represents a home panel route that takes a `HomepanelSection` value indicating the section to be displayed.
    case homepanel(HomepanelSection)

    /// Represents a settings route that takes a `SettingsSection` value indicating the settings section to be displayed.
    case settings(SettingsSection)

    /// Represents an application action route that takes an `AppAction` value indicating the action to be performed.
    case action(AppAction)

    /// Represents a Firefox account sign-in route that takes a `signIn` string, a `user` string, and an `email` string.
    case fxaSignIn(signIn: String, user: String, email: String)

    /// Enumeration representing different sections of the home panel.
    enum HomepanelSection: String, CaseIterable {
        case bookmarks = "bookmarks"
        case topSites = "top-sites"
        case history = "history"
        case readingList = "reading-list"
    }

    /// Enumeration representing different sections of the settings menu.
    enum SettingsSection: String, CaseIterable {
        case clearPrivateData = "clear-private-data"
        case newTab = "new-tab"
        case homePage = "home-page"
        case mailto = "mailto"
        case search = "search"
        case fxa = "fxa"
        case systemDefaultBrowser = "system-default-browser"
    }

    /// Enumeration representing different actions that can be performed within the application.
    enum AppAction: String, CaseIterable {
        case closePrivateTabs = "close-private-tabs"
    }
}
