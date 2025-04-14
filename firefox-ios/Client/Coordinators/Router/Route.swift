// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// An enumeration representing different navigational routes in an application.
enum Route: Equatable {
    /// Represents a search route that takes a URL, a boolean value indicating whether the search
    /// is private or not and an optional set of search options.
    ///
    /// - Parameters:
    ///   - url: A `URL` object representing the URL to be searched. Pass `nil` if the search does not require a URL.
    ///   - isPrivate: A boolean value indicating whether the search is private or not.
    ///   - options: An optional set of `SearchOptions` values that can be used to customize the search behavior.
    case search(url: URL?, isPrivate: Bool, options: Set<SearchOptions>? = nil)

    /// Represents a search route that takes a URL and a tab identifier.
    ///
    /// - Parameters:
    ///   - url: A `URL` object representing the URL to be searched. Can be `nil`.
    ///   - tabId: A string representing the identifier of the tab where the search should be performed.
    case searchURL(url: URL?, tabId: String)

    /// Represents a search route that takes a query string a boolean value indicating whether the search
    /// is private or not.
    ///
    /// - Parameters:
    ///   - query: A string representing the query to be searched and.
    ///   - isPrivate: A boolean value indicating whether the search is private or not.
    case searchQuery(query: String, isPrivate: Bool)

    /// Represents a route for sending Glean data.
    ///
    /// - Parameter url: A `URL` object representing the URL to send Glean data to.
    case glean(url: URL)

    /// Represents a home panel route that takes a `HomepanelSection` value indicating the section to be displayed.
    ///
    /// - Parameter section: An instance of `HomepanelSection` indicating the section of the home
    ///                      panel to be displayed.
    case homepanel(section: HomepanelSection)

    /// Represents a settings route that takes a `SettingsSection` value indicating the settings
    /// section to be displayed.
    ///
    /// - Parameter section: An instance of `SettingsSection` indicating the section of the settings
    ///                      menu to be displayed.
    case settings(section: SettingsSection)

    /// Represents an application action route that takes an `AppAction` value indicating the action to be performed.
    ///
    /// - Parameter action: An instance of `AppAction` indicating the application action to be performed.
    case action(action: AppAction)

    /// Represents a Firefox account sign-in route that takes an `FxALaunchParams` object indicating
    /// the parameters for the sign-in.
    ///
    /// - Parameter params: An instance of `FxALaunchParams` containing the parameters for the sign-in.
    case fxaSignIn(params: FxALaunchParams)

    /// Represents a default browser route that takes a `DefaultBrowserSection` value indicating
    /// the section to be displayed.
    ///
    /// - Parameter section: An instance of `DefaultBrowserSection` indicating the section of the default browser
    ///                      settings to be displayed.
    case defaultBrowser(section: DefaultBrowserSection)

    /// A route for opening a share sheet with share content and an optional accompanying message.
    ///
    /// - Parameters:
    ///   - shareType: The content to be shared.
    ///   - shareMessage: An optional plain text share message to be shared.
    case sharesheet(shareType: ShareType, shareMessage: ShareMessage?)

    /// An enumeration representing different sections of the home panel.
    enum HomepanelSection: String, CaseIterable, Equatable {
        case bookmarks
        case topSites = "top-sites"
        case history
        case readingList = "reading-list"
        case downloads
        case newPrivateTab = "new-private-tab"
        case newTab = "new-tab"

        var libraryPanel: LibraryPanelType {
            switch self {
            case .bookmarks: return .bookmarks
            case .history: return .history
            case .readingList: return .readingList
            case .downloads: return .downloads
            default: return . bookmarks
            }
        }
    }

    /// An enumeration representing different sections of the settings menu.
    enum SettingsSection: String, CaseIterable, Equatable {
        case addresses
        case appIcon = "app-icon"
        case contentBlocker
        case clearPrivateData = "clear-private-data"
        case creditCard
        case password
        case fxa
        case general
        case homePage = "homepage"
        case mailto
        case newTab = "newtab"
        case search
        case browser
        case theme
        case toolbar
        case topSites
        case wallpaper
        case rateApp
    }

    /// An enumeration representing different actions that can be performed within the application.
    enum AppAction: String, CaseIterable, Equatable {
        case closePrivateTabs = "close-private-tabs"
        case showQRCode
        case showIntroOnboarding = "show-intro-onboarding"
    }

    /// An enumeration representing different sections of the default browser settings.
    enum DefaultBrowserSection: String, CaseIterable, Equatable {
        case tutorial
        case systemSettings = "system-settings"
    }

    /// An enumeration representing options that can be used in a search feature.
    enum SearchOptions: Equatable {
        /// An option to focus the user's attention on the location field of the search interface.
        case focusLocationField
    }
}
