// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import XCTest

@testable import Client

@MainActor
final class GroupedEditBookmarkViewControllerTests: XCTestCase {
    private var profile: MockProfile!

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

    func test_numberOfSections_returnsMainAndSelectFolderSections() {
        let subject = createSubject()

        XCTAssertEqual(subject.tableView.numberOfSections, 2)
    }

    func test_numberOfRows_mainSection_isAlwaysOne() {
        let subject = createSubject()

        XCTAssertEqual(subject.tableView.numberOfRows(inSection: 0), 1)
    }

    func test_numberOfRows_selectFolderSection_whenCollapsed_matchesFolderCount() {
        let subject = createSubject()

        XCTAssertEqual(subject.tableView.numberOfRows(inSection: 1), 1)
    }

    func test_cellForRow_mainSection_returnsEditBookmarkCell() {
        let subject = createSubject()

        let cell = subject.tableView.dataSource?.tableView(subject.tableView,
                                                           cellForRowAt: IndexPath(row: 0, section: 0))

        XCTAssertTrue(cell is EditBookmarkCell)
    }

    func test_cellForRow_selectFolderSection_returnsFolderTreeCell() {
        let subject = createSubject()

        let cell = subject.tableView.dataSource?.tableView(subject.tableView,
                                                           cellForRowAt: IndexPath(row: 0, section: 1))

        XCTAssertTrue(cell is FolderTreeCell)
    }

    func test_didSelectRow_folderCell_expandsAndFetchesFolders() {
        let fetcher = MockGroupedFolderHierarchyFetcher()
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        selectFolderAndWait(viewModel, subject: subject, indexPath: IndexPath(row: 0, section: 1))

        XCTAssertFalse(viewModel.isFolderCollapsed)
        XCTAssertEqual(fetcher.fetchFoldersCalled, 1)
    }

    func test_numberOfRows_selectFolderSection_whenExpanded_includesNewFolderCell() {
        let folders = [GroupedFolder(title: "Top", guid: "top", indentation: 0)]
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = folders
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        selectFolderAndWait(viewModel, subject: subject, indexPath: IndexPath(row: 0, section: 1))

        // folders returned by the fetcher, plus the "New Folder" row appended while expanded
        XCTAssertEqual(subject.tableView.numberOfRows(inSection: 1), folders.count + 1)
    }

    func test_cellForRow_newFolderRow_returnsOneLineTableViewCell() {
        let folders = [GroupedFolder(title: "Top", guid: "top", indentation: 0)]
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = folders
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        selectFolderAndWait(viewModel, subject: subject, indexPath: IndexPath(row: 0, section: 1))
        let newFolderRow = folders.count
        let cell = subject.tableView.dataSource?.tableView(
            subject.tableView,
            cellForRowAt: IndexPath(row: newFolderRow, section: 1)
        )

        XCTAssertTrue(cell is OneLineTableViewCell)
    }

    func test_didSelectRow_selectingFolder_collapsesAndUpdatesSelectedFolder() {
        let folder = GroupedFolder(title: "Top", guid: "top", indentation: 0)
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = [folder]
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        // Expand the list first
        selectFolderAndWait(viewModel, subject: subject, indexPath: IndexPath(row: 0, section: 1))
        // Selecting the folder again collapses the list synchronously
        subject.tableView(subject.tableView, didSelectRowAt: IndexPath(row: 0, section: 1))

        XCTAssertTrue(viewModel.isFolderCollapsed)
        XCTAssertEqual(viewModel.selectedFolder?.guid, folder.guid)
    }

    func test_willSelectRow_placeholderHeaderCell_returnsNil() {
        let placeholder = GroupedFolder(
            title: "",
            guid: GroupedEditBookmarkViewModel.mobileHeaderPlaceholderGuid,
            indentation: 0
        )
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = [placeholder]
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        selectFolderAndWait(viewModel, subject: subject, indexPath: IndexPath(row: 0, section: 1))
        let result = subject.tableView(subject.tableView, willSelectRowAt: IndexPath(row: 0, section: 1))

        XCTAssertNil(result)
    }

    func test_saveButtonAction_whenStandalone_savesBookmark() {
        let viewModel = createViewModel()
        let subject = createSubject(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: subject)
        _ = navController

        let expectation = XCTestExpectation(description: "bookmark saved")
        viewModel.onBookmarkSaved = { expectation.fulfill() }

        subject.saveButtonAction()

        wait(for: [expectation], timeout: 1.0)
    }

    func test_saveButtonAction_whenInLibrary_popsViewController() {
        let subject = createSubject()
        let navController = UINavigationController()
        navController.pushViewController(UIViewController(), animated: false)
        navController.pushViewController(subject, animated: false)

        subject.saveButtonAction()

        XCTAssertFalse(navController.viewControllers.contains(subject))
    }

    func test_saveButtonAction_whenInLibrary_savesBookmark() {
        let viewModel = createViewModel()
        let subject = createSubject(viewModel: viewModel)
        let navController = UINavigationController()
        navController.pushViewController(UIViewController(), animated: false)
        navController.pushViewController(subject, animated: false)

        let expectation = XCTestExpectation(description: "bookmark saved")
        viewModel.onBookmarkSaved = { expectation.fulfill() }

        subject.saveButtonAction()

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Private

    private func createSubject(
        viewModel: GroupedEditBookmarkViewModel? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> GroupedEditBookmarkViewController {
        let subject = GroupedEditBookmarkViewController(
            viewModel: viewModel ?? createViewModel(),
            windowUUID: .XCTestDefaultUUID
        )
        subject.loadViewIfNeeded()
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createViewModel(
        folderFetcher: GroupedFolderHierarchyFetcher? = nil
    ) -> GroupedEditBookmarkViewModel {
        let parentFolder = BookmarkFolderData(
            guid: "parent_guid",
            dateAdded: 0,
            lastModified: 0,
            parentGUID: nil,
            position: 0,
            title: "Parent",
            childGUIDs: [],
            children: nil
        )
        let node = BookmarkItemData(
            guid: "bookmark_guid",
            dateAdded: 0,
            lastModified: 0,
            parentGUID: "parent_guid",
            position: 0,
            url: "https://example.com",
            title: "Example"
        )
        return GroupedEditBookmarkViewModel(
            parentFolder: parentFolder,
            node: node,
            profile: profile,
            bookmarksSaver: MockBookmarksSaver(),
            folderFetcher: folderFetcher ?? MockGroupedFolderHierarchyFetcher()
        )
    }

    private func selectFolderAndWait(
        _ viewModel: GroupedEditBookmarkViewModel,
        subject: GroupedEditBookmarkViewController,
        indexPath: IndexPath
    ) {
        let statusExpectation = XCTestExpectation(description: "folder status updated")
        let snapshotExpectation = XCTestExpectation(description: "snapshot applied")

        let existingHandler = viewModel.onFolderStatusUpdate
        viewModel.onFolderStatusUpdate = {
            existingHandler?()
            statusExpectation.fulfill()
        }

        let existingSnapshotHandler = subject.dataSource.onSnapshotUpdate
        subject.dataSource.onSnapshotUpdate = {
            existingSnapshotHandler?()
            snapshotExpectation.fulfill()
        }

        subject.tableView(subject.tableView, didSelectRowAt: indexPath)
        wait(for: [statusExpectation, snapshotExpectation], timeout: 1.0)
    }
}
