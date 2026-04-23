// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

@MainActor
final class BookmarksPanelViewModelTests: XCTestCase, LegacyFeatureFlaggable {
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
    }

    override func tearDown() async throws {
        profile = nil
        DependencyHelperMock().reset()
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
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 0)
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
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 0, "Contains no folders")
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
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 3, "Contains the 3 desktop folders")
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
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 0, "Contains no bookmarks")
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
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 1, "Mobile folder contains the local desktop folder")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testReloadData_doesntCreateDesktopBookmarksFolder() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)
        let expectation = expectation(description: "Subject reloaded")
        subject.reloadData {
            XCTAssertNotNil(subject.bookmarkFolder)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 0, "Mobile folder does not contain local desktop folder")
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

    func testMoveRowAtGetNewIndex_MobileGuid_showingDesktopFolder_zeroIndex() {
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID)

        createDesktopBookmark(subject: subject) {
            let index = subject.getNewIndex(from: 0)
            XCTAssertEqual(index, 0)
        }
    }

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

        subject.getSiteDetails(for: bookmark) { site in
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

        subject.getSiteDetails(for: bookmark) { site in
            expectation.fulfill()
            XCTAssertNotNil(site)
            XCTAssertTrue(site?.isPinnedSite ?? false)
        }

        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Search bookmarks

    func testSearchBookmarks_emptyQuery_returnsEmpty() {
        let handler = MockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "") {
            XCTAssertTrue(subject.isShowingSearchResults)
            XCTAssertTrue(subject.displayedBookmarkNodes.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_matchingTitle_returnsResults() {
        let handler = MockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "firefox") {
            XCTAssertTrue(subject.isShowingSearchResults)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 1)
            XCTAssertEqual(subject.displayedBookmarkNodes.first?.title, "Firefox")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_matchingURL_returnsResults() {
        let handler = MockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "mozilla.org") {
            XCTAssertTrue(subject.isShowingSearchResults)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 1)
            XCTAssertEqual(subject.displayedBookmarkNodes.first?.title, "Mozilla")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_noMatches_returnsEmpty() {
        let handler = MockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "nonexistent") {
            XCTAssertTrue(subject.isShowingSearchResults)
            XCTAssertTrue(subject.displayedBookmarkNodes.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_caseInsensitive_returnsResults() {
        let handler = MockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "FIREFOX") {
            XCTAssertTrue(subject.isShowingSearchResults)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 1)
            XCTAssertEqual(subject.displayedBookmarkNodes.first?.title, "Firefox")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_recursiveInSubfolders_returnsResults() {
        let handler = MockBookmarksHandler(folderData: createFolderWithNestedBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        subject.searchBookmarks(query: "nested") {
            XCTAssertTrue(subject.isShowingSearchResults)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 1)
            XCTAssertEqual(subject.displayedBookmarkNodes.first?.title, "Nested Bookmark")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSearchBookmarks_matchesMultipleResults() {
        let handler = MockBookmarksHandler(folderData: createFolderWithBookmarks())
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: handler)
        let expectation = expectation(description: "Search completed")

        // Both "Firefox" (url: https://www.firefox.com) and "Mozilla" (url: https://www.mozilla.org)
        // contain "www" in their URLs
        subject.searchBookmarks(query: "www") {
            XCTAssertTrue(subject.isShowingSearchResults)
            XCTAssertEqual(subject.displayedBookmarkNodes.count, 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testDeletingBookmark_reloadsDataAndSearchResults_ifSearching() throws {
        setupNimbusBookmarksSearchTesting(isEnabled: true)

        let bookmarksTree = createFolderWithBookmarks()
        let bookmarksHandler = MockBookmarksHandler(folderData: bookmarksTree)
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: bookmarksHandler)
        let fetchAndSearchBookmarks = expectation(description: "Fetch and search bookmarks completed")

        // Setup: Populate the bookmarks (2 total bookmarks) fully before starting search, as search state affects fetching
        subject.reloadData {
            // Search the test data (1 matching bookmark)
            subject.searchBookmarks(query: "firefox") {
                fetchAndSearchBookmarks.fulfill()
            }
        }

        waitForExpectations(timeout: 2)

        // Validate setup before starting test, reset handler state
        XCTAssertEqual(bookmarksHandler.getBookmarksTreeCalled, 2, "Called when fetching mobile bookmarks, and after search")
        XCTAssertEqual(bookmarksHandler.countBookmarksTreeCalled, 1, "Called after fetching mobile bookmarks")
        XCTAssertTrue(subject.isShowingSearchResults, "Should be true after searching")
        XCTAssertEqual(subject.displayedBookmarkNodes.count, 1, "1 of 2 bookmarks should be shown for search")
        bookmarksHandler.getBookmarksTreeCalled = 0
        bookmarksHandler.countBookmarksTreeCalled = 0

        // After search has completed, test that removing a bookmark eventually reloads the bookmarks tree and search results
        let removeExpectation = expectation(description: "Bookmark removal completed")

        // Remove the bookmark that is in the search results
        let bookmarkToRemove = try XCTUnwrap(bookmarksTree.children?[safe: 0] as? FxBookmarkNode)
        subject.remove(bookmark: bookmarkToRemove) {
            removeExpectation.fulfill()
        }

        waitForExpectations(timeout: 2)

        // Expect removing a bookmark to eventually refresh the tree
        XCTAssertEqual(bookmarksHandler.getBookmarksTreeCalled, 2, "It takes 2 calls to refresh bookmarks + re-search")
        XCTAssertEqual(bookmarksHandler.countBookmarksTreeCalled, 1, "Called after re-fetching mobile bookmarks")
        XCTAssertEqual(subject.displayedBookmarkNodes.count, 0, "One search result removed, in active search state")
    }

    func testDeletingBookmark_doesNotReloadDataOrSearchResults_ifNotSearching() throws {
        setupNimbusBookmarksSearchTesting(isEnabled: true)

        let bookmarksTree = createFolderWithBookmarks()
        let bookmarksHandler = MockBookmarksHandler(folderData: bookmarksTree)
        let subject = createSubject(guid: BookmarkRoots.MobileFolderGUID, bookmarksHandler: bookmarksHandler)
        let fetchBookmarks = expectation(description: "Fetch and search bookmarks completed")

        // Setup: Populate the bookmarks (2 total bookmarks) fully before starting search, as search state affects fetching
        subject.reloadData {
            fetchBookmarks.fulfill()
        }

        waitForExpectations(timeout: 2)

        // Validate setup before starting test, reset handler state
        XCTAssertEqual(bookmarksHandler.getBookmarksTreeCalled, 1, "Called when fetching mobile bookmarks")
        XCTAssertEqual(bookmarksHandler.countBookmarksTreeCalled, 1, "Called after fetching mobile bookmarks")
        XCTAssertFalse(subject.isShowingSearchResults, "Should be false after searching")
        XCTAssertEqual(subject.displayedBookmarkNodes.count, 2, "All bookmarks should be shown (not filtered by search)")
        bookmarksHandler.getBookmarksTreeCalled = 0
        bookmarksHandler.countBookmarksTreeCalled = 0

        // Test that removing a bookmark does NOT unnecessarily reload bookmark nodes when the user is not in search.
        // Reloading is only necessary if a bookmark outside the current folder was deleted, which can only happen in search
        // mode.
        let removeExpectation = expectation(description: "Bookmark removal completed")

        let bookmarkToRemove = try XCTUnwrap(bookmarksTree.children?[safe: 0] as? FxBookmarkNode)
        subject.remove(bookmark: bookmarkToRemove) {
            removeExpectation.fulfill()
        }

        waitForExpectations(timeout: 2)

        // Expect removing a bookmark to eventually refresh the tree
        XCTAssertEqual(bookmarksHandler.getBookmarksTreeCalled, 0, "Don't refresh when not in search mode")
        XCTAssertEqual(bookmarksHandler.countBookmarksTreeCalled, 0, "Don't refresh when not in search mode")
        XCTAssertEqual(subject.displayedBookmarkNodes.count, 1, "One of two bookmarks was removed")
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
        bookmarksHandler: BookmarksHandler = MockBookmarksHandler(),
        quickActions: QuickActions = MockQuickActions()
    ) -> BookmarksPanelViewModel {
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarksHandler: bookmarksHandler,
                                                bookmarkFolderGUID: guid,
                                                quickActions: quickActions)
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

    private func setupNimbusBookmarksSearchTesting(isEnabled: Bool) {
        FxNimbus.shared.features.bookmarksSearchFeature.with { _, _ in
            return BookmarksSearchFeature(enabled: isEnabled)
        }
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
        let deferred = Deferred<Maybe<Bool>>()
        deferred.fill(Maybe(success: isPinnedTopSite))
        return deferred
    }
}
