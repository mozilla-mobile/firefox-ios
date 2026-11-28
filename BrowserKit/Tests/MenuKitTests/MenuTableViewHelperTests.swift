// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import MenuKit

@MainActor
final class MenuTableViewHelperTests: XCTestCase {
    var tableView: UITableView!
    var helper: MenuTableViewHelper!

    override func setUp() async throws {
        try await super.setUp()
        tableView = UITableView()
        helper = MenuTableViewHelper(tableView: tableView)
    }

    override func tearDown() async throws {
        tableView = nil
        helper = nil
        try await super.tearDown()
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

    // MARK: - Horizontal tabs at accessibility text sizes

    func testNumberOfRows_horizontalTabs_shouldReturnOneRow() {
        let section = MenuSection(isHorizontalTabsSection: true, options: createOptions(count: 4))
        helper.updateData([section], theme: nil, isBannerVisible: false, isAccessibilityCategory: false)

        XCTAssertEqual(helper.numberOfRowsInSection(0), 1)
    }

    func testNumberOfRows_horizontalTabs_withAccessibilityCategory_shouldReturnOneRowPerOption() {
        let section = MenuSection(isHorizontalTabsSection: true, options: createOptions(count: 4))
        helper.updateData([section], theme: nil, isBannerVisible: false, isAccessibilityCategory: true)

        XCTAssertEqual(helper.numberOfRowsInSection(0), 4)
    }

    func testCellForRow_horizontalTabs_withAccessibilityCategory_shouldReturnMenuCellType() {
        tableView.register(MenuCell.self, forCellReuseIdentifier: MenuCell.cellIdentifier)
        tableView.register(MenuSquaresViewContentCell.self,
                           forCellReuseIdentifier: MenuSquaresViewContentCell.cellIdentifier)
        let section = MenuSection(isHorizontalTabsSection: true, options: createOptions(count: 4))
        helper.updateData([section], theme: nil, isBannerVisible: false, isAccessibilityCategory: true)
        helper.reload()

        for row in 0..<4 {
            let cell = helper.cellForRowAt(tableView, IndexPath(row: row, section: 0))
            XCTAssertTrue(cell is MenuCell)
        }
    }

    func testDidSelectRow_horizontalTabs_shouldNotRunAction() {
        var tappedOptions = [Int]()
        let options = createOptions(count: 4) { tappedOptions.append($0) }
        let section = MenuSection(isHorizontalTabsSection: true, options: options)
        helper.updateData([section], theme: nil, isBannerVisible: false, isAccessibilityCategory: false)

        helper.didSelectRowAt(tableView, IndexPath(row: 0, section: 0))

        XCTAssertTrue(tappedOptions.isEmpty)
    }

    func testDidSelectRow_horizontalTabs_withAccessibilityCategory_shouldRunActionOfSelectedRow() {
        var tappedOptions = [Int]()
        let options = createOptions(count: 4) { tappedOptions.append($0) }
        let section = MenuSection(isHorizontalTabsSection: true, options: options)
        helper.updateData([section], theme: nil, isBannerVisible: false, isAccessibilityCategory: true)

        helper.didSelectRowAt(tableView, IndexPath(row: 2, section: 0))

        XCTAssertEqual(tappedOptions, [2])
    }

    func testUpdateLayout_whenAccessibilityCategoryChanges_shouldUpdateNumberOfRows() {
        let section = MenuSection(isHorizontalTabsSection: true, options: createOptions(count: 4))
        helper.updateData([section], theme: nil, isBannerVisible: false, isAccessibilityCategory: false)

        helper.updateLayout(isAccessibilityCategory: true)
        XCTAssertEqual(helper.numberOfRowsInSection(0), 4)

        helper.updateLayout(isAccessibilityCategory: false)
        XCTAssertEqual(helper.numberOfRowsInSection(0), 1)
    }

    // MARK: - Helpers

    private func createOptions(count: Int, onTap: (@MainActor (Int) -> Void)? = nil) -> [MenuElement] {
        return (0..<count).map { index in
            MenuElement(
                title: "Option \(index)",
                iconName: "",
                isEnabled: true,
                isActive: false,
                a11yLabel: "",
                a11yHint: "",
                a11yId: "",
                action: { onTap?(index) }
            )
        }
    }
}
