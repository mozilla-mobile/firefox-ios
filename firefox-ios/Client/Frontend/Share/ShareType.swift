// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Preconfigured sharing schemes which the share manager knows how to handle.
///     file: Include a file URL (`file://`). Best used for sharing downloaded files. If possible, the remote URL is saved
///           as well for `Send to Device` and other activities which share the content off-device without an attachment.
///     site: Include a website URL (`http(s)://`). Best used for sharing library/bookmarks, etc. without an active tab.
///           Shares configured using .site will not append a title to Messages but will have a subtitle in Mail.
///     tab:  Include a URL and a tab to share. If sharing a tab with an active webView, then additional sharing
///           options can be configured, including printing the page and adding the webpage to your iOS home screen.
///           __SPECIAL NOTE__: If you download a PDF, you can view that in a tab. In that case, the URL may have a `file://`
///            scheme instead of `http(s)://`, so certain options, like Send to Device / Add to Home Screen, may not be
///            available.
enum ShareType {
    case file(url: URL, remoteURL: URL?)
    case site(url: URL)
    case tab(url: URL, tab: any ShareTab)

    /// The share URL wrapped by the given type.
    var wrappedURL: URL {
        switch self {
        case let .file(url, _):
            return url
        case let .site(url):
            return url
        case let .tab(url, _):
            return url
        }
    }

    /// The plain text name of this share type.
    var typeName: String {
        switch self {
        case .file:
            return "file"
        case .site:
            return "site"
        case .tab:
            return "tab"
        }
    }
}
