// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum MainMenuNavigationDestination: Equatable, CaseIterable {
    case bookmarks
    case customizeHomepage
    case downloads
    case editBookmark
    case findInPage
    case goToURL
    case history
    case newTab
    case newPrivateTab
    case passwords
    case settings
    case syncSignIn
    case shareSheet
    case zoom
}

enum MainMenuDetailsViewType {
    case tools
    case save
}

struct MenuNavigationDestination: Equatable {
    let destination: MainMenuNavigationDestination
    let url: URL?
    let title: String?

    init(
        _ destination: MainMenuNavigationDestination,
        url: URL? = nil,
        title: String? = nil
    ) {
        self.destination = destination
        self.url = url
        self.title = title
    }
}
