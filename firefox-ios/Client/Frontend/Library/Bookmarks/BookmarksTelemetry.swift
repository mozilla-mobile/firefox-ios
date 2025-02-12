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
        case activityStream = "activity-stream"
        case pageActionMenu = "page-action-menu"
        case addBookmarkToast = "add-bookmark-toast"
    }

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func addBookmark(eventLabel: EventLabel) {
        gleanWrapper.recordLabel(for: GleanMetrics.Bookmarks.add,
                                 label: eventLabel.rawValue)
    }

    func deleteBookmark(eventLabel: EventLabel) {
        gleanWrapper.recordLabel(for: GleanMetrics.Bookmarks.delete,
                                 label: eventLabel.rawValue)
    }

    func openBookmarksSite(eventLabel: EventLabel) {
        gleanWrapper.recordLabel(for: GleanMetrics.Bookmarks.open,
                                 label: eventLabel.rawValue)
    }

    func editBookmark(eventLabel: EventLabel) {
        gleanWrapper.recordLabel(for: GleanMetrics.Bookmarks.edit,
                                 label: eventLabel.rawValue)
    }

     func addBookmarkFolder() {
         gleanWrapper.recordEvent(for: GleanMetrics.Bookmarks.folderAdd)
     }
}
