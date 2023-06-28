// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
@testable import Client

final class PasswordManagerCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() {
        super.tearDown()
        self.mockRouter = nil
        DependencyHelperMock().reset()
    }

    func testStart_withShowOnboarding() {
        let subject = createSubject()

        subject.start(with: true)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is PasswordManagerOnboardingViewController)
    }

    func testStart_withDontShowOnboarding() {
        let subject = createSubject()

        subject.start(with: false)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is PasswordManagerListViewController)
    }

    func testShowPasswordManager() {
        let subject = createSubject()

        subject.showPasswordManager()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is PasswordManagerListViewController)
    }

    func testShowPasswordOnboarding() {
        let subject = createSubject()

        subject.showPasswordOnboarding()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is PasswordManagerOnboardingViewController)
    }

    func testPressedPasswordDetail() {
        let subject = createSubject()

        let mockLoginRecord = LoginRecord(
            credentials: URLCredential(user: "", password: "", persistence: .none),
            protectionSpace: URLProtectionSpace.fromOrigin("https://test.com")
        )
        let mockModel = PasswordDetailViewControllerModel(
            profile: MockProfile(),
            login: mockLoginRecord,
            webpageNavigationHandler: nil,
            breachRecord: nil
        )
        subject.pressedPasswordDetail(model: mockModel)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is PasswordDetailViewController)
    }

    // MARK: - Helper
    func createSubject() -> PasswordManagerCoordinator {
        let subject = PasswordManagerCoordinator(router: mockRouter, profile: MockProfile())
        trackForMemoryLeaks(subject)
        return subject
    }
}
