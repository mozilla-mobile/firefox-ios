// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import XCTest

@testable import Client

@MainActor
final class GroupedEditFolderViewControllerTests: XCTestCase {
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

    func test_numberOfSections_beforeBrowsing_returnsEditPlusSummarySection() {
        let subject = createSubject()

        XCTAssertEqual(subject.numberOfSections(in: subject.tableView), 2)
    }

    func test_numberOfRows_editFolderSection_isAlwaysOne() {
        let subject = createSubject()

        XCTAssertEqual(subject.tableView(subject.tableView, numberOfRowsInSection: 0), 1)
    }

    func test_numberOfRows_summarySection_beforeBrowsing_returnsTwo() {
        let subject = createSubject()

        XCTAssertEqual(subject.tableView(subject.tableView, numberOfRowsInSection: 1), 2)
    }

    func test_cellForRow_editFolderSection_returnsEditFolderCell() {
        let subject = createSubject()

        let cell = subject.tableView(subject.tableView, cellForRowAt: IndexPath(row: 0, section: 0))

        XCTAssertTrue(cell is EditFolderCell)
    }

    func test_cellForRow_summaryRowOne_showsChangeLocationCell() {
        let subject = createSubject()

        let cell = subject.tableView(subject.tableView, cellForRowAt: IndexPath(row: 1, section: 1))

        XCTAssertTrue(cell is LinkActionCell)
    }

    func test_didSelectRow_summaryRowOne_beginsBrowsingFolders() {
        let fetcher = MockGroupedFolderHierarchyFetcher()
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        let expectation = XCTestExpectation(description: "folder status updated")
        viewModel.onFolderStatusUpdate = { expectation.fulfill() }

        subject.tableView(subject.tableView, didSelectRowAt: IndexPath(row: 1, section: 1))
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(viewModel.isBrowsingFolders)
        XCTAssertEqual(fetcher.fetchFoldersCalled, 1)
    }

    func test_numberOfRows_groupSection_whenExpanded_matchesFolderCount() {
        let folders = [GroupedFolder(title: "Top", guid: "top", indentation: 0)]
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = folders
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        beginBrowsingAndWait(viewModel, subject: subject)

        XCTAssertEqual(subject.tableView(subject.tableView, numberOfRowsInSection: 1), folders.count)
    }

    func test_didSelectRow_whileBrowsing_selectsFolderOnViewModel() {
        let folder = GroupedFolder(title: "Top", guid: "top", indentation: 0)
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = [folder]
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        beginBrowsingAndWait(viewModel, subject: subject)
        subject.tableView(subject.tableView, didSelectRowAt: IndexPath(row: 0, section: 1))

        XCTAssertEqual(viewModel.selectedFolder?.guid, folder.guid)
        XCTAssertFalse(viewModel.isBrowsingFolders)
    }

    func test_headerTap_togglesGroupExpansionOnViewModel() {
        let folder = GroupedFolder(title: "Top", guid: "top", indentation: 0)
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = [folder]
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        beginBrowsingAndWait(viewModel, subject: subject)
        let wasExpanded = viewModel.folderGroups[0].isExpanded
        let header = subject.tableView(subject.tableView, viewForHeaderInSection: 1) as? FolderSectionHeaderView
        header?.onTap?()

        XCTAssertEqual(viewModel.folderGroups[0].isExpanded, !wasExpanded)
    }

    func test_toggleGroup_collapsingMultiBlockGroup_updatesSectionCountWithoutStaleCache() {
        let folderA = GroupedFolder(title: "A", guid: "a", indentation: 0)
        let folderB = GroupedFolder(title: "B", guid: "b", indentation: 0)
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = [folderA, folderB]
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        beginBrowsingAndWait(viewModel, subject: subject)
        XCTAssertEqual(subject.numberOfSections(in: subject.tableView), 3)

        let header = subject.tableView(subject.tableView, viewForHeaderInSection: 1) as? FolderSectionHeaderView
        header?.onTap?()

        XCTAssertEqual(subject.numberOfSections(in: subject.tableView), 2)
    }

