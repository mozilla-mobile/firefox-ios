// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class EditBookmarkViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    let parentFolder = MockFxBookmarkNode(type: .folder,
                                          guid: "5678",
                                          position: 0,
                                          isRoot: false,
                                          title: "Parent")
    let bookmarkNode = MockFxBookmarkNode(type: .bookmark,
                                          guid: "1235",
                                          position: 1,
                                          isRoot: false,
                                          title: "Example")

    var folderFetcher: MockFolderHierarchyFetcher!
    var bookmarksSaver: MockBookmarksSaver!
    var profile: MockProfile!
    var themeManager: MockThemeManager!
    var viewModel: EditBookmarkViewModel!
    let dummyTableView = UITableView()

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        folderFetcher = MockFolderHierarchyFetcher()
        bookmarksSaver = MockBookmarksSaver()
        profile = MockProfile()
        themeManager = MockThemeManager()
        viewModel = EditBookmarkViewModel(parentFolder: parentFolder,
                                          node: bookmarkNode,
                                          profile: profile,
                                          bookmarksSaver: bookmarksSaver,
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

        XCTAssertEqual(subject.title, .Bookmarks.Menu.EditBookmarkTitle)
    }

    func testViewDidLoad_addsTableViewSubview() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertFalse(subject.view.subviews.isEmpty)
    }

    func testEstimatedHeightForHeader_mainSection_isZero() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.tableView(dummyTableView, estimatedHeightForHeaderInSection: 0), 0)
    }

    func testEstimatedHeightForHeader_selectFolderSection_isAutomaticDimension() {
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

    func testWillSelectRow_realFolderRow_allowsSelection() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        // The collapsed default state shows the selected folder as the only row in section 1.
        let indexPath = IndexPath(row: 0, section: 1)
        XCTAssertEqual(subject.tableView(dummyTableView, willSelectRowAt: indexPath), indexPath)
    }

    func testWillSelectRow_rowWithNoMatchingFolderEntry_stillAllowsSelection() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        let outOfBoundsIndexPath = IndexPath(row: 99, section: 1)
        XCTAssertEqual(subject.tableView(dummyTableView, willSelectRowAt: outOfBoundsIndexPath),
                       outOfBoundsIndexPath)
    }

    func testDidSelectRow_realFolderRow_callsSelectFolder() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        let initialIsCollapsed = viewModel.isFolderCollapsed
        subject.tableView(dummyTableView, didSelectRowAt: IndexPath(row: 0, section: 1))

        XCTAssertNotEqual(viewModel.isFolderCollapsed, initialIsCollapsed)
    }

    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> EditBookmarkViewController {
        let subject = EditBookmarkViewController(viewModel: viewModel,
                                                 windowUUID: windowUUID,
                                                 themeManager: themeManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
