// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaRustComponents
import MozillaAppServices
import Shared

@testable import Client

@MainActor
final class EditFolderViewModelTests: XCTestCase {
    let folder = MockFxBookmarkNode(type: .folder,
                                    guid: "1235",
                                    position: 1,
                                    isRoot: false,
                                    title: "Hello")
    let emptyTitleFolder = MockFxBookmarkNode(type: .folder,
                                              guid: "1235",
                                              position: 1,
                                              isRoot: false,
                                              title: "")
    let parentFolder = MockFxBookmarkNode(type: .folder,
                                          guid: "5678",
                                          position: 0,
                                          isRoot: false,
                                          title: "Parent")
    var folderFetcher: MockFolderHierarchyFetcher!
    var bookmarksSaver: MockBookmarksSaver!
    var profile: MockProfile!
    var parentFolderSelector: MockParentFolderSelector!

    override func setUp() async throws {
        try await super.setUp()
        folderFetcher = MockFolderHierarchyFetcher()
        bookmarksSaver = MockBookmarksSaver()
        profile = MockProfile()
        parentFolderSelector = MockParentFolderSelector()
    }

    override func tearDown() async throws {
        folderFetcher = nil
        bookmarksSaver = nil
        profile = nil
        parentFolderSelector = nil
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

        XCTAssertFalse(subject.shouldShowDisclosureIndicator(isFolderSelected: true))
    }

