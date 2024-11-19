// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

class AppSettingsTableViewControllerTests: XCTestCase {
    private var profile: Profile!
    private var tabManager: TabManager!
    private var appAuthenticator: MockAppAuthenticator!
    private var delegate: MockSettingsFlowDelegate!
    private var applicationHelper: MockApplicationHelper!
    private var mockSettingsDelegate: MockSettingsDelegate!
    private var mockParentCoordinator: MockSettingsFlowDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        self.tabManager = TabManagerImplementation(profile: profile,
                                                   uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        self.appAuthenticator = MockAppAuthenticator()
        self.delegate = MockSettingsFlowDelegate()
        self.applicationHelper = MockApplicationHelper()
        self.mockSettingsDelegate = MockSettingsDelegate()
        self.mockParentCoordinator = MockSettingsFlowDelegate()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        self.profile = nil
        self.tabManager = nil
        self.appAuthenticator = nil
        self.delegate = nil
        self.applicationHelper = nil
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

    func testPassword_whenNeedShowingLoginOnboarding_showOnboarding() {
        UserDefaults.standard.set(false, forKey: LoginOnboarding.HasSeenLoginOnboardingKey)
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.handle(route: .password)

        XCTAssertEqual(delegate.showPasswordManagerCalled, 1)
        XCTAssertTrue(delegate.savedShouldShowOnboarding)
    }

    func testPassword_whenHasAlreadyShownLoginOnboarding_authenticateAndShowPassword() {
        appAuthenticator.authenticationState = .deviceOwnerAuthenticated
        UserDefaults.standard.set(true, forKey: LoginOnboarding.HasSeenLoginOnboardingKey)
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.handle(route: .password)

        XCTAssertEqual(delegate.showPasswordManagerCalled, 1)
        XCTAssertFalse(delegate.savedShouldShowOnboarding)
    }

    func testPressedShowTour_openOnboardingDeeplinkURL() {
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.pressedShowTour()

        XCTAssertEqual(delegate.didFinishShowingSettingsCalled, 1)
        XCTAssertEqual(applicationHelper.lastOpenURL,
                       URL(string: "fennec://deep-link?url=/action/show-intro-onboarding")!)
    }

    func testShowExperiments_openExperiments() {
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.pressedExperiments()

        XCTAssertEqual(delegate.showExperimentsCalled, 1)
    }

    func testDelegatesAreSet() {
        let subject = createSubject()

        // NOTE: The subject holds a weak reference to these delegates, so we have to store them for the length of the test
        // duration, or else they will deallocate before the following assertion checks.
        XCTAssertNotNil(subject.settingsDelegate)
        XCTAssertNotNil(subject.parentCoordinator)
    }

    // MARK: - Helper
    private func createSubject() -> AppSettingsTableViewController {
        let subject = AppSettingsTableViewController(with: profile,
                                                     and: tabManager,
                                                     settingsDelegate: mockSettingsDelegate,
                                                     parentCoordinator: mockParentCoordinator,
                                                     appAuthenticator: appAuthenticator,
                                                     applicationHelper: applicationHelper)
        trackForMemoryLeaks(subject)
        return subject
    }
}
