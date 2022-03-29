// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol CanRemoveQuickActionBookMark {
    var profile: Profile { get }
    func removeBookmarkShortcut()
}

extension CanRemoveQuickActionBookMark {

    func removeBookmarkShortcut() {
        let dataQueue = DispatchQueue(label: "com.moz.removeShortcut.queue")

        // Get most recent bookmark
        profile.places.getRecentBookmarks(limit: 1).uponQueue(dataQueue) { result in
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
