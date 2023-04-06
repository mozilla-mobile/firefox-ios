// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// An enumeration representing different navigational routes in an application.
enum Route: Equatable {
    /// Represents a search route that takes a URL and a boolean value indicating whether the search is private or not.
    ///
    /// - Parameters:
    ///   - url: A `URL` object representing the URL to be searched. Can be `nil`.
    ///   - isPrivate: A boolean value indicating whether the search is private or not.
    case search(url: URL?, isPrivate: Bool)

    /// Represents a search route that takes a URL and a tab identifier.
    ///
    /// - Parameters:
    ///   - url: A `URL` object representing the URL to be searched. Can be `nil`.
    ///   - tabId: A string representing the identifier of the tab where the search should be performed.
    case search(url: URL?, tabId: String)

    /// Represents a search route that takes a query string.
    ///
    /// - Parameter query: A string representing the query to be searched.
    case search(query: String)

    /// Represents a route for sending Glean data.
    ///
    /// - Parameter url: A `URL` object representing the URL to send Glean data to.
    case glean(url: URL)

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

    /// Represents a Firefox account sign-in route that takes an `FxALaunchParams` object indicating the parameters for the sign-in.
    ///
    /// - Parameter params: An instance of `FxALaunchParams` containing the parameters for the sign-in.
    case fxaSignIn(_ params: FxALaunchParams)

    /// Represents a default browser route that takes a `DefaultBrowserSection` value indicating the section to be displayed.
    ///
    /// - Parameter section: An instance of `DefaultBrowserSection` indicating the section of the default browser settings to be displayed.
    case defaultBrowser(section: DefaultBrowserSection)

    /// An enumeration representing different sections of the home panel.
    enum HomepanelSection: String, CaseIterable, Equatable {
        case bookmarks = "bookmarks"
        case topSites = "top-sites"
        case history = "history"
        case readingList = "reading-list"
        case downloads
    }

    /// An enumeration representing different sections of the settings menu.
    enum SettingsSection: String, CaseIterable, Equatable {
        case clearPrivateData = "clear-private-data"
        case newTab = "newtab"
        case homePage = "homepage"
        case mailto = "mailto"
        case search = "search"
        case fxa = "fxa"
        case systemDefaultBrowser = "system-default-browser"
        case wallpaper = "wallpaper"
        case theme = "theme"
        case contentBlocker
        case toolbar
        case tabs
        case topSites
        case general
    }

    /// An enumeration representing different actions that can be performed within the application.
    enum AppAction: String, CaseIterable, Equatable {
        case closePrivateTabs = "close-private-tabs"
        case presentDefaultBrowserOnboarding
        case showQRCode
    }

    /// An enumeration representing different sections of the default browser settings.
    enum DefaultBrowserSection: String, CaseIterable, Equatable {
        case tutorial = "tutorial"
        case systemSettings = "system-settings"
    }
}

public extension URL {
    /// Force the URL's scheme to lowercase to ensure the code below can cope with URLs like the following from an external source. E.g Notes.app
    ///
    /// Https://www.apple.com
    ///
    var sanitized: URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let scheme = components.scheme, !scheme.isEmpty
        else { return self }

        components.scheme = scheme.lowercased()
        return components.url ?? self
    }
}

enum DeeplinkInput {
    enum Host: String {
        case deepLink = "deep-link"
        case fxaSignIn = "fxa-signin"
        case openUrl = "open-url"
        case openText = "open-text"
        case glean
        case widgetMediumTopSitesOpenUrl = "widget-medium-topsites-open-url"
        case widgetSmallQuickLinkOpenUrl = "widget-small-quicklink-open-url"
        case widgetMediumQuickLinkOpenUrl = "widget-medium-quicklink-open-url"
        case widgetSmallQuickLinkOpenCopied = "widget-small-quicklink-open-copied"
        case widgetMediumQuickLinkOpenCopied = "widget-medium-quicklink-open-copied"
        case widgetSmallQuickLinkClosePrivateTabs = "widget-small-quicklink-close-private-tabs"
        case widgetMediumQuickLinkClosePrivateTabs = "widget-medium-quicklink-close-private-tabs"
        case widgetTabsMediumOpenUrl = "widget-tabs-medium-open-url"
        case widgetTabsLargeOpenUrl = "widget-tabs-large-open-url"
    }

    enum Path: String {
        case settings = "settings"
        case homepanel = "homepanel"
        case defaultBrowser = "default-browser"
    }
}

extension Route {
    init?(url: URL) {
        let url = url.sanitized
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
              let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String]
        else {
            // Something very strange has happened; org.mozilla.Client should be the zeroeth URL type.
            return nil
        }

        guard let scheme = components.scheme, urlSchemes.contains(scheme) else { return nil }

