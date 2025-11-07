// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SummarizeKit

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
    case printSheet
    case shareSheet
    case saveAsPDF
    case webpageSummary(config: SummarizerConfig?)
    case zoom

    /// NOTE: This is only used in tests. Right now, we have three entrypoints for the summarizer and 
    /// it's difficult to find a way to pass custom configs to the summarizers from all three. 
    /// In FXIOS-13126, we will clean all this up and have one action/middleware to deal with this.
    /// Once that happens we can strip the associated value for `webpageSummary` and 
    /// revert to using CaseIterable on the enum.
    public static var allCasesForTests: [MainMenuNavigationDestination] {
        [
            .bookmarks,
            .defaultBrowser,
            .downloads,
            .editBookmark,
            .findInPage,
            .history,
            .passwords,
            .settings,
            .siteProtections,
            .syncSignIn,
            .printSheet,
            .shareSheet,
            .saveAsPDF,
            .webpageSummary(config: SummarizerConfig(instructions: "", options: [:])),
            .zoom
        ]
    }
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
