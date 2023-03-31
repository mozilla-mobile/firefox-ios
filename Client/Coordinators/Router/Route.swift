// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum Route {
    case search(url: String, isPrivate: Bool)
    case homepanel(HomepanelSection)
    case settings(SettingsSection)
    case action(AppAction)
    case fxaSignIn(signIn: String, user: String, email: String)

    enum HomepanelSection: String, CaseIterable {
        case bookmarks = "bookmarks"
        case topSites = "top-sites"
        case history = "history"
        case readingList = "reading-list"
    }

    enum SettingsSection: String, CaseIterable {
        case clearPrivateData = "clear-private-data"
        case newTab = "new-tab"
        case homePage = "home-page"
        case mailto = "mailto"
        case search = "search"
        case fxa = "fxa"
        case systemDefaultBrowser = "system-default-browser"
    }

    enum AppAction: String, CaseIterable {
        case closePrivateTabs = "close-private-tabs"
    }
}
