// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest
import Storage
import Shared

class RecentItemsHelperTests: XCTestCase {
    private let bookmarkCutoffDate = 10
    private let readingListCutoffdate = 7

    func testEmptyRecentItems_returnsEmpty() {
        let recentItemsHelper = RecentItemsHelper()
        let result = recentItemsHelper.filterStaleItems(recentItems: [])
        XCTAssertEqual(result.count, 0)
    }

    // MARK: Bookmarks

    func testBookmarkItem_withNowDate() {
        let recentItemsHelper = RecentItemsHelper()
        let bookmarksItems = [createBookmarkItem()]
        let result = recentItemsHelper.filterStaleItems(recentItems: bookmarksItems)
        XCTAssertEqual(result.count, 1)
    }

    func testMultipleBookmarkItems_withNowDate() {
        let recentItemsHelper = RecentItemsHelper()
        let bookmarksItems = createBookmarksItems(count: 10)
        let result = recentItemsHelper.filterStaleItems(recentItems: bookmarksItems)
        XCTAssertEqual(result.count, 10)
    }

    func testBookmarkItem_withExactCutoffDate() {
        let recentItemsHelper = RecentItemsHelper()
        let exactDate = Calendar.current.add(numberOfDays: -bookmarkCutoffDate, to: Date())!
        let bookmarksItems = [createBookmarkItem(date: exactDate)]
        let result = recentItemsHelper.filterStaleItems(recentItems: bookmarksItems)
        XCTAssertEqual(result.count, 1)
    }

    func testBookmarkItem_withPastDatePastCutoff() {
        let recentItemsHelper = RecentItemsHelper()
        let pastDate = Calendar.current.add(numberOfDays: -bookmarkCutoffDate - 1, to: Date())!
        let bookmarksItems = [createBookmarkItem(date: pastDate)]
        let result = recentItemsHelper.filterStaleItems(recentItems: bookmarksItems)
        XCTAssertEqual(result.count, 0)
    }

    func testBookmarkItem_withPastDateBeforeCutoff() {
        let recentItemsHelper = RecentItemsHelper()
        let beforeCutoff = Calendar.current.add(numberOfDays: -bookmarkCutoffDate + 1, to: Date())!
        let bookmarksItems = [createBookmarkItem(date: beforeCutoff)]
        let result = recentItemsHelper.filterStaleItems(recentItems: bookmarksItems)
        XCTAssertEqual(result.count, 1)
    }

    func testBookmarkItem_withFutureDate() {
        let recentItemsHelper = RecentItemsHelper()
        let futureDate = Calendar.current.add(numberOfDays: bookmarkCutoffDate, to: Date())!
        let bookmarksItems = [createBookmarkItem(date: futureDate)]
        let result = recentItemsHelper.filterStaleItems(recentItems: bookmarksItems)
        XCTAssertEqual(result.count, 1)
    }

    func testMultipleBookmarkItems_withMixedDates() {
        let recentItemsHelper = RecentItemsHelper()
        let pastDate = Calendar.current.add(numberOfDays: -bookmarkCutoffDate - 1, to: Date())!
        let pastBookmarksItems = createBookmarksItems(count: 2, date: pastDate)

        let futureDate = Calendar.current.add(numberOfDays: bookmarkCutoffDate, to: Date())!
        let futureBookmarksItems = createBookmarksItems(count: 2, date: futureDate)

        let beforeCutoff = Calendar.current.add(numberOfDays: -bookmarkCutoffDate + 1, to: Date())!
        let beforeCutoffBookmarksItems = createBookmarksItems(count: 2, date: beforeCutoff)

        let exactDate = Calendar.current.add(numberOfDays: -bookmarkCutoffDate, to: Date())!
        let exactDateBookmarksItems = createBookmarksItems(count: 2, date: exactDate)

        var bookmarksItems = pastBookmarksItems
        bookmarksItems.append(contentsOf: futureBookmarksItems)
        bookmarksItems.append(contentsOf: beforeCutoffBookmarksItems)
        bookmarksItems.append(contentsOf: exactDateBookmarksItems)

        let result = recentItemsHelper.filterStaleItems(recentItems: bookmarksItems)
        XCTAssertEqual(result.count, 6)
    }

    // MARK: Reading List

    func testReadingListItem_withNowDate() {
        let recentItemsHelper = RecentItemsHelper()
        let readingListItems = [createReadingListItem()]
        let result = recentItemsHelper.filterStaleItems(recentItems: readingListItems)
        XCTAssertEqual(result.count, 1)
    }