    func test_reload_afterNewRootFolderAdded_updatesSectionCountWithoutStaleCache() {
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = [GroupedFolder(title: "A", guid: "a", indentation: 0)]
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        beginBrowsingAndWait(viewModel, subject: subject)
        let sectionsBeforeReload = subject.numberOfSections(in: subject.tableView)

        fetcher.mockFolderStructures = [
            GroupedFolder(title: "A", guid: "a", indentation: 0),
            GroupedFolder(title: "B", guid: "b", indentation: 0)
        ]
        beginBrowsingAndWait(viewModel, subject: subject)

        XCTAssertEqual(subject.numberOfSections(in: subject.tableView), sectionsBeforeReload + 1)
    }

    func test_reload_afterNestedFolderAdded_updatesRowCountWithoutStaleCache() {
        let fetcher = MockGroupedFolderHierarchyFetcher()
        fetcher.mockFolderStructures = [GroupedFolder(title: "A", guid: "a", indentation: 0)]
        let viewModel = createViewModel(folderFetcher: fetcher)
        let subject = createSubject(viewModel: viewModel)

        beginBrowsingAndWait(viewModel, subject: subject)
        XCTAssertEqual(subject.tableView(subject.tableView, numberOfRowsInSection: 1), 1)

        fetcher.mockFolderStructures = [
            GroupedFolder(title: "A", guid: "a", indentation: 0),
            GroupedFolder(title: "A-child", guid: "a-child", indentation: 1)
        ]
        beginBrowsingAndWait(viewModel, subject: subject)

        XCTAssertEqual(subject.tableView(subject.tableView, numberOfRowsInSection: 1), 2)
    }

    func test_saveButtonAction_popsViewController() {
        let subject = createSubject()
        let navController = UINavigationController()
        navController.pushViewController(UIViewController(), animated: false)
        navController.pushViewController(subject, animated: false)

        subject.saveButtonAction()

        XCTAssert(!navController.viewControllers.contains(subject))
    }

    func test_saveButtonAction_savesFolder() {
        let folder = makeFolder()
        let viewModel = createViewModel(folder: folder)
        let subject = createSubject(viewModel: viewModel)

        let expectation = XCTestExpectation(description: "folder saved")
        viewModel.onBookmarkSaved = { expectation.fulfill() }

        subject.saveButtonAction()

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Private

    private func createSubject(
        viewModel: GroupedEditFolderViewModel? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> GroupedEditFolderViewController {
        let subject = GroupedEditFolderViewController(
            viewModel: viewModel ?? createViewModel(),
            windowUUID: .XCTestDefaultUUID
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createViewModel(
        folder: FxBookmarkNode? = nil,
        folderFetcher: GroupedFolderHierarchyFetcher? = nil
    ) -> GroupedEditFolderViewModel {
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
        return GroupedEditFolderViewModel(
            profile: profile,
            parentFolder: parentFolder,
            folder: folder,
            bookmarkSaver: MockBookmarksSaver(),
            folderFetcher: folderFetcher ?? MockGroupedFolderHierarchyFetcher()
        )
    }

    private func makeFolder() -> BookmarkFolderData {
        BookmarkFolderData(
            guid: "folder_guid",
            dateAdded: 0,
            lastModified: 0,
            parentGUID: "parent_guid",
            position: 0,
            title: "My Folder",
            childGUIDs: [],
            children: nil
        )
    }

    private func beginBrowsingAndWait(
        _ viewModel: GroupedEditFolderViewModel,
        subject: GroupedEditFolderViewController
    ) {
        let expectation = XCTestExpectation(description: "folder groups loaded")
        viewModel.onFolderStatusUpdate = { [weak subject] in
            subject?.tableView.reloadData()
            subject?.view.setNeedsLayout()
            subject?.view.layoutIfNeeded()
            expectation.fulfill()
        }
        viewModel.beginBrowsingFolders()
        wait(for: [expectation], timeout: 1.0)
    }
}
