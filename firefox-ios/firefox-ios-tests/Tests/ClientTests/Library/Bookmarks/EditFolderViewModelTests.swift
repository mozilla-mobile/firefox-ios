// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaRustComponents
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

        XCTAssertFalse(subject.isBrowsingFolders)
        XCTAssertTrue(subject.folderGroups.isEmpty)
        XCTAssertEqual(subject.selectedFolder?.title, parentFolder.title)
        XCTAssertEqual(subject.selectedFolder?.guid, parentFolder.guid)
    }

    func testSelectFolder_updatesSelectionAndCollapsesBackToSummary() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }

        subject.selectFolder(Folder(title: "Test", guid: "", indentation: 0))

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(subject.selectedFolder?.title, "Test")
        XCTAssertFalse(subject.isBrowsingFolders)
    }

    func testBeginBrowsingFolders_fetchesAndPopulatesFolderGroups() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }

        subject.beginBrowsingFolders()

        waitForExpectations(timeout: 0.1)
        XCTAssertTrue(subject.isBrowsingFolders)
        XCTAssertEqual(folderFetcher.fetchFoldersCalled, 1)

        let allGroupedFolders = subject.folderGroups.flatMap { $0.folders }
        XCTAssertEqual(allGroupedFolders, folderFetcher.mockFolderStructures)
    }

    func testToggleGroupExpansion_togglesIsExpandedAndCallsCallback() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let loadExpectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            loadExpectation.fulfill()
        }
        subject.beginBrowsingFolders()
        waitForExpectations(timeout: 0.1)

        guard !subject.folderGroups.isEmpty else {
            XCTFail("Expected at least one folder group to test toggling against")
            return
        }
        let initialExpansionState = subject.folderGroups[0].isExpanded

        let toggleExpectation = expectation(description: "onGroupExpansionUpdate should be called")
        subject.onGroupExpansionUpdate = { index in
            XCTAssertEqual(index, 0)
            toggleExpectation.fulfill()
        }
        subject.toggleGroupExpansion(at: 0)

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(subject.folderGroups[0].isExpanded, !initialExpansionState)
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
