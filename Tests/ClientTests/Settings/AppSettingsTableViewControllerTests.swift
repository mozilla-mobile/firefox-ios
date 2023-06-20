// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class AppSettingsTableViewControllerTests: XCTestCase {
    private var profile: Profile!
    private var tabManager: TabManager!
    private var appAuthenticator: MockAppAuthenticator!
    private var delegate: MockSettingsFlowDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.profile = MockProfile()
        self.tabManager = TabManagerImplementation(profile: profile, imageStore: nil)
        self.appAuthenticator = MockAppAuthenticator()
        self.delegate = MockSettingsFlowDelegate()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        self.profile = nil
        self.tabManager = nil
        self.appAuthenticator = nil
        self.delegate = nil
    }

    func testRouteNotHandled_delegatesArentCalled() {
        let subject = createSubject()
        subject.handle(route: .clearPrivateData)

        XCTAssertEqual(delegate.showCreditCardSettingsCalled, 0)
        XCTAssertEqual(delegate.showDevicePassCodeCalled, 0)
    }

    func testCreditCard_whenDeviceOwnerAuthenticated_showCreditCardSettings() {
        appAuthenticator.authenticationState = .deviceOwnerAuthenticated
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.handle(route: .creditCard)

        XCTAssertEqual(delegate.showCreditCardSettingsCalled, 1)
    }

    func testCreditCard_whenPassCodeRequired_showDevicePasscode() {
        appAuthenticator.authenticationState = .passCodeRequired
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.handle(route: .creditCard)

        XCTAssertEqual(delegate.showDevicePassCodeCalled, 1)
    }

    func testCreditCard_whenDeviceOwnerFailed_showNothing() {
        appAuthenticator.authenticationState = .deviceOwnerFailed
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.handle(route: .creditCard)

        XCTAssertEqual(delegate.showDevicePassCodeCalled, 0)
        XCTAssertEqual(delegate.showCreditCardSettingsCalled, 0)
    }

    // MARK: - Helper
    private func createSubject() -> AppSettingsTableViewController {
        let subject = AppSettingsTableViewController(with: profile,
                                                     and: tabManager,
                                                     appAuthenticator: appAuthenticator)
        trackForMemoryLeaks(subject)
        return subject
    }
}

// MARK: - MockSettingsFlowDelegate
class MockSettingsFlowDelegate: SettingsFlowDelegate {
    var showDevicePassCodeCalled = 0
    var showCreditCardSettingsCalled = 0
    var didFinishShowingSettingsCalled = 0

    func showDevicePassCode() {
        showDevicePassCodeCalled += 1
    }

    func showCreditCardSettings() {
        showCreditCardSettingsCalled += 1
    }

    func didFinishShowingSettings() {
        didFinishShowingSettingsCalled += 1
    }
}
