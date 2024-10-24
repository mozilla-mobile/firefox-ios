// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class QRCodeCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var parentCoordinator: MockParentCoordinator!

    override func setUp() {
        super.setUp()
        router = MockRouter(navigationController: UINavigationController())
        parentCoordinator = MockParentCoordinator()
    }

    override func tearDown() {
        super.tearDown()
        router = nil
        parentCoordinator = nil
    }

    func testShowQRCode_presentsQRCodeNavigationController() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is QRCodeNavigationController)
    }

    func testShowQRCode_setsDelegate() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        guard let qrCodeViewController = (
            router.presentedViewController as? QRCodeNavigationController
        )?.topViewController as? QRCodeViewController
        else {
            XCTFail("The QRCodeViewController has to exist")
            return
        }
        XCTAssertTrue(qrCodeViewController.qrCodeDelegate is MockQRCodeViewControllerDelegate)
    }

    func testShowQRCode_setsDismissHandler() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        guard let qrCodeViewController = (
            router.presentedViewController as? QRCodeNavigationController
        )?.topViewController as? QRCodeViewController
        else {
            XCTFail("The QRCodeViewController has to exist")
            return
        }
        XCTAssertTrue(qrCodeViewController.dismissHandler is QRCodeCoordinator)
    }

    func testShowQRCode_callsDidFinishOnParentCoordinator() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        guard let qrCodeViewController = (
            router.presentedViewController as? QRCodeNavigationController
        )?.topViewController as? QRCodeViewController
        else {
            XCTFail("The QRCodeViewController has to exist")
            return
        }
        // Since there is no capture device set, the controller should call dismiss on viewDidLoad()
        qrCodeViewController.loadViewIfNeeded()
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func testShowQRCode_callsDidFinishOnParentCoordinator_whenRouterCompletionIsCalled() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        router.savedCompletion?()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    private func createSubject() -> QRCodeCoordinator {
        let coordinator = QRCodeCoordinator(parentCoordinator: parentCoordinator,
                                            router: router)
        trackForMemoryLeaks(coordinator)
        return coordinator
    }
}
