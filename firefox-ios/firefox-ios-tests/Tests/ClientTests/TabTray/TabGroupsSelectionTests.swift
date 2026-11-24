// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
final class TabGroupsSelectionTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testToggleSelection_outsideSelectionMode_doesNotSelectTabs() {
        let subject = createSubject()

        subject.toggleTabSelection("tab-0")
        subject.toggleSelectionOfAllTabs()

        XCTAssertTrue(subject.selectedTabIDs.isEmpty)
    }

    func testToggleSelection_ignoresTabsOutsideVisibleList() {
        let subject = createSubject()
        subject.isSelectingTabs = true

        subject.toggleTabSelection("missing-tab")
        subject.toggleTabSelection("tab-1")

        XCTAssertEqual(subject.selectedTabIDs, ["tab-1"])
    }

    func testSelectAll_onEmptyList_keepsSelectionEmpty() {
        let subject = createSubject(tabIDs: [])
        subject.isSelectingTabs = true

        subject.toggleSelectionOfAllTabs()

        XCTAssertTrue(subject.selectedTabIDs.isEmpty)
    }

    func testSelectAll_selectsVisibleTabsAndDeselectAllClearsThem() {
        let subject = createSubject()
        subject.isSelectingTabs = true

        subject.toggleSelectionOfAllTabs()
        XCTAssertEqual(subject.selectedTabIDs, ["tab-0", "tab-1", "tab-2"])

        subject.toggleSelectionOfAllTabs()
        XCTAssertTrue(subject.selectedTabIDs.isEmpty)
    }

    func testDeselectAll_withPartialSelection_clearsSelection() {
        let subject = createSubject()
        subject.isSelectingTabs = true
        subject.toggleTabSelection("tab-1")

        subject.toggleSelectionOfAllTabs()

        XCTAssertTrue(subject.selectedTabIDs.isEmpty)
    }

    func testStateUpdate_removesClosedTabsFromSelection() {
        let subject = createSubject()
        subject.isSelectingTabs = true
        subject.toggleSelectionOfAllTabs()

        subject.newState(state: makeState(tabIDs: ["tab-0", "tab-2"]))

        XCTAssertEqual(subject.selectedTabIDs, ["tab-0", "tab-2"])
        XCTAssertEqual(subject.tabsState.tabs.map(\.tabUUID), ["tab-0", "tab-2"])
    }

    func testSelectAll_withSelectedGroup_selectsOnlyGroupTabs() async throws {
        let subject = createSubject()
        subject.tabGroupsController = try await makeGroupController(tabIDs: ["tab-1"])
        subject.isSelectingTabs = true

        subject.toggleSelectionOfAllTabs()

        XCTAssertEqual(subject.selectedTabIDs, ["tab-1"])
        XCTAssertEqual(subject.tabsState.tabs.map(\.tabUUID), ["tab-1"])
    }

    func testSelectionMode_disablesDraggingImmediately() {
        let subject = createSubject()
        XCTAssertTrue(subject.collectionView.dragInteractionEnabled)

        subject.isSelectingTabs = true

        XCTAssertFalse(subject.collectionView.dragInteractionEnabled)
    }

    func testEndingSelection_clearsCollectionViewSelectionAndAccessibilityTrait() throws {
        let subject = createSubject()
        let cell = try realizedCell(in: subject)
        let indexPath = IndexPath(item: 0, section: 0)
        subject.isSelectingTabs = true
        subject.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        subject.toggleTabSelection("tab-0")
        XCTAssertTrue(cell.accessibilityTraits.contains(.selected))

        subject.isSelectingTabs = false

        XCTAssertTrue(subject.collectionView.indexPathsForSelectedItems?.isEmpty ?? true)
        XCTAssertFalse(cell.isSelected)
        XCTAssertFalse(cell.accessibilityTraits.contains(.selected))
    }

    func testGroupFilter_keepsDraggingDisabledAfterSelectionModeEnds() async throws {
        let subject = createSubject()
        XCTAssertTrue(subject.collectionView.dragInteractionEnabled)
        subject.tabGroupsController = try await makeGroupController(tabIDs: ["tab-1"])
        XCTAssertFalse(subject.collectionView.dragInteractionEnabled)
        subject.isSelectingTabs = true

        subject.isSelectingTabs = false

        XCTAssertEqual(subject.tabsState.tabs.map(\.tabUUID), ["tab-1"])
        XCTAssertFalse(subject.collectionView.dragInteractionEnabled)

        subject.tabGroupsController = nil

        XCTAssertTrue(subject.collectionView.dragInteractionEnabled)
    }

    func testSelectionIndicator_showsEmptyCheckedAndHiddenStates() throws {
        let subject = createSubject()
        let theme = NovaLightTheme()
        subject.applyTheme(theme: theme)
        let cell = try realizedCell(in: subject)

        subject.isSelectingTabs = true

        let indicator = try selectionSubview("tabGroupsSelection.indicator", in: cell)
        let checkmark = try selectionSubview("tabGroupsSelection.checkmark", in: indicator)
        XCTAssertFalse(indicator.isHidden)
        XCTAssertEqual(indicator.backgroundColor, .clear)
        XCTAssertEqual(indicator.layer.borderColor, UIColor.white.cgColor)
        XCTAssertTrue(checkmark.isHidden)
        XCTAssertFalse(indicator.isUserInteractionEnabled)

        subject.toggleTabSelection("tab-0")

        XCTAssertEqual(indicator.backgroundColor, theme.colors.actionPrimary)
        XCTAssertFalse(checkmark.isHidden)
        XCTAssertFalse(try selectionSubview("tabGroupsSelection.ring", in: cell).isHidden)

        subject.isSelectingTabs = false

        XCTAssertTrue(indicator.isHidden)
        XCTAssertTrue(try selectionSubview("tabGroupsSelection.ring", in: cell).isHidden)
    }

    func testSelectionIndicator_andRingUseSelectedGroupColor() async throws {
        let subject = createSubject()
        let controller = try await makeGroupController(tabIDs: ["tab-0"])
        subject.tabGroupsController = controller
        subject.applyTheme(theme: NovaLightTheme())
        let cell = try realizedCell(in: subject)
        let color = try XCTUnwrap(controller.state.groups.first).color.uiColor
        subject.isSelectingTabs = true

        subject.toggleTabSelection("tab-0")

        XCTAssertEqual(try selectionSubview("tabGroupsSelection.indicator", in: cell).backgroundColor, color)
        XCTAssertEqual(try selectionSubview("tabGroupsSelection.ring", in: cell).layer.borderColor, color.cgColor)
    }

    func testSelectionIndicator_defaultGroupUsesCurrentThemeSolidColor() async throws {
        let subject = createSubject()
        subject.tabGroupsController = try await makeGroupController(tabIDs: ["tab-0"],
                                                                    color: TabGroupColorPalette.defaultColor)
        subject.applyTheme(theme: NovaLightTheme())
        let cell = try realizedCell(in: subject)
        subject.isSelectingTabs = true
        subject.toggleTabSelection("tab-0")
        let themes: [any Theme] = [NovaLightTheme(), NovaDarkTheme()]
        for theme in themes {
            subject.applyTheme(theme: theme)

            let indicator = try selectionSubview("tabGroupsSelection.indicator", in: cell)
            let checkmark = try XCTUnwrap(selectionSubview("tabGroupsSelection.checkmark", in: indicator) as? UIImageView)
            XCTAssertEqual(indicator.backgroundColor, theme.colors.tabGroupNoColor)
            XCTAssertEqual(checkmark.tintColor, theme.colors.iconPrimary)
            XCTAssertEqual(try selectionSubview("tabGroupsSelection.ring", in: cell).layer.borderColor,
                           theme.colors.iconSecondary.cgColor)
        }
    }

    func testSelection_synchronizesAllSelectedCellsAndAccessibilityTraits() throws {
        let subject = createSubject()
        let cells = try (0..<3).map { try realizedCell(in: subject, at: $0) }
        subject.isSelectingTabs = true
        XCTAssertFalse(subject.collectionView.allowsMultipleSelection)

        for index in 0..<2 {
            let path = IndexPath(item: index, section: 0)
            subject.collectionView.selectItem(at: path, animated: false, scrollPosition: [])
            subject.collectionView(subject.collectionView, didSelectItemAt: path)
        }

        XCTAssertEqual(subject.selectedTabIDs, ["tab-0", "tab-1"])
        for (index, cell) in cells.enumerated() {
            XCTAssertEqual(cell.isSelected, index < 2, "Source card \(index) selection")
            XCTAssertEqual(cell.accessibilityTraits.contains(.selected), index < 2, "Source card \(index) traits")
        }
        XCTAssertFalse(subject.collectionView.allowsMultipleSelection)

        subject.isSelectingTabs = false

        for (index, cell) in cells.enumerated() {
            XCTAssertFalse(cell.isSelected, "Source card \(index) after selection ends")
            XCTAssertFalse(cell.accessibilityTraits.contains(.selected), "Source card \(index) traits after selection ends")
        }
    }

    func testNormalMode_keepsExistingUIKitSelectionWithoutBulkIndicator() throws {
        let subject = createSubject()
        let cell = try realizedCell(in: subject)
        cell.isSelected = true
        let originalTraits = cell.accessibilityTraits

        subject.applyTheme(theme: NovaLightTheme())

        XCTAssertTrue(cell.isSelected)
        XCTAssertEqual(cell.accessibilityTraits, originalTraits)
        XCTAssertNil(cell.subviews.first { $0.accessibilityIdentifier == "tabGroupsSelection.indicator" })
    }

    private func realizedCell(in subject: TabDisplayView, at index: Int = 0) throws -> UICollectionViewCell {
        subject.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        subject.layoutIfNeeded()
        subject.collectionView.layoutIfNeeded()
        return try XCTUnwrap(subject.collectionView.cellForItem(at: IndexPath(item: index, section: 0)))
    }

    private func selectionSubview(_ identifier: String, in view: UIView) throws -> UIView {
        try XCTUnwrap(view.subviews.first { $0.accessibilityIdentifier == identifier })
    }

    private func createSubject(tabIDs: [TabUUID] = ["tab-0", "tab-1", "tab-2"],
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabDisplayView {
        let state = makeState(tabIDs: tabIDs)
        let subject = TabDisplayView(panelType: .tabs,
                                     state: state,
                                     windowUUID: .XCTestDefaultUUID,
                                     tabTrayUtils: MockTabTrayUtils())
        subject.newState(state: state)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func makeState(tabIDs: [TabUUID]) -> TabsPanelState {
        TabsPanelState(windowUUID: .XCTestDefaultUUID)
            .copy(tabs: tabIDs.map { TabModel.emptyState(tabUUID: $0, title: $0) })
    }

    private func makeGroupController(tabIDs: [TabUUID], color: CodableColor? = nil) async throws -> TabGroupsController {
        var group = TabGroup(title: "Work", tabIDs: tabIDs)
        if let color { group.color = color }
        let storage = MockTabGroupStorage()
        await storage.setSnapshot(TabGroupSnapshot(groups: [group]))
        let manager = TabGroupManager(storage: storage)
        try await manager.restore()
        let profile = makeProfile()
        let tabs = tabIDs.map { id in
            let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
            tab.tabUUID = id
            manager.bind(tab)
            return tab
        }
        _ = try manager.openGroup(group.id, in: .XCTestDefaultUUID)
        let controller = TabGroupsController(groupManager: manager, windowUUID: .XCTestDefaultUUID)
        controller.selectGroup(id: group.id)
        withExtendedLifetime(tabs) {}
        trackForMemoryLeaks(controller)
        return controller
    }
}
