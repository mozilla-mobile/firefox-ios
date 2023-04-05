// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// An enumeration representing different navigational routes in an application.
enum Route {
    /// Represents a search route that takes a URL string and a boolean value indicating whether the search is private or not.
    ///
    /// - Parameters:
    ///   - url: A string representing the URL to be searched.
    ///   - isPrivate: A boolean value indicating whether the search is private or not.
    case search(url: String, isPrivate: Bool)

    /// Represents a home panel route that takes a `HomepanelSection` value indicating the section to be displayed.
    ///
    /// - Parameter section: An instance of `HomepanelSection` indicating the section of the home panel to be displayed.
    case homepanel(section: HomepanelSection)

    /// Represents a settings route that takes a `SettingsSection` value indicating the settings section to be displayed.
    ///
    /// - Parameter section: An instance of `SettingsSection` indicating the section of the settings menu to be displayed.
    case settings(section: SettingsSection)

    /// Represents an application action route that takes an `AppAction` value indicating the action to be performed.
    ///
    /// - Parameter action: An instance of `AppAction` indicating the application action to be performed.
    case action(action: AppAction)

    /// Represents a Firefox account sign-in route that takes a `signIn` string, a `user` string, and an `email` string.
    ///
    /// - Parameters:
    ///   - signIn: A string representing the sign-in action.
    ///   - user: A string representing the username of the account being signed in to.
    ///   - email: A string representing the email address associated with the account being signed in to.
    case fxaSignIn(signIn: String, user: String, email: String)

    /// An enumeration representing different sections of the home panel.
    enum HomepanelSection: String, CaseIterable {
        case bookmarks = "bookmarks"
        case topSites = "top-sites"
        case history = "history"
        case readingList = "reading-list"
        case downloads
    }

    /// An enumeration representing different sections of the settings menu.
    enum SettingsSection: String, CaseIterable {
        case clearPrivateData = "clear-private-data"
        case newTab = "new-tab"
        case homePage = "home-page"
        case mailto = "mailto"
        case search = "search"
        case fxa = "fxa"
        case systemDefaultBrowser = "system-default-browser"
        case wallpaper
        case theme
        case contentBlocker
        case toolbar
        case tabs
        case topSites
    }

    /// An enumeration representing different actions that can be performed within the application.
    enum AppAction: String, CaseIterable {
        case closePrivateTabs = "close-private-tabs"
        case presentDefaultBrowserOnboarding
        case showQRCode
    }
}
