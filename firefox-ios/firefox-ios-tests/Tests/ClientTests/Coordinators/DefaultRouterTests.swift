// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class DefaultRouterTests: XCTestCase {
    var navigationController: MockNavigationController!

    override func setUp() async throws {
        try await super.setUp()
        navigationController = await MockNavigationController()
    }

    override func tearDown() {
        super.tearDown()
        navigationController = nil
    }

    @MainActor
    func testInitialState() {
        let subject = DefaultRouter(navigationController: navigationController)

        XCTAssertNil(subject.rootViewController)
        XCTAssertEqual(subject.navigationController.viewControllers, navigationController.viewControllers)
        XCTAssertEqual(subject.completions.count, 0)
    }

    @MainActor
    func testPresentViewController_presentCalled() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()
        subject.present(viewController, completion: {})

        XCTAssertEqual(navigationController.presentCalled, 1)
        XCTAssertEqual(navigationController.presentedViewController, viewController)
        XCTAssertEqual(subject.completions.count, 1)
    }

    @MainActor
    func testPresentViewController_dismissModalCompletionCalled() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()
        let expectation = expectation(description: "Completion is called")
        subject.present(viewController) {
            expectation.fulfill()
        }

        subject.presentationControllerDidDismiss(viewController.presentationController!)

        waitForExpectations(timeout: 0.1)
    }

    @MainActor
    func testRunCompletion_DoesNotRunForNonExistingCompletion() {
        let subject = DefaultRouter(navigationController: navigationController)

        let viewController = UIViewController()
        subject.presentationControllerDidDismiss(viewController.presentationController!)

        XCTAssertEqual(subject.completions.count, 0)
    }

    @MainActor
    func testDismissModule() {
        let subject = DefaultRouter(navigationController: navigationController)
        subject.dismiss()

        XCTAssertEqual(navigationController.dismissCalled, 1)
    }

    @MainActor
    func testPresentThenDismiss_removesCompletion() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()

        subject.present(viewController, completion: {})
        XCTAssertEqual(subject.completions.count, 1)

        subject.dismiss()
        XCTAssertEqual(subject.completions.count, 0)
    }

    @MainActor
    func testPushModule_pushViewController() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()
        subject.push(viewController, completion: {})

        XCTAssertEqual(navigationController.pushCalled, 1)
        XCTAssertEqual(navigationController.presentedViewController, viewController)
        XCTAssertEqual(subject.completions.count, 1)
    }

    @MainActor
    func testPopViewController() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()
        let expectation = expectation(description: "Completion is called")

        subject.push(viewController) {
            XCTAssertEqual(self.navigationController.popViewCalled, 1)
            expectation.fulfill()
        }
        subject.popViewController()

        waitForExpectations(timeout: 0.1)
    }

    @MainActor
    func testPopToViewController_notifiesDismissals_andRunsCompletions() throws {
        let baseVC = UIViewController()
        let pushedVC = MockDismissalNotifiableViewController()
        var completionCalled = false

        let subject = DefaultRouter(navigationController: navigationController)
        subject.push(baseVC, animated: false)
        subject.push(pushedVC, animated: false) { completionCalled = true }

        let returnedViewControllers = subject.popToViewController(baseVC, reason: .deeplink, animated: false)

        XCTAssertEqual(navigationController.popToViewControllerCalled, 1)
        XCTAssertEqual(returnedViewControllers?.count, 1)

        let poppedControllers = try XCTUnwrap(returnedViewControllers)
        XCTAssertTrue(poppedControllers.contains(where: { $0 === pushedVC }))

        XCTAssertEqual(pushedVC.dismissalReason, .deeplink)

        XCTAssertTrue(completionCalled)

        XCTAssertEqual(navigationController.viewControllers, [baseVC])
    }

    @MainActor
    func testSetRootViewController() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()
        subject.setRootViewController(viewController, hideBar: true)

        XCTAssertEqual(navigationController.viewControllers, [viewController])
        XCTAssertEqual(navigationController.isNavigationBarHidden, true)
    }

    @MainActor
    func testSetRootViewController_withPushedViewController_completionIsCalled() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()
        let expectation = expectation(description: "Completion is called")

        subject.push(viewController) {
            expectation.fulfill()
        }
        subject.setRootViewController(viewController)

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(navigationController.viewControllers, [viewController])
    }

    // MARK: - UINavigationControllerDelegate

    @MainActor
    func testNavigationControllerDelegate_doesntRunCompletionWhenNoFromVC() {
        let subject = DefaultRouter(navigationController: navigationController)
        let expectation = expectation(description: "Completion is called")
        expectation.isInverted = true

        let viewController = UIViewController()
        subject.push(viewController) {
            expectation.fulfill()
        }
        subject.checkNavigationCompletion(for: navigationController)

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    @MainActor
    func testNavigationControllerDelegate_runsCompletionForPoppedViewController() {
        let subject = DefaultRouter(navigationController: navigationController)
        let expectation = expectation(description: "Completion is called")
        let viewController = UIViewController()

        navigationController.fromViewController = viewController
        subject.push(viewController) {
            expectation.fulfill()
        }
        navigationController.viewControllers = []
        subject.checkNavigationCompletion(for: navigationController)

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
