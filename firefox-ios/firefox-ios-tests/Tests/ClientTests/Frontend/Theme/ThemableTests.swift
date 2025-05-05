// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Shared

class ThemableTests: XCTestCaseRootViewController {
    private var tableViewDelegate: TestsTableView!
    private var testThemable: TestsThemeable!
    private var mockThemeManager: MockThemeManager!

    override func setUp() {
        super.setUp()
        mockThemeManager = MockThemeManager()
        tableViewDelegate = TestsTableView()
        testThemable = TestsThemeable()
        testThemable.themeManager = mockThemeManager
    }

    override func tearDown() {
        mockThemeManager = nil
        tableViewDelegate = nil
        testThemable = nil
        super.tearDown()
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

    // MARK: - updateThemeApplicableSubviews
    func test_updateThemeApplicableSubviews_withDefault_returnsProperTheme() {
        testThemable.updateThemeApplicableSubviews(UIView(), for: .XCTestDefaultUUID)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 1)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 0)
    }

    func test_updateThemeApplicableSubviews_withPrivateThemeOverrides_returnsProperTheme() {
        testThemable.shouldUsePrivateOverride = true
        testThemable.shouldBeInPrivateTheme = true
        testThemable.updateThemeApplicableSubviews(UIView(), for: .XCTestDefaultUUID)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 0)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 1)
    }

    func test_updateThemeApplicableSubviews_withPrivateThemeOverrides_forceNoPrivateTheme_returnsProperTheme() {
        testThemable.shouldUsePrivateOverride = true
        testThemable.shouldBeInPrivateTheme = false
        testThemable.updateThemeApplicableSubviews(UIView(), for: .XCTestDefaultUUID)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 0)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 1)
    }

    func test_updateThemeApplicableSubviews_withDefault_forcePrivateTheme_returnsProperTheme() {
        testThemable.shouldUsePrivateOverride = false
        testThemable.shouldBeInPrivateTheme = true
        testThemable.updateThemeApplicableSubviews(UIView(), for: .XCTestDefaultUUID)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 1)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 0)
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
    var themeManager: ThemeManager = MockThemeManager()
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    func applyTheme() {}
    var currentWindowUUID: UUID? { return .XCTestDefaultUUID }
    var shouldUsePrivateOverride = false
    var shouldBeInPrivateTheme = false
}
