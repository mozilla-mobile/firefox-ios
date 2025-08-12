// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum MainMenuNavigationDestination: Equatable {
    case bookmarks
    case defaultBrowser
    case downloads
    case editBookmark
    case findInPage
    case history
    case passwords
    case settings
    case siteProtections
    case syncSignIn
    case printSheetV2
    case saveAsPDFV2
    case webpageSummary(instructions: String)
    case zoom
}

struct MenuNavigationDestination: Equatable {
    let destination: MainMenuNavigationDestination
    let url: URL?

    init(
        _ destination: MainMenuNavigationDestination,
        url: URL? = nil
    ) {
        self.destination = destination
        self.url = url
    }
}
