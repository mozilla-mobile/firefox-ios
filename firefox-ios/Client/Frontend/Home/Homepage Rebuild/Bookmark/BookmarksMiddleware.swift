// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage

final class BookmarksMiddleware {
    private let bookmarksHandler: BookmarksHandler
    private let bookmarkItemsLimit: UInt = 8

    init(profile: Profile = AppContainer.shared.resolve()) {
        self.bookmarksHandler = profile.places
    }

    lazy var bookmarksProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID

        switch action.actionType {
        case HomepageActionType.initialize, HomepageMiddlewareActionType.bookmarksUpdated:
            self.handleInitializeBookmarksAction(windowUUID: windowUUID)
        default:
           break
        }
    }

    private func handleInitializeBookmarksAction(windowUUID: WindowUUID) {
        bookmarksHandler.getRecentBookmarks(limit: bookmarkItemsLimit) { [weak self] bookmarks in
            let bookmarks = bookmarks.map {
                BookmarkConfiguration(
                    site: Site.createBasicSite(
                        url: $0.url,
                        title: $0.title,
                        isBookmarked: true
                    )
                )
            }
            self?.dispatchBookmarksAction(windowUUID: windowUUID, updatedBookmarks: bookmarks)
        }
    }

    private func dispatchBookmarksAction(windowUUID: WindowUUID, updatedBookmarks: [BookmarkConfiguration]) {
        let newAction = BookmarksAction(
            bookmarks: updatedBookmarks,
            windowUUID: windowUUID,
            actionType: BookmarksMiddlewareActionType.initialize
        )
        store.dispatchLegacy(newAction)
    }
}
