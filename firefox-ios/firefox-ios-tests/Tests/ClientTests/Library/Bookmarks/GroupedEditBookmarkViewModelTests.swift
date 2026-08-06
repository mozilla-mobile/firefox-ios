// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
import Shared

@testable import Client

@MainActor
class GroupedEditBookmarkViewModelTests: XCTestCase {
    let folder = MockFxBookmarkNode(type: .folder,
                                    guid: "1235",
                                    position: 1,
                                    isRoot: false,
                                    title: "Hello")
    var parentFolder = MockFxBookmarkNode(type: .folder,
                                          guid: "5678",
                                          position: 0,
                                          isRoot: false,
                                          title: "Parent")
    var folderBookmarkItemData = BookmarkItemData(guid: "Hello",
                                                  dateAdded: 0,
                                                  lastModified: 0,
                                                  parentGUID: nil,
                                                  position: 0,
                                                  url: "",
                                                  title: "Hello")
    var folderFetcher: MockGroupedFolderHierarchyFetcher!
    var bookmarksSaver: MockBookmarksSaver!
    var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        folderFetcher = MockGroupedFolderHierarchyFetcher()
        bookmarksSaver = MockBookmarksSaver()
        profile = MockProfile()
    }

    override func tearDown() async throws {
        folderFetcher = nil
        bookmarksSaver = nil
        profile = nil
        try await super.tearDown()
    }

    func testInit() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)

        XCTAssertTrue(subject.isFolderCollapsed)
        XCTAssertTrue(!subject.folderStructures.isEmpty)
        XCTAssertEqual(subject.selectedFolder?.title, parentFolder.title)
        XCTAssertEqual(subject.selectedFolder?.guid, parentFolder.guid)
    }

    func testShouldShowDisclosureIndicator_whenIsFolderSelected() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let folder = GroupedFolder(title: folder.title, guid: folder.guid, indentation: 0)

        subject.selectFolder(folder)

        XCTAssertTrue(subject.shouldShowDisclosureIndicatorForFolder(folder))
    }

    func testShouldShowDisclosureIndicator_whenIsNotFolderSelected() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let folder = GroupedFolder(title: folder.title, guid: folder.guid, indentation: 0)

        XCTAssertFalse(subject.shouldShowDisclosureIndicatorForFolder(folder))
    }

    func testShouldShowDisclosureIndicator_whenIsFolderCollapsed() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let folder = GroupedFolder(title: folder.title, guid: folder.guid, indentation: 0)

        subject.selectFolder(folder)
        // Double selecting a folder turns isFolderCollapsed to true
        subject.selectFolder(folder)

        XCTAssertFalse(subject.shouldShowDisclosureIndicatorForFolder(folder))
        XCTAssertTrue(subject.isFolderCollapsed)
    }

    func testBackNavigationButtonTitle_whenIsMobileFolderGuid() {
        parentFolder.guid = "mobile______"
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        XCTAssertEqual(subject.getBackNavigationButtonTitle, "All")
    }

    func testBackNavigationButtonTitle_whenIsNotMobileFolderGuid() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        XCTAssertEqual(subject.getBackNavigationButtonTitle, parentFolder.title)
    }

    func testSelectFolder_callsOnFolderStatusUpdate() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }
        subject.selectFolder(GroupedFolder(title: "Test", guid: "", indentation: 0))

        waitForExpectations(timeout: 0.1)
    }

    func testSelectFolder_callsGetFolderStructure() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }

        subject.selectFolder(GroupedFolder(title: "Test", guid: "", indentation: 0))

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(folderFetcher.fetchFoldersCalled, 1)
    }

    // MARK: - Folder structure / placeholder insertion

    func testGetFolderStructure_insertsBothPlaceholders_whenDesktopAndMobileFoldersExist() {
        folderFetcher.mockFolderStructures = [
            GroupedFolder(title: "Mobile Bookmarks", guid: "mobile1", indentation: 0, isDesktopRoot: false),
            GroupedFolder(title: "Desktop Bookmarks", guid: "desktop1", indentation: 0, isDesktopRoot: true)
        ]
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }

        subject.selectFolder(GroupedFolder(title: "Test", guid: "", indentation: 0))

        waitForExpectations(timeout: 0.1)
        // mobile placeholder + mobile folder + desktop placeholder + desktop folder
        XCTAssertEqual(subject.folderStructures.count, 4)
        XCTAssertEqual(subject.folderStructures.first?.guid,
                       GroupedEditBookmarkViewModel.mobileHeaderPlaceholderGuid)
        XCTAssertEqual(subject.folderStructures[2].guid,
                       GroupedEditBookmarkViewModel.desktopHeaderPlaceholderGuid)
    }

    func testGetFolderStructure_omitsPlaceholders_whenNoDesktopFoldersExist() {
        folderFetcher.mockFolderStructures = [
            GroupedFolder(title: "Mobile Bookmarks", guid: "mobile1", indentation: 0, isDesktopRoot: false)
        ]
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }

        subject.selectFolder(GroupedFolder(title: "Test", guid: "", indentation: 0))

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(subject.folderStructures, folderFetcher.mockFolderStructures)
    }

    // MARK: - Save bookmark

    func testSaveBookmark_whenHasNoUpdateDoesntSave() async throws {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)

        let task = subject.saveBookmark()

        XCTAssertNil(task)
        XCTAssertEqual(bookmarksSaver.saveCalled, 0)
    }

    func testSaveBookmark_whenHasEmptyGuid_thenSetsRecentBookmarksPrefsString() async throws {
        let subject = createSubject(folder: folderBookmarkItemData, parentFolder: parentFolder)
        let expectation = expectation(description: "onBookmarkSaved should be called")
        subject.onBookmarkSaved = {
            expectation.fulfill()
        }

        subject.setUpdatedTitle("Hello test")
        let task = subject.saveBookmark()
        await task?.value

        await fulfillment(of: [expectation])
        let prefs = try XCTUnwrap(profile.prefs as? MockProfilePrefs)
        let recentBookmark = try XCTUnwrap(prefs.things[PrefsKeys.RecentBookmarkFolder] as? String)
        XCTAssertEqual(recentBookmark, "5678")
        XCTAssertEqual(bookmarksSaver.saveCalled, 1)
    }

    func testSave_whenHasDifferentGuid_thenSetsRecentBookmarksPrefsString() async throws {
        let expectedGuid = "09876"
        bookmarksSaver.mockCreateGuid = expectedGuid
        profile.prefs.setString(expectedGuid, forKey: PrefsKeys.RecentBookmarkFolder)

        let subject = createSubject(folder: folderBookmarkItemData, parentFolder: parentFolder)
        let expectation = expectation(description: "onBookmarkSaved should be called")
        subject.onBookmarkSaved = {
            expectation.fulfill()
        }

        subject.setUpdatedTitle("Hello test")
        let task = subject.saveBookmark()
        await task?.value

        await fulfillment(of: [expectation])
        let prefs = try XCTUnwrap(profile.prefs as? MockProfilePrefs)
        let recentBookmark = try XCTUnwrap(prefs.things[PrefsKeys.RecentBookmarkFolder] as? String)
        XCTAssertEqual(recentBookmark, "5678")
        XCTAssertEqual(bookmarksSaver.saveCalled, 1)
    }

    // MARK: - GroupedParentFolderSelector

    func testSelectFolderCreatedFromChild_ensureFolderIsCollapsed() {
        let subject = createSubject(folder: folderBookmarkItemData, parentFolder: parentFolder)
        let folderToSelect = GroupedFolder(title: folder.title, guid: folder.guid, indentation: 0)

        subject.selectFolder(folderToSelect)
        subject.selectFolderCreatedFromChild(folder: folderToSelect)

        XCTAssertTrue(subject.isFolderCollapsed)
    }

    func testSelectFolderCreatedFromChild_ensureFolderSelectedUpdates() {
        let subject = createSubject(folder: folderBookmarkItemData, parentFolder: parentFolder)
        let folderToSelect = GroupedFolder(title: folder.title, guid: folder.guid, indentation: 0)

        subject.selectFolderCreatedFromChild(folder: folderToSelect)

        XCTAssertEqual(subject.selectedFolder, folderToSelect)
        XCTAssertEqual(subject.folderStructures, [folderToSelect])
    }

    func testSelectFolderCreatedFromChild_ensureOnFolderStatusUpdateIsCalled() {
        let subject = createSubject(folder: folderBookmarkItemData, parentFolder: parentFolder)
        let folderToSelect = GroupedFolder(title: folder.title, guid: folder.guid, indentation: 0)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }

        subject.selectFolderCreatedFromChild(folder: folderToSelect)

        waitForExpectations(timeout: 0.1)
    }

    // MARK: Helper function

    func createSubject(folder: FxBookmarkNode,
                       parentFolder: FxBookmarkNode,
                       file: StaticString = #filePath,
                       line: UInt = #line) -> GroupedEditBookmarkViewModel {
        let subject = GroupedEditBookmarkViewModel(parentFolder: parentFolder,
                                                   node: folder,
                                                   profile: profile,
                                                   bookmarksSaver: bookmarksSaver,
                                                   folderFetcher: folderFetcher)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
