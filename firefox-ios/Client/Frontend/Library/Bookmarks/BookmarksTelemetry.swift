// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct BookmarksTelemetry {
    private let gleanWrapper: GleanWrapper

    enum EventLabel: String {
        case bookmarksPanel = "bookmarks-panel"
        case topSites = "top-sites"
    }

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func addBookmarkFolder() {
        gleanWrapper.recordEvent(for: GleanMetrics.Bookmarks.folderAdd)
    }

    func deleteBookmark() {
        gleanWrapper.recordLabel(for: GleanMetrics.Bookmarks.delete,
                                 label: EventLabel.bookmarksPanel.rawValue)
    }

    func openBookmarksSite(eventLabel: EventLabel) {
        gleanWrapper.recordLabel(for: GleanMetrics.Bookmarks.open, label: eventLabel.rawValue)
    }

    func editBookmark(eventLabel: EventLabel) {
        gleanWrapper.recordLabel(for: GleanMetrics.Bookmarks.edit, label: eventLabel.rawValue)
    }
}
