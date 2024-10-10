// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Storage
import XCTest

@testable import Client

class CanRemoveQuickActionBookmarkTests: XCTestCase {
    private var subject: MockCanRemoveQuickActionBookmark!
    private var mockBookmarksHandler: BookmarksHandlerMock!
    private var mockQuickActions: MockQuickActions!

    override func setUp() {
        super.setUp()
        mockQuickActions = MockQuickActions()
        mockBookmarksHandler = BookmarksHandlerMock()
        subject = MockCanRemoveQuickActionBookmark(bookmarksHandler: mockBookmarksHandler)
    }

    override func tearDown() {
        mockQuickActions = nil
        mockBookmarksHandler = nil
        subject = nil
        super.tearDown()
    }

    func testWithoutBookmarks() {
        subject.removeBookmarkShortcut(quickAction: mockQuickActions)
        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: [])

        XCTAssertEqual(mockBookmarksHandler.getRecentBookmarksCallCount, 1)
        XCTAssertEqual(mockQuickActions.removeWasCalled, 1)
        XCTAssertEqual(mockQuickActions.addWithUserDataCalled, 0)
        XCTAssertEqual(mockQuickActions.addFromShareItemCalled, 0)
    }

    func testWithBookmarks() {
        subject.removeBookmarkShortcut(quickAction: mockQuickActions)
        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: getMockBookmarks())

        XCTAssertEqual(mockBookmarksHandler.getRecentBookmarksCallCount, 1)
        XCTAssertEqual(mockQuickActions.removeWasCalled, 0)
        XCTAssertEqual(mockQuickActions.addWithUserDataCalled, 1)
        XCTAssertEqual(mockQuickActions.addFromShareItemCalled, 0)
    }
}

// MARK: - Helper methods
private extension CanRemoveQuickActionBookmarkTests {
    func getMockBookmarks() -> [BookmarkItemData] {
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

// MARK: - CanRemoveQuickActionBookmarkMock
private class MockCanRemoveQuickActionBookmark: CanRemoveQuickActionBookmark {
    var bookmarksHandler: BookmarksHandler

    init(bookmarksHandler: BookmarksHandler) {
        self.bookmarksHandler = bookmarksHandler
    }
}

// MARK: - MockQuickActions
class MockQuickActions: QuickActions {
    var addFromShareItemCalled = 0
    func addDynamicApplicationShortcutItemOfType(_ type: ShortcutType,
                                                 fromShareItem shareItem: ShareItem,
                                                 toApplication application: UIApplication) {
        addFromShareItemCalled += 1
    }

    var addWithUserDataCalled = 0
    func addDynamicApplicationShortcutItemOfType(_ type: ShortcutType,
                                                 withUserData userData: [String: String],
                                                 toApplication application: UIApplication) {
        addWithUserDataCalled += 1
    }

    var removeWasCalled = 0
    func removeDynamicApplicationShortcutItemOfType(_ type: ShortcutType,
                                                    fromApplication application: UIApplication) {
        removeWasCalled += 1
    }

    var handleShortCutItemCalled = 0
    func handleShortCutItem(
        _ shortcutItem: UIApplicationShortcutItem,
        withBrowserViewController bvc: BrowserViewController,
        completionHandler: @escaping (Bool) -> Void
    ) {
        handleShortCutItemCalled += 1
        completionHandler(true)
    }
}
