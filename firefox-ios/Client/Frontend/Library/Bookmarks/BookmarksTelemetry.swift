// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct BookmarksTelemetry {
    private let gleanWrapper: GleanWrapper
    private let label = "bookmarks-panel"

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func addBookmarkFolder() {
        gleanWrapper.recordEvent(for: GleanMetrics.Bookmarks.folderAdd)
    }

    func deleteBookmark() {
        gleanWrapper.recordLabel(for: GleanMetrics.Bookmarks.delete, label: label)
    }

    func openBookmarksPanel() {
        gleanWrapper.recordLabel(for: GleanMetrics.Bookmarks.open, label: label)
    }
}
