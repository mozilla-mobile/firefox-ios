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
    private var recentBookmarks = [RecentlySavedBookmark]()

    weak var delegate: RecentlySavedDelegate?

    init(bookmarksHandler: BookmarksHandler,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        self.bookmarksHandler = bookmarksHandler

        setupNotifications(forObserver: self,
                           observing: [.ReadingListUpdated,
                                       .BookmarksUpdated,
                                       .RustPlacesOpened])

        getRecentBookmarks()
    }

    func getRecentlySavedData() -> [RecentlySavedItem] {
        var items = [RecentlySavedItem]()
        items.append(contentsOf: recentBookmarks)

        return items
    }

    // MARK: - Bookmarks

    private func getRecentBookmarks() {
        bookmarksHandler.getRecentBookmarks(limit: bookmarkItemsLimit) { bookmarks in
            let bookmarks = bookmarks.map { RecentlySavedBookmark(bookmark: $0) }
            self.updateRecentBookmarks(bookmarks: bookmarks)
        }
    }

    private func updateRecentBookmarks(bookmarks: [RecentlySavedBookmark]) {
        recentBookmarks = bookmarks
        delegate?.didLoadNewData()

        // Send telemetry if bookmarks aren't empty
        if !recentBookmarks.isEmpty {
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .view,
                object: .firefoxHomepage,
                value: .recentlySavedBookmarkItemView,
                extras: [
                    TelemetryWrapper.EventObject.recentlySavedBookmarkImpressions.rawValue: "\(bookmarks.count)"
                ]
            )
        }
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .BookmarksUpdated, .RustPlacesOpened:
            getRecentBookmarks()
        default: break
        }
    }
}
