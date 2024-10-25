// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared

class ThemableTests: XCTestCaseRootViewController {
    private var tableViewDelegate: TestsTableView!
    private var testThemable: TestsThemeable!

    override func setUp() {
        super.setUp()
        tableViewDelegate = TestsTableView()
        testThemable = TestsThemeable()
    }

    override func tearDown() {
        super.tearDown()
        tableViewDelegate = nil
        testThemable = nil
    }

    // MARK: Get all subviews

    func testGetAllSubviews_noSubviews() {
        let subject = UIView()
        let result = testThemable.getAllSubviews(for: subject, ofType: UIView.self)
        XCTAssertEqual(result.count, 0, "No subviews")
    }

    func testGetAllSubviews_twoSubviews() {
        let subview1 = UIView(), subview2 = UIView()
        let subject = UIView()
        subject.addSubviews(subview1, subview2)

        let result = testThemable.getAllSubviews(for: subject, ofType: UIView.self)
        XCTAssertEqual(result.count, 2, "Two subviews")
    }

    func testGetAllSubviews_twoSubviewsWithChildren() {
        let childView1 = UIView(), childView2 = UIView()
        let subview1 = UIView(), subview2 = UIView()
        subview1.addSubview(childView1)
        subview2.addSubview(childView2)
        let subject = UIView()
        subject.addSubviews(subview1, subview2)

        let result = testThemable.getAllSubviews(for: subject, ofType: UIView.self)
        XCTAssertEqual(result.count, 4, "Four subviews")
    }

    func testGetAllSubviews_withTableView() {
        let tableView = UITableView(frame: CGRect(width: 200, height: 300))
        tableView.dataSource = tableViewDelegate
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: TestsTableView.testCellId)
        rootViewController.view.addSubview(tableView)

        loadViewForTesting()

        let result = testThemable.getAllSubviews(for: tableView, ofType: UITableViewCell.self)
        XCTAssertEqual(result.count, 3, "Retrieving three UITableViewCell in tableview")
    }
}

// MARK: - TestsTableViewDataSource
class TestsTableView: NSObject, UITableViewDataSource, UITableViewDelegate {
    static let testCellId = "TestCell"
    static let numberOfRows = 3

    var finishedLoading: (() -> Void)?

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TestsTableView.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TestsTableView.testCellId,
                                                 for: indexPath as IndexPath)
        return cell
    }
}

// MARK: - TestsThemeable
class TestsThemeable: UIViewController, Themeable {
    var themeManager: ThemeManager = DefaultThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    func applyTheme() {}
    var currentWindowUUID: UUID? { return .XCTestDefaultUUID }
}
