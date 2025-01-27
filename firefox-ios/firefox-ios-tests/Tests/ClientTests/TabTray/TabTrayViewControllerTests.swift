// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

final class TabTrayViewControllerTests: XCTestCase {
    var delegate: MockTabTrayViewControllerDelegate!
    var navigationController: DismissableNavigationViewController!
    private var tabManager: MockTabManager!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        let mockTabManager = MockTabManager()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: mockTabManager)
        delegate = MockTabTrayViewControllerDelegate()
        navigationController = DismissableNavigationViewController()
        tabManager = mockTabManager
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() {
        super.tearDown()
        delegate = nil
        navigationController = nil
        DependencyHelperMock().reset()
    }

    // MARK: Compact layout
    func testToolbarItems_ForCompact() {
        let viewController = createSubject()
        viewController.layout = .compact
        viewController.viewWillAppear(false)

        XCTAssertEqual(viewController.segmentControlItems.count, 3)
        guard let navController = viewController.navigationController else {
            XCTFail("NavigationController is expected")
            return
        }

        XCTAssertFalse(navController.isToolbarHidden)
        XCTAssertNil(viewController.navigationItem.titleView)
    }

    func testBottomToolbarItems_ForTabsInCompact() {
        let viewController = createSubject()

        viewController.layout = .compact
        viewController.viewWillAppear(false)

        XCTAssertEqual(viewController.toolbarItems?.count, 3)
    }

    func testBottomToolbarItems_ForPrivateTabsInCompact() {
        let viewController = createSubject(selectedSegment: .privateTabs)

        viewController.layout = .compact
        viewController.viewWillAppear(false)

        XCTAssertEqual(viewController.toolbarItems?.count, 3)
    }

    func testBottomToolbarItems_ForSyncTabsEnabledInCompact() {
        let viewController = createSubject(selectedSegment: .syncedTabs)
        viewController.layout = .compact
        viewController.viewWillAppear(false)

        XCTAssertEqual(viewController.toolbarItems?.count, 0)
    }

    // MARK: Regular layout
    func testToolbarItems_ForRegular() {
        let viewController = createSubject()
        viewController.layout = .regular
        viewController.viewWillAppear(false)

        XCTAssertEqual(viewController.segmentControlItems.count, 3)
        guard let navController = viewController.navigationController else {
            XCTFail("NavigationController is expected")
            return
        }

        XCTAssertTrue(navController.isToolbarHidden)
        XCTAssertNotNil(viewController.navigationItem.titleView)
    }

    // MARK: - Private
    private func createSubject(selectedSegment: TabTrayPanelType = .tabs,
                               file: StaticString = #file,
                               line: UInt = #line) -> TabTrayViewController {
        let subject = TabTrayViewController(selectedTab: selectedSegment, windowUUID: .XCTestDefaultUUID)
        subject.delegate = delegate
        subject.childPanelControllers = makeChildPanels()
        subject.setupOpenPanel(panelType: selectedSegment)
        let navigationController = createNavigationController(root: subject)
        navigationController.isNavigationBarHidden = false

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createNavigationController(root: UIViewController) -> UINavigationController {
        let navigationController = DismissableNavigationViewController(rootViewController: root)
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let modalPresentationStyle: UIModalPresentationStyle = isPad ? .fullScreen: .formSheet
        navigationController.modalPresentationStyle = modalPresentationStyle

        return navigationController
    }

    private func makeChildPanels() -> [UINavigationController] {
        let regularTabsPanel = TabDisplayPanelViewController(isPrivateMode: false, windowUUID: .XCTestDefaultUUID)
        let privateTabsPanel = TabDisplayPanelViewController(isPrivateMode: true, windowUUID: .XCTestDefaultUUID)
        let syncTabs = RemoteTabsPanel(windowUUID: .XCTestDefaultUUID)
        return [
            ThemedNavigationController(rootViewController: regularTabsPanel, windowUUID: windowUUID),
            ThemedNavigationController(rootViewController: privateTabsPanel, windowUUID: windowUUID),
            ThemedNavigationController(rootViewController: syncTabs, windowUUID: windowUUID)
        ]
    }
}

// MARK: MockTabTrayViewControllerDelegate
class MockTabTrayViewControllerDelegate: TabTrayViewControllerDelegate {
    func didFinish() {}
}
