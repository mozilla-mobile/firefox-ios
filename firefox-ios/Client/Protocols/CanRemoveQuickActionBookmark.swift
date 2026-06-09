// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

import class MozillaAppServices.BookmarkItemData

protocol CanRemoveQuickActionBookmark: Sendable {
    @MainActor
    var bookmarksHandler: BookmarksHandler { get }

    @MainActor
    static func removeBookmarkShortcut(
        withBookmarksHandler bookmarksHandler: BookmarksHandler,
        withQuickActions quickActions: QuickActions
    )
}

// Extension to easily remove a bookmark from the quick actions
extension CanRemoveQuickActionBookmark {
    @MainActor
    static func removeBookmarkShortcut(
        withBookmarksHandler bookmarksHandler: BookmarksHandler,
        withQuickActions quickActions: QuickActions = QuickActionsImplementation()
    ) {
        // Get most recent bookmark
        bookmarksHandler.getRecentBookmarks(limit: 1) { bookmarkItems in
            ensureMainThread {
                if bookmarkItems.isEmpty {
                    // Remove the openLastBookmark shortcut
                    quickActions.removeDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                            fromApplication: .shared)
                } else {
                    // Update the last bookmark shortcut
                    let userData = [QuickActionInfos.tabURLKey: bookmarkItems[0].url,
                                    QuickActionInfos.tabTitleKey: bookmarkItems[0].title]
                    quickActions.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                         withUserData: userData,
                                                                         toApplication: .shared)
                }
            }
        }
    }
}
