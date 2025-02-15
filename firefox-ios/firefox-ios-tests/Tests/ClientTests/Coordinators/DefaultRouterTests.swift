// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class DefaultRouterTests: XCTestCase {
    var navigationController: MockNavigationController!

    override func setUp() {
        super.setUp()
        navigationController = MockNavigationController()
    }

    override func tearDown() {
        navigationController = nil
        super.tearDown()
    }

    func testInitialState() {
        let subject = DefaultRouter(navigationController: navigationController)

        XCTAssertNil(subject.rootViewController)
        XCTAssertEqual(subject.navigationController.viewControllers, navigationController.viewControllers)
        XCTAssertEqual(subject.completions.count, 0)
    }

    func testPresentViewController_presentCalled() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()
        subject.present(viewController, completion: {})

        XCTAssertEqual(navigationController.presentCalled, 1)
        XCTAssertEqual(navigationController.presentedViewController, viewController)
        XCTAssertEqual(subject.completions.count, 1)
    }

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

    func testRunCompletion_DoesNotRunForNonExistingCompletion() {
        let subject = DefaultRouter(navigationController: navigationController)

        let viewController = UIViewController()
        subject.presentationControllerDidDismiss(viewController.presentationController!)

        XCTAssertEqual(subject.completions.count, 0)
    }

    func testDismissModule() {
        let subject = DefaultRouter(navigationController: navigationController)
        subject.dismiss()

        XCTAssertEqual(navigationController.dismissCalled, 1)
    }

    func testPresentThenDismiss_removesCompletion() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()

        subject.present(viewController, completion: {})
        XCTAssertEqual(subject.completions.count, 1)

        subject.dismiss()
        XCTAssertEqual(subject.completions.count, 0)
    }

    func testPushModule_pushViewController() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()
        subject.push(viewController, completion: {})

        XCTAssertEqual(navigationController.pushCalled, 1)
        XCTAssertEqual(navigationController.presentedViewController, viewController)
        XCTAssertEqual(subject.completions.count, 1)
    }

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

    func testSetRootViewController() {
        let subject = DefaultRouter(navigationController: navigationController)
        let viewController = UIViewController()
        subject.setRootViewController(viewController, hideBar: true)

        XCTAssertEqual(navigationController.viewControllers, [viewController])
        XCTAssertEqual(navigationController.isNavigationBarHidden, true)
    }

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

    func testNavigationControllerDelegate_runsCompletionForPoppedViewController() {
        let subject = DefaultRouter(navigationController: navigationController)
        let expectation = expectation(description: "Completion is called")
        let viewController = UIViewController()

        navigationController.fromViewController = viewController
        subject.push(viewController) {
            expectation.fulfill()
        }
        subject.checkNavigationCompletion(for: navigationController)

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
