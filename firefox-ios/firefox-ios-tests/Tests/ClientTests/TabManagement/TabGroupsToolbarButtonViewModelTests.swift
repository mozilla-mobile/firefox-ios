// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class TabGroupsToolbarButtonViewModelTests: TabManagerTestsBase {
    override func setUp() async throws {
        try await super.setUp()
        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: true) }
    }

    override func tearDown() async throws {
        FxNimbus.shared.features.tabGroupsFeature.with { variables in
            TabGroupsFeature(variables)
        }
        try await super.tearDown()
    }

    @MainActor
    func testConfigure_withSelectedGroup_usesThumbnailStackAndAddsBadge() async throws {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let tabs = generateTabs(count: 3)
        let manager = createSubject(tabs: tabs, groupManager: groups)
        let ids = tabs.map(\.tabUUID)
        let windowUUID = manager.windowUUID
        defer { TabGroupsSessionStore.removeController(for: windowUUID) }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: manager)
        let action = ToolbarActionConfiguration(actionType: .tabs,
                                                iconName: "tabCount",
                                                numberOfTabs: 1,
                                                isEnabled: true,
                                                a11yLabel: "Tabs",
                                                a11yId: "tabs")

        XCTAssertEqual(TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID), action)

        controller.createGroup(name: "Work", icon: .sfSymbol("bag.fill"), tabIDs: [ids[0]], normalTabIDs: ids)
        let configured = TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID)

        XCTAssertNil(configured.actionLabel)
        XCTAssertNil(configured.iconName)
        XCTAssertEqual(configured.numberOfTabs, 1)
        XCTAssertNotNil(configured.bottomLeadingBadgeImage)
        XCTAssertEqual(configured.bottomLeadingBadgeShadowColor, controller.state.groups.first?.color.uiColor)
        XCTAssertEqual(configured.a11yLabel, "Work, \(String.TabGroups.Accessibility.MenuButton)")

        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: false) }
        XCTAssertEqual(TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID), action)
    }

    @MainActor
    func testConfigure_withSavedPreset_usesCurrentTokenForBadgeShadow() async throws {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let tabs = generateTabs(count: 1)
        let manager = createSubject(tabs: tabs, groupManager: groups)
        let windowUUID = manager.windowUUID
        defer { TabGroupsSessionStore.removeController(for: windowUUID) }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: manager)
        let savedColor = try XCTUnwrap(CodableColor(uiColor: UIColor {
            UIColor(rgb: $0.userInterfaceStyle == .dark ? 0x70abff : 0x455fe7)
        }))
        let ids = tabs.map(\.tabUUID)
        controller.createGroup(name: "Work", color: savedColor, tabIDs: ids, normalTabIDs: ids)
        let action = ToolbarActionConfiguration(actionType: .tabs,
                                                iconName: "tabCount",
                                                numberOfTabs: 1,
                                                isEnabled: true,
                                                a11yLabel: "Tabs",
                                                a11yId: "tabs")

        let configured = TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID)
        let shadowColor = try XCTUnwrap(configured.bottomLeadingBadgeShadowColor)
        let themes: [any Theme] = [NovaLightTheme(), NovaDarkTheme()]
        for theme in themes {
            let traits = UITraitCollection(userInterfaceStyle: theme.type.getInterfaceStyle())
            let actualComponents = try XCTUnwrap(shadowColor.resolvedColor(with: traits).cgColor.components)
            let expectedComponents = try XCTUnwrap(theme.colors.tabGroupBlue.cgColor.components)
            XCTAssertEqual(actualComponents.count, expectedComponents.count)
            for (actualComponent, expectedComponent) in zip(actualComponents, expectedComponents) {
                XCTAssertEqual(actualComponent, expectedComponent, accuracy: 0.000_001)
            }
        }
    }

    @MainActor
    func testConfigure_withScreenshotButton_preservesScreenshotsAndUsesGroupCount() async throws {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let tabs = generateTabs(count: 3)
        let manager = createSubject(tabs: tabs, groupManager: groups)
        let windowUUID = manager.windowUUID
        defer { TabGroupsSessionStore.removeController(for: windowUUID) }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: manager)
        let ids = tabs.map(\.tabUUID)
        controller.createGroup(name: "Work", tabIDs: [ids[0], ids[1]], normalTabIDs: ids)
        let screenshot = UIImage(systemName: "globe")
        let action = ToolbarActionConfiguration(actionType: .tabs,
                                                iconName: nil,
                                                numberOfTabs: 3,
                                                isEnabled: true,
                                                previousTabScreenshot: screenshot,
                                                nextTabScreenshot: screenshot,
                                                a11yLabel: "Tabs",
                                                a11yId: "tabs")

        let configured = TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID, normalTabIDs: ids)

        XCTAssertNil(configured.iconName)
        XCTAssertEqual(configured.numberOfTabs, 2)
        XCTAssertEqual(configured.previousTabScreenshot, screenshot)
        XCTAssertEqual(configured.nextTabScreenshot, screenshot)
        XCTAssertNotNil(configured.bottomLeadingBadgeImage)
        XCTAssertEqual(configured.cacheId, action.cacheId)
    }

    @MainActor
    func testConfigure_withPrivateBadge_doesNotAddGroupBadge() async throws {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let tabs = generateTabs(count: 1)
        let manager = createSubject(tabs: tabs, groupManager: groups)
        let windowUUID = manager.windowUUID
        defer { TabGroupsSessionStore.removeController(for: windowUUID) }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: manager)
        let ids = tabs.map(\.tabUUID)
        controller.createGroup(name: "Work", tabIDs: ids, normalTabIDs: ids)
        let action = ToolbarActionConfiguration(actionType: .tabs,
                                                iconName: "tabCount",
                                                badgeImageName: "privateMode",
                                                numberOfTabs: 1,
                                                isEnabled: true,
                                                a11yLabel: "Private Tabs",
                                                a11yId: "tabs")

        XCTAssertEqual(TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID), action)
    }

    @MainActor
    func testToolbarCountsOnlyMobileTabs() async throws {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let tabs = generateTabs(count: 3)
        let manager = createSubject(tabs: tabs, groupManager: groups)
        let ids = tabs.map(\.tabUUID)
        let windowUUID = manager.windowUUID
        defer { TabGroupsSessionStore.removeController(for: windowUUID) }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: manager)
        let action = ToolbarActionConfiguration(actionType: .tabs,
                                                iconName: "tabCount",
                                                numberOfTabs: 3,
                                                isEnabled: true,
                                                a11yLabel: "Tabs",
                                                a11yId: "tabs")
        controller.createGroup(name: "Work", tabIDs: [ids[0], ids[2]], normalTabIDs: ids)
        controller.selectGroup(id: nil)

        let configured = TabGroupsToolbarButtonViewModel.configure(action,
                                                                   for: windowUUID,
                                                                   normalTabIDs: ids)

        XCTAssertEqual(configured.numberOfTabs, 1)
        XCTAssertEqual(configured.iconName, action.iconName)
    }
}
