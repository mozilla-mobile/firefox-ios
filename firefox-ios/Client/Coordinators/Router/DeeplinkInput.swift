// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// An enumeration of possible input parameters for handling deep links in the Mozilla Firefox browser.
enum DeeplinkInput {
    /// An enumeration of possible hosts for deep links.
    enum Host: String {
        case deepLink = "deep-link"
        case fxaSignIn = "fxa-signin"
        case openUrl = "open-url"
        case openText = "open-text"
        case sharesheet = "share-sheet"
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

        var shouldRouteDeeplinkToSpecificIPadWindow: Bool {
            switch self {
            case .widgetTabsMediumOpenUrl, .widgetTabsLargeOpenUrl:
                // Some of our widget URLs contain tab UUIDs which will be contained within a specific iPad
                // window. Make sure that when opening these we route them to the correct UIScene.
                return true
            default:
                return false
            }
        }
    }

    /// An enumeration of possible paths for deep links.
    enum Path: String {
        case settings = "settings"
        case homepanel = "homepanel"
        case defaultBrowser = "default-browser"
        case action
    }

    enum Shortcut: String {
        case newTab = "NewTab"
        case newPrivateTab = "NewPrivateTab"
        case openLastBookmark = "OpenLastBookmark"
        case qrCode = "QRCode"
    }
}
