// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

@MainActor
final class BookmarksPanelViewModelTests: XCTestCase, FeatureFlaggable {
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() async throws {
        profile = nil
        try await super.tearDown()
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
        wait(for: [expectation], timeout: 1)
    }

    func testShouldReload_whenMobileEmptyBookmarks() throws {
        profile.reopen()
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        let expectation = expectation(description: "Subject reloaded")
        subject.reloadData {
            XCTAssertNotNil(subject.bookmarkFolder)
            XCTAssertEqual(subject.bookmarkNodes.count, 0, "Contains no folders")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
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
        wait(for: [expectation], timeout: 1)
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
        wait(for: [expectation], timeout: 1)
    }

    func testReloadData_createsDesktopBookmarksFolder() {
        let bookmarksHandler = MockBookmarksHandler()
        bookmarksHandler.bookmarksInTreeValue = 1
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: bookmarksHandler)
        let expectation = expectation(description: "Subject reloaded")
        subject.reloadData {
            XCTAssertNotNil(subject.bookmarkFolder)
            XCTAssertEqual(subject.bookmarkNodes.count, 1, "Mobile folder contains the local desktop folder")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testReloadData_doesntCreateDesktopBookmarksFolder() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        let expectation = expectation(description: "Subject reloaded")
        subject.reloadData {
            XCTAssertNotNil(subject.bookmarkFolder)
            XCTAssertEqual(subject.bookmarkNodes.count, 0, "Mobile folder does not contain the local desktop folder")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
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
        let expectedIndex = 0
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

    @MainActor
    func testMoveRowAtGetNewIndex_MobileGuid_showingDesktopFolder_zeroIndex() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)

        createDesktopBookmark(subject: subject) {
            let index = subject.getNewIndex(from: 0)
            XCTAssertEqual(index, 0)
        }
    }

    @MainActor
    func testMoveRowAtGetNewIndex_MobileGuid_showingDesktopFolder_minusIndex() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)

