// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

class BookmarksPanelViewModelTests: XCTestCase {
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
    }

    override func tearDown() {
        profile = nil
        super.tearDown()
    }

    func testIsRootNode_falseWhenMenu() {
        let subject = createSubject(guid: BookmarkRoots.MenuFolderGUID)
        XCTAssertFalse(subject.isRootNode)
    }

    func testIsRootNode_trueWhenMobile() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        XCTAssertTrue(subject.isRootNode)
    }

    func testShouldFlashRow_defaultIsFalse() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        XCTAssertFalse(subject.shouldFlashRow)
    }

    func testShouldFlashRow_trueWhenAddedBookmark() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        subject.didAddBookmarkNode()
        XCTAssertTrue(subject.shouldFlashRow)
        XCTAssertFalse(subject.shouldFlashRow, "Flash row only once")
    }

    func testShouldNotReload_whenProfileIsShutDown() {
        profile.shutdown()
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        let expectation = expectation(description: "Subject reloaded")
        subject.reloadData {
            XCTAssertNil(subject.bookmarkFolder)
            XCTAssertEqual(subject.bookmarkNodes.count, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testShouldReload_whenMobileEmptyBookmarks() throws {
        profile.reopen()
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        let expectation = expectation(description: "Subject reloaded")
        subject.reloadData {
            XCTAssertNotNil(subject.bookmarkFolder)
            XCTAssertEqual(subject.bookmarkNodes.count, 1, "Contains the local desktop folder")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testShouldReload_whenLocalDesktopFolder() {
        profile.reopen()
        let subject = createSubject(guid: LocalDesktopFolder.localDesktopFolderGuid)
        let expectation = expectation(description: "Subject reloaded")
        subject.reloadData {
            XCTAssertNil(subject.bookmarkFolder)
            XCTAssertEqual(subject.bookmarkNodes.count, 3, "Contains the 3 desktop folders")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testShouldReload_whenMenuFolder() {
        // The test passes without a clean database, however
        // it fails when run with all of ClientTest. We give it a
        // separate databasePrefix so it isn't affected by other tests
        profile = MockProfile(databasePrefix: "testShouldReload_whenMenuFolder")
        let subject = createSubject(guid: BookmarkRoots.MenuFolderGUID)
        let expectation = expectation(description: "Subject reloaded")
        subject.reloadData {
            XCTAssertNotNil(subject.bookmarkFolder)
            XCTAssertEqual(subject.bookmarkNodes.count, 0, "Contains no bookmarks")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - Move row at index

    func testMoveRowAtGetNewIndex_NotMobileGuid_atZero() {
        let subject = createSubject(guid: BookmarkRoots.MenuFolderGUID)
        let expectedIndex = 0
        let index = subject.getNewIndex(from: expectedIndex)
        XCTAssertEqual(index, expectedIndex)
    }

    func testMoveRowAtGetNewIndex_NotMobileGuid_minusIndex() {
        let subject = createSubject(guid: BookmarkRoots.MenuFolderGUID)
        let expectedIndex = -1
        let index = subject.getNewIndex(from: expectedIndex)
        XCTAssertEqual(index, expectedIndex)
    }

    func testMoveRowAtGetNewIndex_NotMobileGuid_atFive() {
        let subject = createSubject(guid: BookmarkRoots.MenuFolderGUID)
        let expectedIndex = 5
        let index = subject.getNewIndex(from: expectedIndex)
        XCTAssertEqual(index, expectedIndex)
    }

    func testMoveRowAtGetNewIndex_MobileGuid_zeroIndex() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        let index = subject.getNewIndex(from: 0)
        XCTAssertEqual(index, 0)
    }

    func testMoveRowAtGetNewIndex_MobileGuid_minusIndex() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        let index = subject.getNewIndex(from: -1)
        XCTAssertEqual(index, 0)
    }

    func testMoveRowAtGetNewIndex_MobileGuid_atFive() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        let index = subject.getNewIndex(from: 5)
        XCTAssertEqual(index, 4)
    }
}

extension BookmarksPanelViewModelTests {
    func createSubject(guid: GUID) -> BookmarksPanelViewModel {
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarksHandler: BookmarksHandlerMock(),
                                                bookmarkFolderGUID: guid)
        trackForMemoryLeaks(viewModel)
        return viewModel
    }

    func createBookmarksNode(count: Int) -> [FxBookmarkNode] {
        var nodes = [FxBookmarkNode]()
        (0..<count).forEach { index in
            let node = MockBookmarkNode(title: "Bookmark title \(index)")
            nodes.append(node)
        }
        return nodes
    }
}

class MockBookmarkNode: FxBookmarkNode {
    var type: BookmarkNodeType = .bookmark
    var guid: String = "12345"
    var parentGUID: String?
    var position: UInt32 = 0
    var isRoot = false
    var title: String

    init(title: String) {
        self.title = title
    }
}