        let isOurScheme = [URL.mozPublicScheme, URL.mozInternalScheme].contains(scheme)
        if isOurScheme, let hostRaw = components.host?.lowercased(), !hostRaw.isEmpty, let host = DeeplinkInput.Host(rawValue: hostRaw) {
            let urlQuery = components.valueForQuery("url")?.asURL
            // Unless the `open-url` URL specifies a `private` parameter,
            // use the last browsing mode the user was in.
            let isPrivate = Bool(components.valueForQuery("private") ?? "") ?? UserDefaults.standard.bool(forKey: PrefsKeys.LastSessionWasPrivate)

            switch host {
            case .deepLink:
                let deepLinkURL = components.valueForQuery("url")?.lowercased()
                let paths = deepLinkURL?.split(separator: "/") ?? []
                guard let pathRaw = paths[safe: 0].flatMap(String.init),
                        let path = DeeplinkInput.Path(rawValue: pathRaw),
                        let subPath = paths[safe: 1].flatMap(String.init)
                else { return nil }
                if path == .settings, let link = SettingsSection(rawValue: subPath) {
                    self = .settings(section: link)
                } else if path == .homepanel, let link = HomepanelSection(rawValue: subPath) {
                    self = .homepanel(section: link)
                } else if path == .defaultBrowser, let link = DefaultBrowserSection(rawValue: subPath) {
                    self = .defaultBrowser(section: link)
                } else {
                    return nil
                }

            case .fxaSignIn where components.valueForQuery("signin") != nil:
                self = .fxaSignIn(FxALaunchParams(entrypoint: .fxaDeepLinkNavigation, query: url.getQuery()))

            case .openUrl:
                self = .search(url: urlQuery, isPrivate: isPrivate)

            case .openText:
                self = .search(query: components.valueForQuery("text") ?? "")

            case .glean:
                self = .glean(url: url)

            case .widgetMediumTopSitesOpenUrl:
                // Widget Top sites - open url
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .mediumTopSitesWidget)
                self = .search(url: urlQuery, isPrivate: isPrivate)

            case .widgetSmallQuickLinkOpenUrl:
                // Widget Quick links - small - open url private or regular
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .smallQuickActionSearch)
                self = .search(url: urlQuery, isPrivate: isPrivate)

            case .widgetMediumQuickLinkOpenUrl:
                // Widget Quick Actions - medium - open url private or regular
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: isPrivate ?.mediumQuickActionPrivateSearch :.mediumQuickActionSearch)
                self = .search(url: urlQuery, isPrivate: isPrivate)

            case .widgetSmallQuickLinkOpenCopied, .widgetMediumQuickLinkOpenCopied:
                // Widget Quick links - medium - open copied url
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .mediumQuickActionCopiedLink)
                if !UIPasteboard.general.hasURLs {
                    let searchText = UIPasteboard.general.string ?? ""
                    self = .search(query: searchText)
                } else {
                    let url = UIPasteboard.general.url
                    let isPrivate = UserDefaults.standard.bool(forKey: PrefsKeys.LastSessionWasPrivate)
                    self = .search(url: url, isPrivate: isPrivate)
                }

            case .widgetSmallQuickLinkClosePrivateTabs, .widgetMediumQuickLinkClosePrivateTabs:
                // Widget Quick links - medium - close private tabs
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .mediumQuickActionClosePrivate)
                self = .action(action: .closePrivateTabs)

            case .widgetTabsMediumOpenUrl:
                // Widget Tabs Quick View - medium
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .mediumTabsOpenUrl)
                let tabs = SimpleTab.getSimpleTabs()
                if let uuid = components.valueForQuery("uuid"), !tabs.isEmpty {
                    let tab = tabs[uuid]
                    self = .search(url: tab?.url, tabId: uuid)
                } else {
                    self = .search(url: nil, isPrivate: false)
                }

            case .widgetTabsLargeOpenUrl:
                // Widget Tabs Quick View - large
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .largeTabsOpenUrl)
                let tabs = SimpleTab.getSimpleTabs()
                if let uuid = components.valueForQuery("uuid"), !tabs.isEmpty {
                    let tab = tabs[uuid]
                    self = .search(url: tab?.url, tabId: uuid)
                } else {
                    self = .search(url: nil, isPrivate: false)
                }
                    
            case .fxaSignIn:
                return nil
            }
        } else if ["http", "https"].contains(scheme) {
            TelemetryWrapper.gleanRecordEvent(category: .action, method: .open, object: .asDefaultBrowser)
            RatingPromptManager.isBrowserDefault = true
            // Use the last browsing mode the user was in
            let isPrivate = UserDefaults.standard.bool(forKey: PrefsKeys.LastSessionWasPrivate)
            self = .search(url: url, isPrivate: isPrivate)
        } else {
            return nil
        }
    }
}
