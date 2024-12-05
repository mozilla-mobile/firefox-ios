// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Preconfigured sharing schemes which the share manager knows how to handle.
///     file: Include a file URL (file://). Best used for sharing downloaded files.
///     site: Include a website URL (http(s)://). Best used for sharing library/bookmarks, etc. without an active tab.
///           Shares configured using .site will not append a title to Messages but will have a subtitle in Mail.
///     tab:  Include a website URL and a tab to share. If sharing a tab with an active webView, then additional sharing
///           options will be configured, including printing the page and adding the webpage to your iOS home screen.
enum ShareType: Equatable {
    case file(url: URL)
    case site(url: URL)
    case tab(url: URL, tab: any ShareTab)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.file(lhsURL), .file(rhsURL)):
            return lhsURL == rhsURL
        case let (.site(lhsURL), .site(rhsURL)):
            return lhsURL == rhsURL
        case let (.tab(lhsURL, lhsTab), .tab(rhsURL, rhsTab)):
            return lhsURL == rhsURL && lhsTab.isEqual(to: rhsTab)
        default:
            return false
        }
    }

    var wrappedURL: URL {
        switch self {
        case let .file(url):
            return url
        case let .site(url):
            return url
        case let .tab(url, _):
            return url
        }
    }
}

extension ShareTab {
    func isEqual(to otherShareTab: some ShareTab) -> Bool {
        return self.displayTitle == otherShareTab.displayTitle
        && self.url == otherShareTab.url
        && self.webView == otherShareTab.webView
    }
}
