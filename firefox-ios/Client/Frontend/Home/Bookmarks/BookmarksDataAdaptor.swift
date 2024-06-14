// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

protocol BookmarksDataAdaptor {
    func getBookmarkData() -> [BookmarkItem]
}

protocol BookmarksDelegate: AnyObject {
    func didLoadNewData()
}

class BookmarksDataAdaptorImplementation: BookmarksDataAdaptor, Notifiable {
    var notificationCenter: NotificationProtocol
    private let bookmarkItemsLimit: UInt = 8
    private var bookmarksHandler: BookmarksHandler
    private var homepageBookmarks = [Bookmark]()

    weak var delegate: BookmarksDelegate?

    init(bookmarksHandler: BookmarksHandler,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        self.bookmarksHandler = bookmarksHandler

        setupNotifications(forObserver: self,
                           observing: [.BookmarksUpdated,
                                       .RustPlacesOpened])

        getBookmarks()
    }

    func getBookmarkData() -> [BookmarkItem] {
        var items = [BookmarkItem]()
        items.append(contentsOf: homepageBookmarks)

        return items
    }

    // MARK: - Bookmarks

    private func getBookmarks() {
        bookmarksHandler.getRecentBookmarks(limit: bookmarkItemsLimit) { bookmarks in
            let bookmarks = bookmarks.map { Bookmark(bookmark: $0) }
            self.updateBookmarks(updatedBookmarks: bookmarks)
        }
    }

    private func updateBookmarks(updatedBookmarks: [Bookmark]) {
        homepageBookmarks = updatedBookmarks
        delegate?.didLoadNewData()

        // Send telemetry if bookmarks aren't empty
        if !homepageBookmarks.isEmpty {
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .view,
                object: .firefoxHomepage,
                value: .bookmarkItemView,
                extras: [
                    TelemetryWrapper.EventObject.bookmarkImpressions.rawValue: "\(updatedBookmarks.count)"
                ]
            )
        }
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .BookmarksUpdated, .RustPlacesOpened:
            getBookmarks()
        default: break
        }
    }
}
