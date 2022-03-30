// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol CanRemoveQuickActionBookmark {
    var profile: Profile { get }
    func removeBookmarkShortcut()
}

// Extension to easily remove a bookmark from the quick actions
extension CanRemoveQuickActionBookmark {

    func removeBookmarkShortcut() {
        // Get most recent bookmark
        profile.places.getRecentBookmarks(limit: 1).uponQueue(.main) { result in
            guard let bookmarkItems = result.successValue else { return }
            if bookmarkItems.count == 0 {
                // Remove the openLastBookmark shortcut
                QuickActions.sharedInstance.removeDynamicApplicationShortcutItemOfType(.openLastBookmark, fromApplication: .shared)
            } else {
                // Update the last bookmark shortcut
                let userData = [QuickActions.TabURLKey: bookmarkItems[0].url, QuickActions.TabTitleKey: bookmarkItems[0].title]
                QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark, withUserData: userData, toApplication: .shared)
            }
        }
    }
}
