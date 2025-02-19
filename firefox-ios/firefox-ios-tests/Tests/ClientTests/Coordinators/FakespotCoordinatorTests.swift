// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import WebKit
@testable import Client

final class FakespotCoordinatorTests: XCTestCase {
    private var profile: MockProfile!
    private var mockRouter: MockRouter!
    let exampleProduct = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!
    let exampleProduct2 = URL(string: "https://www.amazon.com/ESpefy-Frame-Dual-Workstation-Black/dp/B0B88PNFDJ")!

    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        DependencyHelperMock().bootstrapDependencies()
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() {
        self.profile = nil
        self.mockRouter = nil
        AppContainer.shared.reset()
        super.tearDown()
    }

    func testInitialState() {
        let subject = createSubject()

        XCTAssertTrue(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
    }

    func testFakespotStarts_presentsFakespotControllerAsModal() throws {
        let subject = createSubject()

        subject.startModal(productURL: exampleProduct)

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is FakespotViewController)
    }

    func testFakespotStarts_presentsFakespotControllerAsSidebar() throws {
        let subject = createSubject()
        let sidebarContainer = MockSidebarEnabledView(frame: CGRect.zero)
        let viewController = UIViewController()

        subject.startSidebar(productURL: exampleProduct,
                             sidebarContainer: sidebarContainer,
                             parentViewController: viewController)

        XCTAssertEqual(sidebarContainer.showSidebarCalled, 1)
    }

    func testFakespotCoordinatorDelegate_CloseSidebar_callsRouterDismiss() throws {
        let subject = createSubject()
        let sidebarContainer = MockSidebarEnabledView(frame: CGRect.zero)
        let viewController = UIViewController()

        subject.startSidebar(productURL: exampleProduct,
                             sidebarContainer: sidebarContainer,
                             parentViewController: viewController)
        subject.closeSidebar(sidebarContainer: sidebarContainer,
                             parentViewController: viewController)

        XCTAssertEqual(sidebarContainer.hideSidebarCalled, 1)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testFakespotCoordinatorDelegate_didDidDismiss_callsRouterDismiss() throws {
        let subject = createSubject()

        subject.startModal(productURL: exampleProduct)
        subject.dismissModal(animated: false)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testUpdateSidebar_withOtherProduct_updatesSidebar() {
        let subject = createSubject()
        let sidebarContainer = MockSidebarEnabledView(frame: CGRect.zero)
        let viewController = UIViewController()

        subject.startSidebar(productURL: exampleProduct,
                             sidebarContainer: sidebarContainer,
                             parentViewController: viewController)

        XCTAssertEqual(sidebarContainer.showSidebarCalled, 1)

        subject.updateSidebar(productURL: exampleProduct2,
                              sidebarContainer: sidebarContainer,
                              parentViewController: viewController)

        XCTAssertEqual(sidebarContainer.updateSidebarCalled, 1)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> FakespotCoordinator {
        let subject = FakespotCoordinator(router: mockRouter, tabManager: MockTabManager())

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
