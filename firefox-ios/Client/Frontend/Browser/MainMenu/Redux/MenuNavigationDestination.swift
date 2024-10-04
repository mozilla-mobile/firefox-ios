// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum MainMenuNavigationDestination: Equatable, CaseIterable {
    case bookmarks
    case customizeHomepage
    case downloads
    case findInPage
    case goToURL
    case history
    case newTab
    case newPrivateTab
    case passwords
    case settings
}

enum MainMenuDetailsViewType {
    case tools
    case save
}

struct MenuNavigationDestination: Equatable {
    let destination: MainMenuNavigationDestination
    let urlToVisit: URL?

    init(
        _ destination: MainMenuNavigationDestination,
        urlToVisit: URL? = nil
    ) {
        self.destination = destination
        self.urlToVisit = urlToVisit
    }
}
