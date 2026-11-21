// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
final class TabGroupsTrayIntegrationTests: XCTestCase {
    private var tabManager: MockTabManager!

    override func setUp() async throws {
        try await super.setUp()
        let manager = MockTabManager()
        tabManager = manager
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: manager)
    }

    override func tearDown() async throws {
        FxNimbus.shared.features.tabGroupsFeature.with { TabGroupsFeature($0) }
        tabManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testFlagDisabled_preservesLegacyToolbarWithGroupsControllerAvailable() {
        let (subject, navigation) = createSubject(featureEnabled: false)

        subject.viewWillAppear(false)

        XCTAssertFalse(navigation.isToolbarHidden)
        XCTAssertNil(subject.tabGroupsNativeToolbar)
        XCTAssertNil(subject.tabGroupsTopHost)
        XCTAssertEqual(subject.toolbarItems?.count, 3)
        XCTAssertTrue(subject.toolbarItems?.contains {
            $0.accessibilityIdentifier == AccessibilityIdentifiers.TabTray.newTabButton
        } == true)
    }

    func testFlagEnabled_usesNativeToolbarAndTabsSegment() throws {
        let (subject, navigation) = createSubject(featureEnabled: true)

        subject.viewWillAppear(false)

        let toolbar = try XCTUnwrap(subject.tabGroupsNativeToolbar)
        XCTAssertFalse(navigation.isToolbarHidden)
        XCTAssertTrue(navigation.isNavigationBarHidden)
        XCTAssertTrue(subject.toolbarItems?.contains { $0.customView === toolbar.panelSelector } == true)
        XCTAssertTrue(subject.toolbarItems?.contains { $0.accessibilityIdentifier == "tabGroupsTray.addTab" } == true)
        XCTAssertEqual(toolbar.panelSelector.titleForSegment(at: 1), String.TabsTray.TabsSelectorNormalTabsTitle)
        XCTAssertEqual(toolbar.panelSelector.selectedSegmentIndex, 1)
        XCTAssertFalse(try XCTUnwrap(subject.tabGroupsTopHost).view.isHidden)
    }

    func testFlagEnabled_privatePanelKeepsPrivateSelectionAndHidesGroupsTitle() throws {
        let (subject, navigation) = createSubject(featureEnabled: true, selectedPanel: .privateTabs)

        subject.viewWillAppear(false)

        XCTAssertFalse(navigation.isToolbarHidden)
        XCTAssertEqual(subject.tabTrayState.selectedPanel, .privateTabs)
        XCTAssertEqual(try XCTUnwrap(subject.tabGroupsNativeToolbar).panelSelector.selectedSegmentIndex, 0)
        XCTAssertTrue(try XCTUnwrap(subject.tabGroupsTopHost).view.isHidden)
    }

    func testFlagEnabled_sizesPanelBeforeNavigationToolbarIsLaidOut() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        let (subject, navigation) = createSubject(featureEnabled: true, theme: NovaLightTheme())
        subject.viewWillAppear(false)
        subject.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        navigation.toolbar.frame = .zero

        subject.viewDidLayoutSubviews()

        let toolbar = try XCTUnwrap(subject.tabGroupsNativeToolbar)
        let panel = try XCTUnwrap(toolbar.items.compactMap { $0.customView as? TabGroupsTrayGlassPanel }.first)
        XCTAssertEqual(panel.intrinsicContentSize.width, 241, accuracy: 0.5)
    }

    func testFlagEnabled_syncPanelKeepsSyncSelectionAndHidesGroupsTitle() throws {
        let (subject, navigation) = createSubject(featureEnabled: true, selectedPanel: .syncedTabs)

        subject.viewWillAppear(false)

        XCTAssertFalse(navigation.isToolbarHidden)
        XCTAssertEqual(subject.tabTrayState.selectedPanel, .syncedTabs)
        XCTAssertEqual(try XCTUnwrap(subject.tabGroupsNativeToolbar).panelSelector.selectedSegmentIndex, 2)
        XCTAssertTrue(try XCTUnwrap(subject.tabGroupsTopHost).view.isHidden)
    }

    func testFlagEnabled_novaUsesNativeGlassForAddButton() throws {
        guard #available(iOS 26.0, *) else { return }
        let theme = NovaLightTheme()
        let (subject, navigation) = createSubject(featureEnabled: true, theme: theme)

        subject.viewWillAppear(false)

        let toolbar = try XCTUnwrap(subject.tabGroupsNativeToolbar)
        let addButton = try XCTUnwrap(toolbar.items.first {
            $0.accessibilityIdentifier == "tabGroupsTray.addTab"
        })
        XCTAssertFalse(navigation.isToolbarHidden)
        XCTAssertEqual(subject.toolbarItems?.count, 3)
        let container = try XCTUnwrap(addButton.customView as? TabGroupsTrayNativeToolbar.GlassButtonContainer)
        let button = container.button
        XCTAssertEqual(button.configuration?.baseForegroundColor, theme.colors.textPrimary)
        XCTAssertEqual(button.accessibilityLabel, String.TabGroups.Accessibility.NewTabButton)
        XCTAssertTrue(addButton.hidesSharedBackground)
    }

    func testDismissedTray_releasesWhileSelectionAndGroupCallbacksRemainAlive() throws {
        weak var releasedSubject: TabTrayViewController?
        var source: TabDisplayView?
        var controller: TabGroupsController?
        autoreleasepool {
            let (subject, navigation) = createSubject(featureEnabled: true)
            releasedSubject = subject
            source = subject.childPanelControllers.compactMap {
                ($0.topViewController as? TabDisplayPanelViewController)?.tabDisplayView
            }.first
            controller = subject.tabGroupsController
            subject.unsubscribeFromRedux()
            navigation.setViewControllers([], animated: false)
        }

        XCTAssertNotNil(source?.onSelectionChange)
        XCTAssertNotNil(controller?.onChange)
        XCTAssertNil(releasedSubject)
        source?.onSelectionChange?()
        if let controller { controller.onChange?(controller.state) }
    }

    private func createSubject(featureEnabled: Bool,
                               selectedPanel: TabTrayPanelType = .tabs,
                               theme: Theme = LightTheme(),
                               file: StaticString = #filePath,
                               line: UInt = #line) -> (TabTrayViewController, UINavigationController) {
        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: featureEnabled) }
        var utils = MockTabTrayUtils()
        utils.displaysExperimentUI = false
        let subject = TabTrayViewController(panelType: selectedPanel,
                                            tabTrayUtils: utils,
                                            themeManager: MockThemeManager(currentTheme: theme),
                                            windowUUID: .XCTestDefaultUUID)
        subject.layout = .compact
        subject.tabManager = tabManager
        subject.tabGroupsController = TabGroupsController(groupManager: tabManager.tabGroupManager,
                                                          windowUUID: .XCTestDefaultUUID,
                                                          tabManager: tabManager)
        subject.childPanelControllers = makeChildPanels()
        subject.setupOpenPanel(panelType: selectedPanel)
        subject.setupTabGroupsUI()
        let navigation = DismissableNavigationViewController(rootViewController: subject)
        trackForMemoryLeaks(subject, file: file, line: line)
        return (subject, navigation)
    }

    private func makeChildPanels() -> [UINavigationController] {
        let delegate = MockTabDisplayViewDragAndDropInteraction()
        let normal = TabDisplayPanelViewController(isPrivateMode: false,
                                                   windowUUID: .XCTestDefaultUUID,
                                                   dragAndDropDelegate: delegate)
        let privateTabs = TabDisplayPanelViewController(isPrivateMode: true,
                                                        windowUUID: .XCTestDefaultUUID,
                                                        dragAndDropDelegate: delegate)
        let sync = RemoteTabsPanel(windowUUID: .XCTestDefaultUUID)
        return [normal, privateTabs, sync].map {
            ThemedNavigationController(rootViewController: $0, windowUUID: .XCTestDefaultUUID)
        }
    }
}
