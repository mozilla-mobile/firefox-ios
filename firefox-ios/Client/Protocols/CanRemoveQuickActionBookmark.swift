// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol CanRemoveQuickActionBookmark {
    var bookmarksHandler: BookmarksHandler { get }
    func removeBookmarkShortcut(quickAction: QuickActions)
}

// Extension to easily remove a bookmark from the quick actions
extension CanRemoveQuickActionBookmark {
    func removeBookmarkShortcut(quickAction: QuickActions = QuickActionsImplementation()) {
        // Get most recent bookmark
        bookmarksHandler.getRecentBookmarks(limit: 1) { bookmarkItems in
            ensureMainThread {
                self.removeBookmarks(quickAction: quickAction,
                                     bookmarkItems: bookmarkItems)
            }
        }
    }

    private func removeBookmarks(quickAction: QuickActions, bookmarkItems: [BookmarkItemData]) {
        if bookmarkItems.isEmpty {
            // Remove the openLastBookmark shortcut
            quickAction.removeDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                   fromApplication: .shared)
        } else {
            // Update the last bookmark shortcut
            let userData = [QuickActionInfos.tabURLKey: bookmarkItems[0].url,
                            QuickActionInfos.tabTitleKey: bookmarkItems[0].title]
            quickAction.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                withUserData: userData,
                                                                toApplication: .shared)
        }
    }
}
