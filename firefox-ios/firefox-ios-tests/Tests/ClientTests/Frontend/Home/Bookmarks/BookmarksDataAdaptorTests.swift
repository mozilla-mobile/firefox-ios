// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Storage
import XCTest

@testable import Client

class BookmarksDataAdaptorTests: XCTestCase {
    var subject: BookmarksDataAdaptor!
    var mockBookmarksHandler: BookmarksHandlerMock!
    var mockNotificationCenter: MockNotificationCenter!
    var mockDelegate: BookmarksDelegateMock?

    override func setUp() {
        super.setUp()
        mockBookmarksHandler = BookmarksHandlerMock()
        mockNotificationCenter = MockNotificationCenter()
        mockDelegate = BookmarksDelegateMock()
    }

    override func tearDown() {
        mockBookmarksHandler = nil
        mockNotificationCenter = nil
        subject = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - getSavedData

    // With bookmarks
    func testGetRecentlySavedData_withBookmarksAndNoReadingItems() {
        initializeSubject()

        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: getMockBookmarks())

        let savedData = subject.getBookmarkData()

        XCTAssert(savedData.count == 1)
        XCTAssert(mockBookmarksHandler.getRecentBookmarksCallCount == 1)
        XCTAssert(mockDelegate?.didLoadNewDataCallCount == 1)
    }

    // With no bookmarks
    func testGetBookmarksData_withNoItems() {
        initializeSubject()

        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: [])

        let savedData = subject.getBookmarkData()

        XCTAssert(savedData.isEmpty)
        XCTAssert(mockBookmarksHandler.getRecentBookmarksCallCount == 1)
        XCTAssert(mockDelegate?.didLoadNewDataCallCount == 1)
    }

    // MARK: - Bookmark Notifications

    func testBookmarksUpdateFromNotification() {
        initializeSubject()

        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: [])

        mockNotificationCenter.post(name: .BookmarksUpdated)

        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: getMockBookmarks())

        let savedData = subject.getBookmarkData()

        XCTAssert(savedData.count == 1)
        XCTAssert(mockBookmarksHandler.getRecentBookmarksCallCount == 2)
        XCTAssert(mockDelegate?.didLoadNewDataCallCount == 2)
    }

    // MARK: - Helper functions

    private func initializeSubject() {
        let subject = BookmarksDataAdaptorImplementation(bookmarksHandler: mockBookmarksHandler,
                                                         notificationCenter: mockNotificationCenter)
        subject.delegate = mockDelegate
        mockNotificationCenter.notifiableListener = subject
        self.subject = subject
    }

    private func getMockBookmarks() -> [BookmarkItemData] {
        let one = BookmarkItemData(guid: "abc",
                                   dateAdded: Int64(Date().toTimestamp()),
                                   lastModified: Int64(Date().toTimestamp()),
                                   parentGUID: "123",
                                   position: 0,
                                   url: "www.firefox.com",
                                   title: "bookmark1")
        return [one]
    }
}
