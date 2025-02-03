// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

final class RemoteTabsCoordinatorTests: XCTestCase {
    private var mockProfile: MockProfile!
    private var mockRouter: MockRouter!
    private var mockApplicationHelper: MockApplicationHelper!
    private var qrDelegate: MockQRCodeViewControllerDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        mockRouter = MockRouter(navigationController: MockNavigationController())
        mockApplicationHelper = MockApplicationHelper()
        qrDelegate = MockQRCodeViewControllerDelegate()
    }

    override func tearDown() {
        mockProfile = nil
        mockRouter = nil
        mockApplicationHelper = nil
        qrDelegate = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testInitialState() {
        let subject = createSubject()

        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testPresentFxASignIn() {
        let subject = createSubject()
        subject.presentFirefoxAccountSignIn()

        XCTAssertEqual(mockRouter.presentCalled, 1)
    }

    func testPresentFxASettings() {
        let subject = createSubject()
        subject.presentFxAccountSettings()

        XCTAssertEqual(mockApplicationHelper.openURLInWindowCalled, 1)
    }

    func testPresentQRCode() {
        let subject = createSubject()
        subject.showQRCode(delegate: qrDelegate)

        XCTAssertEqual(mockRouter.presentCalled, 1)
    }

    func testDidFinishCalled() {
        let subject = createSubject()
        subject.showQRCode(delegate: qrDelegate)

        guard let qrCodeCoordinator = subject.childCoordinators.first(where: {
            $0 is QRCodeCoordinator
        }) as? QRCodeCoordinator else {
            XCTFail("QRCodeCoordinator expected to be found")
            return
        }

        subject.didFinish(from: qrCodeCoordinator)
        XCTAssertEqual(subject.childCoordinators.count, 0)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> RemoteTabsCoordinator {
        let subject = RemoteTabsCoordinator(profile: mockProfile,
                                            router: mockRouter,
                                            windowUUID: windowUUID,
                                            applicationHelper: mockApplicationHelper)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
