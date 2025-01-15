// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class EditBookmarkDataSourceTests: XCTestCase {
    private let folders = [
        Folder(title: "Parent", guid: "ParentFolder", indentation: 0),
        Folder(title: "Child", guid: "ChildFolder", indentation: 1)
    ]
    private var tableView: UITableView!

    override func setUp() {
        super.setUp()
        tableView = UITableView()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.rootViewController?.view.addSubview(tableView)
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        tableView = nil
        super.tearDown()
    }

    func testOnSnapshotUpdate() {
        let expectation = XCTestExpectation(description: "onShapshotUpate should be called")
        let subject = createSubject(tableView: tableView)

        subject.onSnapshotUpdate = {
            expectation.fulfill()
        }

        subject.updateSnapshot(isFolderCollapsed: true, folders: folders)

        wait(for: [expectation], timeout: 10.0)
    }

    func testDataSourceSnapshot_whenFolderIsCollapsed() {
        let subject = createSubject(tableView: tableView)
        let sections: [EditBookmarkTableSection] = [.main, .selectFolder]
        var tableCells: [EditBookmarkTableCell] = [.bookmark]
        folders.forEach {
            tableCells.append(EditBookmarkTableCell.folder($0, true))
        }

        subject.updateSnapshot(isFolderCollapsed: true, folders: folders)

        XCTAssertEqual(subject.snapshot().sectionIdentifiers, sections)
        XCTAssertEqual(subject.snapshot().itemIdentifiers, tableCells)
    }

    func testDataSourceSnapshot_whenFolderIsNotCollapsed() {
        let subject = createSubject(tableView: tableView)
        let sections: [EditBookmarkTableSection] = [.main, .selectFolder]
        var tableCells: [EditBookmarkTableCell] = [.bookmark]
        folders.forEach {
            tableCells.append(EditBookmarkTableCell.folder($0, false))
        }
        tableCells.append(.newFolder)

        subject.updateSnapshot(isFolderCollapsed: false, folders: folders)

        XCTAssertEqual(subject.snapshot().sectionIdentifiers, sections)
        XCTAssertEqual(subject.snapshot().itemIdentifiers, tableCells)
    }

    private func createSubject(tableView: UITableView) -> EditBookmarkDiffableDataSource {
        let dataSource = EditBookmarkDiffableDataSource(tableView: tableView) { _, _, _ in
            return UITableViewCell()
        }
        trackForMemoryLeaks(dataSource)
        return dataSource
    }
}
