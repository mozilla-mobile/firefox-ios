// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import MenuKit

@MainActor
final class MenuTableViewHelperTests: XCTestCase {
    var tableView: UITableView!
    var helper: MenuTableViewHelper!

    override func setUp() {
        super.setUp()
        tableView = UITableView()
        helper = MenuTableViewHelper(tableView: tableView)
    }

    override func tearDown() {
        tableView = nil
        helper = nil
        super.tearDown()
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
        helper.updateData([section], theme: nil, isBannerVisible: false)
        helper.reload()

        XCTAssertEqual(tableView.numberOfSections, 1)
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

        tableView.register(MenuAccountCell.self, forCellReuseIdentifier: MenuAccountCell.cellIdentifier)
        let section = MenuSection(isHorizontalTabsSection: false, isExpanded: true, options: [option])
        helper.updateData([section], theme: nil, isBannerVisible: false)
        helper.reload()

        let cell = helper.cellForRowAt(tableView, IndexPath(row: 0, section: 0))
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

        tableView.register(MenuSquaresViewContentCell.self,
                           forCellReuseIdentifier: MenuSquaresViewContentCell.cellIdentifier)
        let section = MenuSection(isHorizontalTabsSection: true, isExpanded: true, options: [option])
        helper.updateData([section], theme: nil, isBannerVisible: false)
        helper.reload()

        let cell = helper.cellForRowAt(tableView, IndexPath(row: 0, section: 0))
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

        tableView.register(MenuInfoCell.self, forCellReuseIdentifier: MenuInfoCell.cellIdentifier)
        let section = MenuSection(isHorizontalTabsSection: false, isExpanded: true, options: [option])
        helper.updateData([section], theme: nil, isBannerVisible: false)
        helper.reload()

        let cell = helper.cellForRowAt(tableView, IndexPath(row: 0, section: 0))
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

        tableView.register(MenuCell.self, forCellReuseIdentifier: MenuCell.cellIdentifier)
        let section = MenuSection(isHorizontalTabsSection: false, isExpanded: true, options: [option])
        helper.updateData([section], theme: nil, isBannerVisible: false)
        helper.reload()

        let cell = helper.cellForRowAt(tableView, IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is MenuCell)
    }
}
