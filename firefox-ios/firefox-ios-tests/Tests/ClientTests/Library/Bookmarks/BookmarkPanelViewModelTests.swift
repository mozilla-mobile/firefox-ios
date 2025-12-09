// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

final class BookmarksPanelViewModelTests: XCTestCase, FeatureFlaggable {
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
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
        let bookmarksHandler = BookmarksHandlerMock()
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

    private func createSubject(
        guid: GUID,
        bookmarksHandler: BookmarksHandler = BookmarksHandlerMock()
    ) -> BookmarksPanelViewModel {
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarksHandler: bookmarksHandler,
                                                bookmarkFolderGUID: guid,
                                                mainQueue: MockDispatchQueue())
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

    @MainActor
    private func createDesktopBookmark(subject: BookmarksPanelViewModel, completion: @Sendable @escaping () -> Void) {
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
                    subject.reloadData {
                        completion()
                        expectation.fulfill()
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
