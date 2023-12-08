// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class RemoteTabsCoordinatorTests: XCTestCase {
    private var mockProfile: MockProfile!
    private var mockRouter: MockRouter!
    private var mockApplicationHelper: MockApplicationHelper!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        mockRouter = MockRouter(navigationController: MockNavigationController())
        mockApplicationHelper = MockApplicationHelper()
    }

    override func tearDown() {
        super.tearDown()
        mockProfile = nil
        mockRouter = nil
        mockApplicationHelper = nil
        DependencyHelperMock().reset()
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

        XCTAssertEqual(mockApplicationHelper.openURLCalled, 1)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> RemoteTabsCoordinator {
        let subject = RemoteTabsCoordinator(profile: mockProfile,
                                            router: mockRouter,
                                            applicationHelper: mockApplicationHelper)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
