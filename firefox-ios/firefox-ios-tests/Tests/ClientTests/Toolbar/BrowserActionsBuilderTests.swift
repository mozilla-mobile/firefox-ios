// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common

@testable import Client

final class BrowserActionsBuilderTests: XCTestCase {
    // MARK: - Editing / navigation toolbar guard

    func testGetActions_whenEditingAndShowingNavigationToolbar_returnsOnlyCancelEditAction() {
        let actions = subject(isEditing: true, isShowingNavigationToolbar: true)

        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].actionType, .cancelEdit)
    }

    func testGetActions_whenNotEditingAndShowingNavigationToolbar_returnsNoActions() {
        let actions = subject(isEditing: false, isShowingNavigationToolbar: true)

        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - New tab

    func testGetActions_whenNotShowingTopTabsAndNotHomepage_includesNewTabAction() {
        let actions = subject(isShowingTopTabs: false, isHomepage: false)

        XCTAssertTrue(actions.contains { $0.actionType == .newTab })
    }

    func testGetActions_whenShowingTopTabs_doesNotIncludeNewTabAction() {
        let actions = subject(isShowingTopTabs: true, isHomepage: false)

        XCTAssertFalse(actions.contains { $0.actionType == .newTab })
    }

    func testGetActions_whenHomepage_doesNotIncludeNewTabAction() {
        let actions = subject(isShowingTopTabs: false, isHomepage: true)

        XCTAssertFalse(actions.contains { $0.actionType == .newTab })
    }

    // MARK: - Layout ordering

    func testGetActions_whenLayoutVersion1_ordersMenuBeforeTabs() {
        let actions = subject(toolbarLayout: .version1)

        XCTAssertEqual(actions.map(\.actionType).suffix(2), [.menu, .tabs])
    }

    func testGetActions_whenLayoutVersion2_ordersTabsBeforeMenu() {
        let actions = subject(toolbarLayout: .version2)

        XCTAssertEqual(actions.map(\.actionType).suffix(2), [.tabs, .menu])
    }

    // MARK: - Tabs action

    func testGetActions_whenTabTrayButtonStyleIsScreenshot_tabsActionHasNoIcon() {
        let actions = subject(tabTrayButtonStyle: .screenshot)

        XCTAssertNil(tabsAction(in: actions)?.iconName)
    }

    func testGetActions_whenTabTrayButtonStyleIsNumber_tabsActionHasTabIcon() {
        let actions = subject(tabTrayButtonStyle: .number)

        XCTAssertEqual(tabsAction(in: actions)?.iconName, StandardImageIdentifiers.Large.tab)
    }

    func testGetActions_setsNumberOfTabsOnTabsAction() {
        let actions = subject(numberOfTabs: 5)

        XCTAssertEqual(tabsAction(in: actions)?.numberOfTabs, 5)
    }

    func testGetActions_whenPrivateMode_setsBadgeOnTabsAction() {
        let actions = subject(isPrivateMode: true)

        XCTAssertNotNil(tabsAction(in: actions)?.badgeImageName)
    }

    func testGetActions_whenNotPrivateMode_noBadgeOnTabsAction() {
        let actions = subject(isPrivateMode: false)

        XCTAssertNil(tabsAction(in: actions)?.badgeImageName)
    }

    // MARK: - Menu action

    func testGetActions_whenShowWarningBadgeTrue_setsBadgeOnMenuAction() {
        let actions = subject(showWarningBadge: true)

        XCTAssertNotNil(menuAction(in: actions)?.badgeImageName)
        XCTAssertNotNil(menuAction(in: actions)?.maskImageName)
    }

    func testGetActions_whenShowWarningBadgeFalse_noBadgeOnMenuAction() {
        let actions = subject(showWarningBadge: false)

        XCTAssertNil(menuAction(in: actions)?.badgeImageName)
        XCTAssertNil(menuAction(in: actions)?.maskImageName)
    }

    // MARK: - Helpers

    private func subject(
        isEditing: Bool = false,
        isShowingNavigationToolbar: Bool = false,
        isShowingTopTabs: Bool = false,
        isHomepage: Bool = false,
        toolbarLayout: ToolbarLayoutStyle? = .version1,
        tabTrayButtonStyle: TabTrayButtonStyle? = .number,
        numberOfTabs: Int = 1,
        showWarningBadge: Bool = false,
        previousTabScreenshot: UIImage? = nil,
        nextTabScreenshot: UIImage? = nil,
        isPrivateMode: Bool = false,
        isNovaDesignEnabled: Bool = false
    ) -> [ToolbarActionConfiguration] {
        BrowserActionsBuilder.getActions(
            isEditing: isEditing,
            isShowingNavigationToolbar: isShowingNavigationToolbar,
            isShowingTopTabs: isShowingTopTabs,
            isHomepage: isHomepage,
            toolbarLayout: toolbarLayout,
            tabTrayButtonStyle: tabTrayButtonStyle,
            numberOfTabs: numberOfTabs,
            showWarningBadge: showWarningBadge,
            previousTabScreenshot: previousTabScreenshot,
            nextTabScreenshot: nextTabScreenshot,
            isPrivateMode: isPrivateMode,
            isNovaDesignEnabled: isNovaDesignEnabled
        )
    }

    private func tabsAction(in actions: [ToolbarActionConfiguration]) -> ToolbarActionConfiguration? {
        return actions.first { $0.actionType == .tabs }
    }

    private func menuAction(in actions: [ToolbarActionConfiguration]) -> ToolbarActionConfiguration? {
        return actions.first { $0.actionType == .menu }
    }
}
