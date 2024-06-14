// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

protocol RecentlySavedDataAdaptor {
    func getRecentlySavedData() -> [RecentlySavedItem]
}

protocol RecentlySavedDelegate: AnyObject {
    func didLoadNewData()
}

class BookmarksDataAdaptorImplementation: RecentlySavedDataAdaptor, Notifiable {
    var notificationCenter: NotificationProtocol
    private let bookmarkItemsLimit: UInt = 8
    private let recentItemsHelper = RecentItemsHelper()
    private var bookmarksHandler: BookmarksHandler
    private var homepageBookmarks = [RecentlySavedBookmark]()

    weak var delegate: RecentlySavedDelegate?

    init(bookmarksHandler: BookmarksHandler,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        self.bookmarksHandler = bookmarksHandler

        setupNotifications(forObserver: self,
                           observing: [.BookmarksUpdated,
                                       .RustPlacesOpened])

        getBookmarks()
    }

    func getRecentlySavedData() -> [RecentlySavedItem] {
        var items = [RecentlySavedItem]()
        items.append(contentsOf: homepageBookmarks)

        return items
    }

    // MARK: - Bookmarks

    private func getBookmarks() {
        bookmarksHandler.getRecentBookmarks(limit: bookmarkItemsLimit) { bookmarks in
            let bookmarks = bookmarks.map { RecentlySavedBookmark(bookmark: $0) }
            self.updateBookmarks(updatedBookmarks: bookmarks)
        }
    }

    private func updateBookmarks(updatedBookmarks: [RecentlySavedBookmark]) {
        homepageBookmarks = updatedBookmarks
        delegate?.didLoadNewData()

        // Send telemetry if bookmarks aren't empty
        if !homepageBookmarks.isEmpty {
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .view,
                object: .firefoxHomepage,
                value: .recentlySavedBookmarkItemView,
                extras: [
                    TelemetryWrapper.EventObject.recentlySavedBookmarkImpressions.rawValue: "\(updatedBookmarks.count)"
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
