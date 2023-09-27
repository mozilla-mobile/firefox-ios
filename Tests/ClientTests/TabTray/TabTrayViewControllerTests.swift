// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

final class TabTrayViewControllerTests: XCTestCase {
    var delegate: MockTabTrayViewControllerDelegate!
    var navigationController: DismissableNavigationViewController!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        delegate = MockTabTrayViewControllerDelegate()
        navigationController = DismissableNavigationViewController()
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
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> TabTrayViewController {
        let navigationController = createNavigationController()
        let subject = TabTrayViewController(delegate: delegate)
        navigationController.setViewControllers([subject], animated: false)
        navigationController.isNavigationBarHidden = false

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createNavigationController() -> UINavigationController {
        let navigationController = DismissableNavigationViewController()
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let modalPresentationStyle: UIModalPresentationStyle = isPad ? .fullScreen: .formSheet
        navigationController.modalPresentationStyle = modalPresentationStyle

        return navigationController
    }
}

// MARK: MockTabTrayViewControllerDelegate
class MockTabTrayViewControllerDelegate: TabTrayViewControllerDelegate {
    func didDismissTabTray() {}
}
