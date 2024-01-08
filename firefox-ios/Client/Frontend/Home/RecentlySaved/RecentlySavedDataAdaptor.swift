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

class RecentlySavedDataAdaptorImplementation: RecentlySavedDataAdaptor, Notifiable {
    var notificationCenter: NotificationProtocol
    private let bookmarkItemsLimit: UInt = 5
    private let readingListItemsLimit: Int = 5
    private let recentItemsHelper = RecentItemsHelper()
    private var readingList: ReadingList
    private var bookmarksHandler: BookmarksHandler
    private var recentBookmarks = [RecentlySavedBookmark]()
    private var readingListItems = [ReadingListItem]()

    weak var delegate: RecentlySavedDelegate?

    init(readingList: ReadingList,
         bookmarksHandler: BookmarksHandler,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        self.readingList = readingList
        self.bookmarksHandler = bookmarksHandler

        setupNotifications(forObserver: self,
                           observing: [.ReadingListUpdated,
                                       .BookmarksUpdated,
                                       .RustPlacesOpened])

        getRecentBookmarks()
        getReadingLists()
    }

    func getRecentlySavedData() -> [RecentlySavedItem] {
        var items = [RecentlySavedItem]()
        items.append(contentsOf: recentBookmarks)
        items.append(contentsOf: readingListItems)

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
        recentBookmarks = recentItemsHelper.filterStaleItems(recentItems: bookmarks) as? [RecentlySavedBookmark] ?? []
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

    // MARK: - Reading list

    private func getReadingLists() {
        let maxItems = readingListItemsLimit
        readingList.getAvailableRecords { readingList in
            let items = readingList.prefix(maxItems)
            self.updateReadingList(readingList: Array(items))
        }
    }

    private func updateReadingList(readingList: [ReadingListItem]) {
        readingListItems = recentItemsHelper.filterStaleItems(recentItems: readingList) as? [ReadingListItem] ?? []
        delegate?.didLoadNewData()

        let extra = [
            TelemetryWrapper.EventObject.recentlySavedReadingItemImpressions.rawValue: "\(readingListItems.count)"
        ]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .recentlySavedReadingListView,
                                     extras: extra)
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .ReadingListUpdated:
            getReadingLists()
        case .BookmarksUpdated, .RustPlacesOpened:
            getRecentBookmarks()
        default: break
        }
    }
}
