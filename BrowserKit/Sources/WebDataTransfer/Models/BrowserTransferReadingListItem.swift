// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A reading list entry exchanged with another browser. Unread, favorite, and archived state stay in Firefox's
/// reading list and are not transferred.
///
/// Platform-independent counterpart of Apple's `BEBrowserDataReadingListItem`.
/// https://developer.apple.com/documentation/browserkit/bebrowserdatareadinglistitem
public struct BrowserTransferReadingListItem: Sendable, Equatable {
    public let url: URL
    public let title: String
    public let lastVisitDate: Date?

    public init(url: URL, title: String, lastVisitDate: Date?) {
        self.url = url
        self.title = title
        self.lastVisitDate = lastVisitDate
    }
}
