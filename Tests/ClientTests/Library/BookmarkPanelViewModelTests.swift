// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import Shared

@testable import Client

class BookmarksPanelViewModelTests: XCTestCase {

    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
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

    func testShouldReload_whenMobileEmptyBookmarks() {
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
        profile.reopen()
        let subject = createSubject(guid: BookmarkRoots.MenuFolderGUID)
        let expectation = expectation(description: "Subject reloaded")
        subject.reloadData {
            XCTAssertNotNil(subject.bookmarkFolder)
            XCTAssertEqual(subject.bookmarkNodes.count, 0, "Contains no bookmarks")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}

extension BookmarksPanelViewModelTests {

    func createSubject(guid: GUID) -> BookmarksPanelViewModel {
        let viewModel = BookmarksPanelViewModel(profile: profile,
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
    var isRoot: Bool = false
    var title: String

    init(title: String) {
        self.title = title
    }
}
