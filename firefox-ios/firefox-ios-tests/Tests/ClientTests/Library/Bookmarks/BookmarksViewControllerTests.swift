// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

@MainActor
final class BookmarksViewControllerTests: XCTestCase {
    private var profile: MockProfile!
    private let displayedFolder = MockFxBookmarkNode(type: .folder,
                                                     guid: "displayed-folder",
                                                     parentGUID: nil,
                                                     position: 0,
                                                     isRoot: false,
                                                     title: "Bookmarks")

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        try await super.tearDown()
    }

    func testParentFolder_whenTheNodeLivesElsewhere_returnsItsOwnFolder() async {
        let handler = MockBookmarksHandler(folderData: folderData(guid: "other-folder", title: "Other"))
        let subject = createSubject(bookmarksHandler: handler)

        let folder = await subject.parentFolder(of: searchHit(parentGUID: "other-folder"),
                                                whenDisplaying: displayedFolder)

        XCTAssertEqual(folder.guid, "other-folder")
        XCTAssertEqual(handler.lastGetBookmarksTreeRootGUID, "other-folder")
    }

    func testParentFolder_whenTheNodeIsInTheDisplayedFolder_doesNotLookItUp() async {
        let handler = MockBookmarksHandler()
        let subject = createSubject(bookmarksHandler: handler)

        let folder = await subject.parentFolder(of: searchHit(parentGUID: displayedFolder.guid),
                                                whenDisplaying: displayedFolder)

        XCTAssertEqual(folder.guid, displayedFolder.guid)
        XCTAssertEqual(handler.getBookmarksTreeWithCompletionCalled, 0)
    }

    func testParentFolder_whenTheNodeHasNoParent_keepsTheDisplayedFolder() async {
        let handler = MockBookmarksHandler()
        let subject = createSubject(bookmarksHandler: handler)

        let folder = await subject.parentFolder(of: searchHit(parentGUID: nil),
                                                whenDisplaying: displayedFolder)

        XCTAssertEqual(folder.guid, displayedFolder.guid)
        XCTAssertEqual(handler.getBookmarksTreeWithCompletionCalled, 0)
    }

    func testParentFolder_whenTheLookupFails_keepsTheDisplayedFolder() async {
        let handler = MockBookmarksHandler()
        handler.getBookmarksTreeResult = .failure(TestError.lookupFailed)
        let subject = createSubject(bookmarksHandler: handler)

        let folder = await subject.parentFolder(of: searchHit(parentGUID: "other-folder"),
                                                whenDisplaying: displayedFolder)

        XCTAssertEqual(folder.guid, displayedFolder.guid)
    }

    func testParentFolder_whenTheLookupReturnsSomethingOtherThanAFolder_keepsTheDisplayedFolder() async {
        let handler = MockBookmarksHandler()
        handler.getBookmarksTreeResult = .success(nil)
        let subject = createSubject(bookmarksHandler: handler)

        let folder = await subject.parentFolder(of: searchHit(parentGUID: "other-folder"),
                                                whenDisplaying: displayedFolder)

        XCTAssertEqual(folder.guid, displayedFolder.guid)
    }

    // MARK: - Private

    private enum TestError: Error {
        case lookupFailed
    }

    private func createSubject(
        bookmarksHandler: BookmarksHandler,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BookmarksViewController {
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarksHandler: bookmarksHandler,
                                                bookmarkFolderGUID: BookmarkRoots.MobileFolderGUID)
        let subject = BookmarksViewController(viewModel: viewModel, windowUUID: .XCTestDefaultUUID)
        subject.bookmarksHandler = bookmarksHandler
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func searchHit(parentGUID: String?) -> MockFxBookmarkNode {
        return MockFxBookmarkNode(type: .bookmark,
                                  guid: "search-hit",
                                  parentGUID: parentGUID,
                                  position: 0,
                                  isRoot: false,
                                  title: "A bookmark")
    }

    private func folderData(guid: String, title: String) -> BookmarkFolderData {
        return BookmarkFolderData(guid: guid,
                                  dateAdded: 0,
                                  lastModified: 0,
                                  parentGUID: nil,
                                  position: 0,
                                  title: title,
                                  childGUIDs: [],
                                  children: nil)
    }
}