        createDesktopBookmark(subject: subject) {
            let index = subject.getNewIndex(from: -1)
            XCTAssertEqual(index, 0)
        }
    }

    func testMoveRowAtGetNewIndex_MobileGuid_hidingDesktopFolder_zeroIndex() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)

        let index = subject.getNewIndex(from: 0)
        XCTAssertEqual(index, 0)
    }

    func testMoveRowAtGetNewIndex_MobileGuid_hidingDesktopFolder_minusIndex() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)

        let index = subject.getNewIndex(from: -1)
        XCTAssertEqual(index, 0)
    }

    func testGetSiteDetails_whenNotPinnedTopSite_returnsBasicSite() {
        let expectation = expectation(description: "get site details")
        profile = MockProfile(
            injectedPinnedSites: MockPinnedSites(
                stubbedIsPinnedtopSite: false
            )
        )
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)

        let bookmark = createBookmarkItemData()
        subject.bookmarkNodes.append(bookmark)

        let indexPath = IndexPath(row: 0, section: 0)
        subject.getSiteDetails(for: indexPath) { site in
            XCTAssertNotNil(site)
            XCTAssertFalse(site?.isPinnedSite ?? true)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testGetSiteDetails_whenIsPinnedTopSite_returnsPinnedSite() {
        let expectation = expectation(description: "get site details")
        profile = MockProfile(
            injectedPinnedSites: MockPinnedSites(
                stubbedIsPinnedtopSite: true
            )
        )
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)

        let bookmark = createBookmarkItemData()
        subject.bookmarkNodes.append(bookmark)

        let indexPath = IndexPath(row: 0, section: 0)
        subject.getSiteDetails(for: indexPath) { site in
            expectation.fulfill()
            XCTAssertNotNil(site)
            XCTAssertTrue(site?.isPinnedSite ?? false)
        }

        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Search bookmarks

    func testSearchBookmarks_emptyQuery_returnsEmpty() {
        let handler = SearchableMockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "") {
            XCTAssertTrue(subject.isSearching)
            XCTAssertTrue(subject.displayedBookmarkNodes.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_matchingTitle_returnsResults() {
        let handler = SearchableMockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "firefox") {
            XCTAssertTrue(subject.isSearching)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 1)
            XCTAssertEqual(subject.displayedBookmarkNodes.first?.title, "Firefox")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_matchingURL_returnsResults() {
        let handler = SearchableMockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "mozilla.org") {
            XCTAssertTrue(subject.isSearching)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 1)
            XCTAssertEqual(subject.displayedBookmarkNodes.first?.title, "Mozilla")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_noMatches_returnsEmpty() {
        let handler = SearchableMockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "nonexistent") {
            XCTAssertTrue(subject.isSearching)
            XCTAssertTrue(subject.displayedBookmarkNodes.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_caseInsensitive_returnsResults() {
        let handler = SearchableMockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "FIREFOX") {
            XCTAssertTrue(subject.isSearching)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 1)
            XCTAssertEqual(subject.displayedBookmarkNodes.first?.title, "Firefox")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_recursiveInSubfolders_returnsResults() {
        let handler = SearchableMockBookmarksHandler(folderData: createFolderWithNestedBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "nested") {
            XCTAssertTrue(subject.isSearching)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 1)
            XCTAssertEqual(subject.displayedBookmarkNodes.first?.title, "Nested Bookmark")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_matchesMultipleResults() {
        let handler = SearchableMockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        // Both "Firefox" (url: https://www.firefox.com) and "Mozilla" (url: https://www.mozilla.org)
        // contain "www" in their URLs
        subject.searchBookmarks(query: "www") {
            XCTAssertTrue(subject.isSearching)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Search test helpers

    private func createFolderWithBookmarks() -> BookmarkFolderData {
        let timestamp = Int64(Date().toTimestamp())
        let bookmark1 = BookmarkItemData(
            guid: "b1",
            dateAdded: timestamp,
            lastModified: timestamp,
            parentGUID: BookmarkRoots.MobileFolderGUID,
            position: 0,
            url: "https://www.firefox.com",
            title: "Firefox"
        )
        let bookmark2 = BookmarkItemData(
            guid: "b2",
            dateAdded: timestamp,
            lastModified: timestamp,
            parentGUID: BookmarkRoots.MobileFolderGUID,
            position: 1,
            url: "https://www.mozilla.org",
            title: "Mozilla"
        )
        return BookmarkFolderData(
            guid: BookmarkRoots.MobileFolderGUID,
            dateAdded: timestamp,
            lastModified: timestamp,
            parentGUID: BookmarkRoots.RootGUID,
            position: 0,
            title: "Mobile Bookmarks",
            childGUIDs: ["b1", "b2"],
            children: [bookmark1, bookmark2]
        )
    }

    private func createFolderWithNestedBookmarks() -> BookmarkFolderData {
        let timestamp = Int64(Date().toTimestamp())
        let nestedBookmark = BookmarkItemData(
            guid: "nb1",
            dateAdded: timestamp,
            lastModified: timestamp,
            parentGUID: "subfolder1",
            position: 0,
            url: "https://nested.example.com",
            title: "Nested Bookmark"
        )
        let subfolder = BookmarkFolderData(
            guid: "subfolder1",
            dateAdded: timestamp,
            lastModified: timestamp,
            parentGUID: BookmarkRoots.MobileFolderGUID,
            position: 0,
            title: "Subfolder",
            childGUIDs: ["nb1"],
            children: [nestedBookmark]
        )
        let topBookmark = BookmarkItemData(
            guid: "tb1",
            dateAdded: timestamp,
            lastModified: timestamp,
            parentGUID: BookmarkRoots.MobileFolderGUID,
            position: 1,
            url: "https://www.firefox.com",
            title: "Firefox"
        )
        return BookmarkFolderData(
            guid: BookmarkRoots.MobileFolderGUID,
            dateAdded: timestamp,
            lastModified: timestamp,
            parentGUID: BookmarkRoots.RootGUID,
            position: 0,
            title: "Mobile Bookmarks",
            childGUIDs: ["subfolder1", "tb1"],
            children: [subfolder, topBookmark]
        )
    }

    private func createSubject(
        guid: GUID,
        bookmarksHandler: BookmarksHandler = MockBookmarksHandler()
    ) -> BookmarksPanelViewModel {
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarksHandler: bookmarksHandler,
                                                bookmarkFolderGUID: guid)
        trackForMemoryLeaks(viewModel)
        return viewModel
    }

    private func createBookmarkItemData() -> BookmarkItemData {
        return BookmarkItemData(
            guid: "abc",
            dateAdded: Int64(Date().toTimestamp()),
            lastModified: Int64(Date().toTimestamp()),
            parentGUID: "123",
            position: 0,
            url: "www.firefox.com",
            title: "bookmark1"
        )
    }

    private func createBookmarksNode(count: Int) -> [FxBookmarkNode] {
        var nodes = [FxBookmarkNode]()
        (0..<count).forEach { index in
            let node = MockBookmarkNode(title: "Bookmark title \(index)")
            nodes.append(node)
        }
        return nodes
    }

    private func createDesktopBookmark(subject: BookmarksPanelViewModel, completion: @escaping @MainActor () -> Void) {
        let expectation = expectation(description: "Subject reloaded")

        profile.places.createBookmark(
            parentGUID: BookmarkRoots.MenuFolderGUID,
            url: "https://www.firefox.com",
            title: "Firefox",
            position: 0
        ).uponQueue(.main) { [profile] _ in
            profile.places.countBookmarksInTrees(folderGuids: [BookmarkRoots.MenuFolderGUID]) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        subject.reloadData {
                            completion()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    XCTFail("Failed to count bookmarks: \(error)")
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 5)
    }
}

// MARK: - Mocks
// TODO: FXIOS-12903 This is unchecked sendable because BookmarkNodeType in rust components
private final class MockBookmarkNode: @unchecked Sendable, FxBookmarkNode {
    let type: BookmarkNodeType
    let guid: String
    let parentGUID: String?
    let position: UInt32
    let isRoot: Bool
    let title: String

    init(
        title: String,
        type: BookmarkNodeType = .bookmark,
        guid: String = "12345",
        parentGUID: String? = nil,
        position: UInt32 = 0,
        isRoot: Bool = false
    ) {
        self.title = title
        self.type = type
        self.guid = guid
        self.parentGUID = parentGUID
        self.position = position
        self.isRoot = isRoot
    }
}

private final class MockPinnedSites: MockablePinnedSites, @unchecked Sendable {
    let isPinnedTopSite: Bool

    init(stubbedIsPinnedtopSite: Bool) {
        isPinnedTopSite = stubbedIsPinnedtopSite
    }

    override func isPinnedTopSite(_ url: String) -> Deferred<Maybe<Bool>> {
        let deffered = Deferred<Maybe<Bool>>()
        deffered.fill(Maybe(success: isPinnedTopSite))
        return deffered
    }
}

/// A mock handler that returns a configurable `BookmarkFolderData` for search tests.
private final class SearchableMockBookmarksHandler: BookmarksHandler, @unchecked Sendable {
    private let folderData: BookmarkFolderData

    init(folderData: BookmarkFolderData) {
        self.folderData = folderData
    }

    func getRecentBookmarks(limit: UInt, completion: @escaping ([BookmarkItemData]) -> Void) {
        completion([])
    }

    func getBookmarksTree(rootGUID: GUID, recursive: Bool) -> Deferred<Maybe<BookmarkNodeData?>> {
        let result = Deferred<Maybe<BookmarkNodeData?>>()
        result.fill(Maybe(success: folderData))
        return result
    }

    func getBookmarksTree(
        rootGUID: GUID,
        recursive: Bool,
        completion: @escaping (Result<BookmarkNodeData?, any Error>) -> Void
    ) {
        completion(.success(folderData))
    }

    func updateBookmarkNode(guid: GUID,
                            parentGUID: GUID?,
                            position: UInt32?,
                            title: String?,
                            url: String?) -> Success {
        succeed()
    }

    func updateBookmarkNode(
        guid: GUID,
        parentGUID: GUID?,
        position: UInt32?,
        title: String?,
        url: String?,
        completion: @escaping (Result<Void, any Error>) -> Void
    ) {
        completion(.success(()))
    }

    func countBookmarksInTrees(folderGuids: [GUID], completion: @escaping (Result<Int, Error>) -> Void) {
        completion(.success(0))
    }

    func isBookmarked(url: String, completion: @escaping @Sendable (Result<Bool, Error>) -> Void) {
        completion(.success(false))
    }
}
