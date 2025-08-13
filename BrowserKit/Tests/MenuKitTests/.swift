// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MenuKit
@testable import Client

final class MenuTableViewTests: XCTestCase {
    var menuView: MenuTableView!

    override func setUp() {
        super.setUp()
        menuView = MenuTableView()
    }

    override func tearDown() {
        menuView = nil
        super.tearDown()
    }

    func testTableView_isSetUpCorrectly() {
        XCTAssertNotNil(menuView)
        XCTAssertTrue(menuView.subviews.contains { $0 is UITableView })
    }

    func testReload_withMenuData() {
        let option = MenuElement(
            title: "Option 1",
            iconName: "",
            isEnabled: true,
            isActive: false,
            a11yLabel: "",
            a11yHint: "",
            a11yId: "",
            action: nil
        )
        let section = MenuSection(isHorizontalTabsSection: false, isExpanded: true, options: [option])
        menuView.reloadTableView(with: [section], isBannerVisible: false)

        XCTAssertEqual(menuView.tableViewContentSize > 0, true)
        XCTAssertEqual(menuView.tableView.numberOfSections, 1)
        XCTAssertEqual(menuView.tableView(menuView.tableView, numberOfRowsInSection: 0), 1)
    }

    func testCellForRow_shouldReturnAccountCellType() {
        let option = MenuElement(
            title: "Option 1",
            iconName: "",
            iconImage: UIImage(),
            needsReAuth: false,
            isEnabled: true,
            isActive: false,
            a11yLabel: "",
            a11yHint: "",
            a11yId: "",
            action: nil
        )
        let section = MenuSection(isHorizontalTabsSection: false, isExpanded: true, options: [option])
        menuView.reloadTableView(with: [section], isBannerVisible: false)

        let cell = menuView.tableView(menuView.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is MenuAccountCell)
    }

    func testCellForRow_shouldReturnSquaresViewContentCellType() {
        let option = MenuElement(
            title: "Option 1",
            iconName: "",
            isEnabled: true,
            isActive: false,
            a11yLabel: "",
            a11yHint: "",
            a11yId: "",
            action: nil
        )
        let section = MenuSection(isHorizontalTabsSection: true, isExpanded: true, options: [option])
        menuView.reloadTableView(with: [section], isBannerVisible: false)

        let cell = menuView.tableView(menuView.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is MenuSquaresViewContentCell)
    }

    func testCellForRow_shouldReturnInfoCellType() {
        let option = MenuElement(
            title: "Option 1",
            iconName: "",
            isEnabled: true,
            isActive: false,
            a11yLabel: "",
            a11yHint: "",
            a11yId: "",
            infoTitle: "Title Test",
            action: nil
        )
        let section = MenuSection(isHorizontalTabsSection: false, isExpanded: true, options: [option])
        menuView.reloadTableView(with: [section], isBannerVisible: false)

        let cell = menuView.tableView(menuView.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is MenuInfoCell)
    }

    func testCellForRow_shouldReturnRedesignCellType() {
        let option = MenuElement(
            title: "Option 1",
            iconName: "",
            isEnabled: true,
            isActive: false,
            a11yLabel: "",
            a11yHint: "",
            a11yId: "",
            action: nil
        )
        let section = MenuSection(isHorizontalTabsSection: false, isExpanded: true, options: [option])
        menuView.reloadTableView(with: [section], isBannerVisible: false)

        let cell = menuView.tableView(menuView.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is MenuCell)
    }
}
