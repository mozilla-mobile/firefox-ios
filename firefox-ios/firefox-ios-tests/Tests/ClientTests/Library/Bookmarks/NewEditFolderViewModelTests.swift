// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaRustComponents
import Shared

@testable import Client

@MainActor
final class NewEditFolderViewModelTests: XCTestCase {
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
    var folderFetcher: MockNewFolderHierarchyFetcher!
    var bookmarksSaver: MockBookmarksSaver!
    var profile: MockProfile!
    var parentFolderSelector: MockParentFolderSelector!

    override func setUp() async throws {
        try await super.setUp()
        folderFetcher = MockNewFolderHierarchyFetcher()
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

    func testControllerTitle_whenEditingFolder() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)

        XCTAssertEqual(subject.controllerTitle, .BookmarksEditFolder)
    }

    func testControllerTitle_whenCreatingNewFolder() {
        let subject = createSubject(folder: nil, parentFolder: parentFolder)

        XCTAssertEqual(subject.controllerTitle, .BookmarksNewFolder)
    }

    func testBeginBrowsingFolders_setsIsBrowsingFoldersTrue() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)

        subject.beginBrowsingFolders()

        XCTAssertTrue(subject.isBrowsingFolders)
    }

    func testSelectFolder_setsIsBrowsingFoldersFalse() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        subject.beginBrowsingFolders()

        subject.selectFolder(NewFolder(title: "Test", guid: "", indentation: 0))

        XCTAssertFalse(subject.isBrowsingFolders)
    }

    func testSelectFolder_callsOnFolderStatusUpdate() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }
        subject.selectFolder(NewFolder(title: "Test", guid: "", indentation: 0))

        waitForExpectations(timeout: 0.1)
    }

    func testBeginBrowsingFolders_callsGetFolderStructure() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let expectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            expectation.fulfill()
        }

        subject.beginBrowsingFolders()

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(folderFetcher.fetchFoldersCalled, 1)
        XCTAssertEqual(folderFetcher.capturedExcludedGuids, [folder.guid])
    }

    func testToggleGroupExpansion_togglesIsExpanded() {
        let subject = createSubject(folder: folder, parentFolder: parentFolder)
        let loadExpectation = expectation(description: "onFolderStatusUpdate should be called")
        subject.onFolderStatusUpdate = {
            loadExpectation.fulfill()
        }
        subject.beginBrowsingFolders()
        waitForExpectations(timeout: 0.1)
        let initialValue = subject.folderGroups[0].isExpanded

        subject.toggleGroupExpansion(at: 0)

        XCTAssertNotEqual(subject.folderGroups[0].isExpanded, initialValue)
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

    func createSubject(folder: FxBookmarkNode?,
                       parentFolder: FxBookmarkNode,
                       file: StaticString = #filePath,
                       line: UInt = #line) -> NewEditFolderViewModel {
        let subject = NewEditFolderViewModel(profile: profile,
                                             parentFolder: parentFolder,
                                             folder: folder,
                                             bookmarkSaver: bookmarksSaver,
                                             folderFetcher: folderFetcher)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

final class MockNewFolderHierarchyFetcher: NewFolderHierarchyFetcher, @unchecked Sendable {
    var mockFolderStructures: [NewFolder] = []
    private(set) var fetchFoldersCalled = 0
    private(set) var capturedExcludedGuids: [String] = []

    func fetchFolders(excludedGuids: [String]) async -> [NewFolder] {
        fetchFoldersCalled += 1
        capturedExcludedGuids = excludedGuids
        return mockFolderStructures
    }
}