    func testMultipleReadingListItem_withNowDate() {
        let recentItemsHelper = RecentItemsHelper()
        let readingListItems = createReadingListItems(count: 10)
        let result = recentItemsHelper.filterStaleItems(recentItems: readingListItems)
        XCTAssertEqual(result.count, 10)
    }

    func testReadingListItem_withExactCutoffDate() {
        let recentItemsHelper = RecentItemsHelper()
        let exactDate = Calendar.current.add(numberOfDays: -readingListCutoffdate, to: Date())!
        let readingListItems = [createReadingListItem(date: exactDate)]
        let result = recentItemsHelper.filterStaleItems(recentItems: readingListItems)
        XCTAssertEqual(result.count, 1)
    }

    func testReadingListItem_withPastDatePastCutoff() {
        let recentItemsHelper = RecentItemsHelper()
        let pastDate = Calendar.current.add(numberOfDays: -readingListCutoffdate - 1, to: Date())!
        let readingListItems = [createReadingListItem(date: pastDate)]
        let result = recentItemsHelper.filterStaleItems(recentItems: readingListItems)
        XCTAssertEqual(result.count, 0)
    }

    func testReadingListItem_withPastDateBeforeCutoff() {
        let recentItemsHelper = RecentItemsHelper()
        let beforeCutoff = Calendar.current.add(numberOfDays: -readingListCutoffdate + 1, to: Date())!
        let readingListItems = [createReadingListItem(date: beforeCutoff)]
        let result = recentItemsHelper.filterStaleItems(recentItems: readingListItems)
        XCTAssertEqual(result.count, 1)
    }

    func testReadingListItem_withFutureDate() {
        let recentItemsHelper = RecentItemsHelper()
        let futureDate = Calendar.current.add(numberOfDays: readingListCutoffdate, to: Date())!
        let readingListItems = [createReadingListItem(date: futureDate)]
        let result = recentItemsHelper.filterStaleItems(recentItems: readingListItems)
        XCTAssertEqual(result.count, 1)
    }

    func testMultipleRecentlySavedItems_withMixedDates() {
        let recentItemsHelper = RecentItemsHelper()
        let pastDate = Calendar.current.add(numberOfDays: -readingListCutoffdate - 1, to: Date())!
        let pastRecentlySavedItems = createReadingListItems(count: 2, date: pastDate)

        let futureDate = Calendar.current.add(numberOfDays: readingListCutoffdate, to: Date())!
        let futureRecentlySavedItems = createReadingListItems(count: 2, date: futureDate)

        let beforeCutoff = Calendar.current.add(numberOfDays: -readingListCutoffdate + 1, to: Date())!
        let beforeCutoffRecentlySavedItems = createReadingListItems(count: 2, date: beforeCutoff)

        let exactDate = Calendar.current.add(numberOfDays: -readingListCutoffdate, to: Date())!
        let exactDateRecentlySavedItems = createReadingListItems(count: 2, date: exactDate)

        var readingListItems = pastRecentlySavedItems
        readingListItems.append(contentsOf: futureRecentlySavedItems)
        readingListItems.append(contentsOf: beforeCutoffRecentlySavedItems)
        readingListItems.append(contentsOf: exactDateRecentlySavedItems)

        let result = recentItemsHelper.filterStaleItems(recentItems: readingListItems)
        XCTAssertEqual(result.count, 6)
    }
}

private extension RecentItemsHelperTests {
    func createBookmarksItems(count: Int, date: Date = Date()) -> [BookmarkItemData] {
        var items = [BookmarkItemData]()
        for _ in 0..<count {
            items.append(createBookmarkItem(date: date))
        }
        return items
    }

    func createBookmarkItem(date: Date = Date()) -> BookmarkItemData {
        let dateAdded = Int64(date.toTimestamp())
        return BookmarkItemData(
            guid: "",
            dateAdded: dateAdded,
            lastModified: 0,
            parentGUID: "",
            position: 0,
            url: "",
            title: ""
        )
    }

    func createReadingListItems(count: Int, date: Date = Date()) -> [ReadingListItem] {
        var items = [ReadingListItem]()
        for _ in 0..<count {
            items.append(createReadingListItem(date: date))
        }
        return items
    }

    func createReadingListItem(date: Date = Date()) -> ReadingListItem {
        // Reading list items are saved with timeIntervalSinceReferenceDate timestamp
        let lastModified = UInt64(1000 * date.timeIntervalSinceReferenceDate)
        return ReadingListItem(id: 0, lastModified: lastModified, url: "", title: "", addedBy: "")
    }
}
