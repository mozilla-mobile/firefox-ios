// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class EditFolderViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    let parentFolder = MockFxBookmarkNode(type: .folder,
                                          guid: "5678",
                                          position: 0,
                                          isRoot: false,
                                          title: "Parent")
    let folder = MockFxBookmarkNode(type: .folder,
                                    guid: "1235",
                                    position: 1,
                                    isRoot: false,
                                    title: "Hello")

    var folderFetcher: MockFolderHierarchyFetcher!
    var bookmarksSaver: MockBookmarksSaver!
    var profile: MockProfile!
    var themeManager: MockThemeManager!
    var viewModel: EditFolderViewModel!
    let dummyTableView = UITableView()

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        folderFetcher = MockFolderHierarchyFetcher()
        bookmarksSaver = MockBookmarksSaver()
        profile = MockProfile()
        themeManager = MockThemeManager()
        viewModel = EditFolderViewModel(profile: profile,
                                        parentFolder: parentFolder,
                                        folder: folder,
                                        bookmarkSaver: bookmarksSaver,
                                        folderFetcher: folderFetcher)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        folderFetcher = nil
        bookmarksSaver = nil
        profile = nil
        themeManager = nil
        viewModel = nil
        try await super.tearDown()
    }

    func testViewDidLoad_setsTitle() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.title, viewModel.controllerTitle)
    }

    func testViewDidLoad_addsTableViewSubview() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertFalse(subject.view.subviews.isEmpty)
    }

    func testNumberOfSections_whenNotBrowsing_returnsEditSectionPlusSummarySection() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.numberOfSections(in: dummyTableView), 2)
    }

    func testNumberOfRowsInSection_editFolderSection_returnsOneRow() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.tableView(dummyTableView, numberOfRowsInSection: 0), 1)
    }

    func testNumberOfRowsInSection_summarySection_returnsSummaryAndChangeLocationRows() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.tableView(dummyTableView, numberOfRowsInSection: 1), 2)
    }

    func testDidSelectRow_summaryRow_doesNotBeginBrowsing() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.tableView(dummyTableView, didSelectRowAt: IndexPath(row: 0, section: 1))

        XCTAssertFalse(viewModel.isBrowsingFolders)
    }

    func testDidSelectRow_changeLocationRow_beginsBrowsing() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        let expectation = expectation(description: "fetch should complete")
        viewModel.onFolderStatusUpdate = {
            expectation.fulfill()
        }

        subject.tableView(dummyTableView, didSelectRowAt: IndexPath(row: 1, section: 1))

        XCTAssertTrue(viewModel.isBrowsingFolders)
        waitForExpectations(timeout: 0.5)
        XCTAssertEqual(folderFetcher.fetchFoldersCalled, 1)
    }

    func testDidSelectRow_editFolderSection_doesNothing() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.tableView(dummyTableView, didSelectRowAt: IndexPath(row: 0, section: 0))

        XCTAssertFalse(viewModel.isBrowsingFolders)
        XCTAssertEqual(folderFetcher.fetchFoldersCalled, 0)
    }

    func testEstimatedHeightForHeader_editFolderSection_isZero() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.tableView(dummyTableView, estimatedHeightForHeaderInSection: 0), 0)
    }

    func testEstimatedHeightForHeader_summarySection_isAutomaticDimension() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.tableView(dummyTableView, estimatedHeightForHeaderInSection: 1),
                       UITableView.automaticDimension)
    }

    func testHeightForRowAt_returnsAutomaticDimension() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.tableView(dummyTableView, heightForRowAt: IndexPath(row: 0, section: 0)),
                       UITableView.automaticDimension)
    }

    // MARK: - Helpers

    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> EditFolderViewController {
        let subject = EditFolderViewController(viewModel: viewModel,
                                               windowUUID: windowUUID,
                                               themeManager: themeManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