    func testShouldShowDisclosureIndicator_whenIsNotFolderSelected() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)

        XCTAssertFalse(subject.shouldShowDisclosureIndicator(isFolderSelected: false))
    }

    func testShouldShowDisclosureIndicator_whenIsNotFolderSelectedAfterSelectFolder() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        subject.selectFolder(Folder(title: "Test", guid: "", indentation: 0))

        XCTAssertTrue(subject.shouldShowDisclosureIndicator(isFolderSelected: true))
    }

    func testSelectFolder_callsOnFolderStatusUpdate() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }
        subject.selectFolder(Folder(title: "Test", guid: "", indentation: 0))

        waitForExpectations(timeout: 0.1)
    }

    func testSelectFolder_callsGetFolderStructure() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }

        subject.selectFolder(Folder(title: "Test", guid: "", indentation: 0))

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(folderFetcher.fetchFoldersCalled, 1)
        XCTAssertEqual(folderFetcher.mockFolderStructures, subject.folderStructures)
    }

    func testSave_whenEmptyFolder_thenDoesntSave() throws {
        let subject = createSubject(folder: emptyTitleFolder, parentFolder: parentFolder)
        subject.save()

        XCTAssertEqual(bookmarksSaver.saveCalled, 0)
    }

    func testSave_whenNilGuidReturned_thenCallsSaveBookmarkButNoRecentBookmark() async throws {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onBookmarkSaved should be called")
        subject.onBookmarkSaved = {
            expectation.fulfill()
        }

        let task = subject.save()
        await task?.value

        await fulfillment(of: [expectation])
        let prefs = try XCTUnwrap(profile.prefs as? MockProfilePrefs)
        XCTAssertNil(prefs.things[PrefsKeys.RecentBookmarkFolder])
        XCTAssertEqual(bookmarksSaver.saveCalled, 1)
    }

    func testSave_whenHasGuidSavesRecentBookmark() async throws {
        let expectedGuid = "09876"
        bookmarksSaver.mockCreateGuid = expectedGuid
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onBookmarkSaved should be called")
        subject.onBookmarkSaved = {
            expectation.fulfill()
        }

        let task = subject.save()
        await task?.value

        await fulfillment(of: [expectation])
        let prefs = try XCTUnwrap(profile.prefs as? MockProfilePrefs)
        let recentBookmarkGuid = try XCTUnwrap(prefs.things[PrefsKeys.RecentBookmarkFolder] as? String)
        XCTAssertEqual(recentBookmarkGuid, expectedGuid)
        XCTAssertEqual(bookmarksSaver.saveCalled, 1)
    }

    func testSave_whenHasGuidCallsParentFolderSelector() async throws {
        let expectedGuid = "09876"
        bookmarksSaver.mockCreateGuid = expectedGuid
        profile.prefs.setString(expectedGuid, forKey: PrefsKeys.RecentBookmarkFolder)
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        subject.parentFolderSelector = parentFolderSelector

        let task = subject.save()
        await task?.value

        XCTAssertNotNil(parentFolderSelector.selectedFolder)
    }

    func testSaveBookmarks_createsNamedFolderInSelectedParent() async {
        bookmarksSaver.mockCreateGuid = "new-folder"
        let subject = makeBatchSubject()
        subject.selectFolder(parentFolderSelection)
        subject.selectFolder(parentFolderSelection)
        await subject.save()?.value

        XCTAssertTrue(subject.saveSucceeded)
        XCTAssertEqual(bookmarksSaver.savedNodes.map(\.title), ["Trip", "First", "Second"])
        XCTAssertEqual(bookmarksSaver.savedParentGUIDs, ["destination", "new-folder", "new-folder"])
    }

    func testSaveBookmarks_retryDoesNotDuplicateSuccessfulBookmarks() async {
        bookmarksSaver.mockCreateGuid = "new-folder"
        bookmarksSaver.failingSaveCalls = [3]
        let subject = makeBatchSubject()
        var failures = 0
        subject.onSaveFailed = { failures += 1 }
        await subject.save()?.value
        XCTAssertFalse(subject.saveSucceeded)
        XCTAssertEqual(failures, 1)

        await subject.save()?.value

        XCTAssertTrue(subject.saveSucceeded)
        XCTAssertEqual(bookmarksSaver.savedNodes.map(\.title), ["Trip", "First", "Second", "Trip", "Second"])
        XCTAssertEqual(bookmarksSaver.savedNodes[3].guid, "new-folder")
        XCTAssertNotNil(bookmarksSaver.savedNodes[3].parentGUID)
    }

    func testSaveBookmarks_folderFailureDoesNotSaveTabs() async {
        bookmarksSaver.failingSaveCalls = [1]
        let subject = makeBatchSubject()
        await subject.save()?.value
        XCTAssertFalse(subject.saveSucceeded)
        XCTAssertEqual(bookmarksSaver.saveCalled, 1)
    }

    func testSaveBookmarks_missingFolderGUIDDoesNotReportSuccess() async {
        let subject = makeBatchSubject()
        await subject.save()?.value
        XCTAssertFalse(subject.saveSucceeded)
        XCTAssertEqual(bookmarksSaver.saveCalled, 1)
    }

    func testSaveBookmarks_rejectsBlankNameAndConcurrentSave() async {
        let subject = makeBatchSubject()
        subject.updateFolderTitle("  ")
        XCTAssertNil(subject.save())
        subject.updateFolderTitle("Trip")
        let task = subject.save()
        XCTAssertNil(subject.save())
        await task?.value
    }

    private var parentFolderSelection: Folder {
        Folder(title: "Destination", guid: "destination", indentation: 0)
    }

    private func makeBatchSubject() -> EditFolderViewModel {
        let bookmarks = ["First", "Second"].map {
            BookmarkItemData(guid: "", dateAdded: 0, lastModified: 0, parentGUID: nil,
                             position: 0, url: "https://example.com/\($0)", title: $0)
        }
        let subject = EditFolderViewModel(profile: profile,
                                          parentFolder: parentFolder,
                                          folder: nil,
                                          bookmarkSaver: bookmarksSaver,
                                          folderFetcher: folderFetcher,
                                          bookmarksToSave: bookmarks)
        subject.updateFolderTitle("Trip")
        return subject
    }

    // MARK: Helper function

    func createSubject(folder: FxBookmarkNode,
                       parentFolder: FxBookmarkNode,
                       file: StaticString = #filePath,
                       line: UInt = #line) -> EditFolderViewModel {
        let subject = EditFolderViewModel(profile: profile,
                                          parentFolder: parentFolder,
                                          folder: folder,
                                          bookmarkSaver: bookmarksSaver,
                                          folderFetcher: folderFetcher)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
