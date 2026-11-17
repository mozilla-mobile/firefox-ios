// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import XCTest
import Common
@testable import Client

@MainActor
class AppSettingsTableViewControllerTests: XCTestCase {
    private var profile: Profile!
    private var tabManager: MockTabManager!
    private var appAuthenticator: MockAppAuthenticator!
    private var delegate: MockSettingsFlowDelegate!
    private var applicationHelper: MockApplicationHelper!
    private var mockSettingsDelegate: MockSettingsDelegate!
    private var mockParentCoordinator: MockSettingsFlowDelegate!
    private var mockGleanUsageReportingMetricsService: MockGleanUsageReportingMetricsService!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.profile = makeProfile()
        self.tabManager = MockTabManager()
        self.appAuthenticator = MockAppAuthenticator()
        self.delegate = MockSettingsFlowDelegate()
        self.applicationHelper = MockApplicationHelper()
        self.mockSettingsDelegate = MockSettingsDelegate()
        self.mockParentCoordinator = MockSettingsFlowDelegate()
        self.mockGleanUsageReportingMetricsService = MockGleanUsageReportingMetricsService(profile: makeProfile())
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        self.profile = nil
        self.tabManager = nil
        self.appAuthenticator = nil
        self.delegate = nil
        self.applicationHelper = nil
        try await super.tearDown()
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

    func testGenerateSettings_whenRetainedBySubject_subjectDeallocates() {
        let subject = createSubject()

        subject.settings = subject.generateSettings()

        XCTAssertFalse(subject.settings.isEmpty)
    }

    #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
    func testInstallationFlowPicker_doesNotChangeStateBeforeSelection() throws {
        let settings = ResetHistorySettingsSpy(windowUUID: .XCTestDefaultUUID)
        let historyStore = ResetHistoryStoreMock()
        profile.prefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
        let subject = ResetInstallationHistorySetting(settings: settings,
                                                      historyStore: historyStore,
                                                      installationPrefs: profile.prefs)
        subject.theme = LightTheme()

        XCTAssertEqual(subject.title?.string, "Test installation flow")
        subject.onClick(nil)

        XCTAssertEqual(historyStore.resetCallCount, 0)
        XCTAssertEqual(historyStore.loadCallCount, 0)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.installationProcessedKey), true)
        let alert = try XCTUnwrap(settings.alert)
        XCTAssertEqual(alert.title, "Test installation flow")
        XCTAssertEqual(alert.actions.map(\.title), ["New installation", "Reinstall", .CancelString])
        XCTAssertEqual(alert.actions.first?.style, .destructive)
        XCTAssertEqual(alert.actions.last?.style, .cancel)
    }

    func testNewInstallation_clearsHistoryAndMarksProcessingPending() {
        let settings = ResetHistorySettingsSpy(windowUUID: .XCTestDefaultUUID)
        let historyStore = ResetHistoryStoreMock()
        historyStore.state = .valid(InstallationHistory(installCounter: 4, lastSeenDate: Date()))
        profile.prefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        let subject = ResetInstallationHistorySetting(settings: settings,
                                                      historyStore: historyStore,
                                                      installationPrefs: profile.prefs)

        subject.prepare(.newInstallation)

        XCTAssertEqual(historyStore.resetCallCount, 1)
        XCTAssertEqual(historyStore.state, .missing)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.installationProcessedKey), false)
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.IntroSeen), 1)
        XCTAssertEqual(settings.alert?.title, "New installation ready")
    }

    func testReinstall_preservesHistoryAndMarksProcessingPending() {
        let settings = ResetHistorySettingsSpy(windowUUID: .XCTestDefaultUUID)
        let historyStore = ResetHistoryStoreMock()
        let history = InstallationHistory(installCounter: 4, lastSeenDate: Date(timeIntervalSince1970: 60))
        historyStore.state = .valid(history)
        profile.prefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
        let subject = ResetInstallationHistorySetting(settings: settings,
                                                      historyStore: historyStore,
                                                      installationPrefs: profile.prefs)

        subject.prepare(.reinstall)

        XCTAssertEqual(historyStore.resetCallCount, 0)
        XCTAssertEqual(historyStore.state, .valid(history))
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.installationProcessedKey), false)
        XCTAssertEqual(settings.alert?.title, "Reinstall ready")
    }

    func testReinstall_withoutValidHistory_doesNotResetProcessing() {
        let settings = ResetHistorySettingsSpy(windowUUID: .XCTestDefaultUUID)
        let historyStore = ResetHistoryStoreMock()
        profile.prefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
        let subject = ResetInstallationHistorySetting(settings: settings,
                                                      historyStore: historyStore,
                                                      installationPrefs: profile.prefs)

        for state in [InstallationHistoryState.missing, .corrupt] {
            historyStore.state = state
            subject.prepare(.reinstall)

            XCTAssertEqual(historyStore.resetCallCount, 0)
            XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.installationProcessedKey), true)
            XCTAssertEqual(settings.alert?.title, "Installation history needed")
        }
    }

    func testInstallationFlow_whenKeychainFails_doesNotResetProcessing() {
        let settings = ResetHistorySettingsSpy(windowUUID: .XCTestDefaultUUID)
        let historyStore = ResetHistoryStoreMock()
        historyStore.error = InstallationHistoryError.invalidValue
        profile.prefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
        let subject = ResetInstallationHistorySetting(settings: settings,
                                                      historyStore: historyStore,
                                                      installationPrefs: profile.prefs)

        for flow in [ResetInstallationHistorySetting.Flow.newInstallation, .reinstall] {
            subject.prepare(flow)

            XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.installationProcessedKey), true)
            XCTAssertEqual(settings.alert?.title, "Could not prepare installation flow")
        }
    }

    func testInstallationDetails_whenHistoryExists_showsValuesWithoutChangingHistory() async {
        let settings = ResetHistorySettingsSpy(windowUUID: .XCTestDefaultUUID)
        let historyStore = ResetHistoryStoreMock()
        historyStore.state = .valid(InstallationHistory(installCounter: 4, lastSeenDate: Date(timeIntervalSince1970: 60)))
        let acquisition = InstallationDetailsAcquisitionMock()
        acquisition.result = .available(AppAcquisition(originalPurchaseDate: Date(timeIntervalSince1970: 0),
                                                       originalAppVersion: "42"))
        profile.prefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
        let subject = InstallationDetailsSetting(settings: settings,
                                                 historyStore: historyStore,
                                                 acquisition: acquisition,
                                                 installationPrefs: profile.prefs)

        let message = await subject.details()

        XCTAssertTrue(message.contains("Processing: Complete"))
        XCTAssertTrue(message.contains("Install count: 4"))
        XCTAssertTrue(message.contains("Last seen (UTC): 1970-01-01T00:01:00Z"))
        XCTAssertTrue(message.contains("Original purchase date (UTC): 1970-01-01"))
        XCTAssertTrue(message.contains("Original app version: 42"))
        XCTAssertEqual(historyStore.loadCallCount, 1)
        XCTAssertEqual(historyStore.resetCallCount, 0)
    }

    func testInstallationDetails_whenValuesAreUnavailable_showsTheirStates() async {
        let settings = ResetHistorySettingsSpy(windowUUID: .XCTestDefaultUUID)
        let historyStore = ResetHistoryStoreMock()
        let acquisition = InstallationDetailsAcquisitionMock()
        let subject = InstallationDetailsSetting(settings: settings,
                                                 historyStore: historyStore,
                                                 acquisition: acquisition,
                                                 installationPrefs: profile.prefs)
        profile.prefs.setBool(false, forKey: PrefsKeys.installationProcessedKey)

        let missingMessage = await subject.details()

        XCTAssertTrue(missingMessage.contains("Processing: Pending"))
        XCTAssertTrue(missingMessage.contains("Retained history: Missing"))
        XCTAssertTrue(missingMessage.contains("StoreKit request failed"))
        historyStore.state = .corrupt
        acquisition.result = .unavailable(.unverified)
        profile.prefs.removeObjectForKey(PrefsKeys.installationProcessedKey)

        let corruptMessage = await subject.details()

        XCTAssertTrue(corruptMessage.contains("Processing: Not initialized"))
        XCTAssertTrue(corruptMessage.contains("Retained history: Corrupt"))
        XCTAssertTrue(corruptMessage.contains("Unverified transaction"))
        historyStore.error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "History locked"])
        acquisition.result = .unavailable(.unsupportedOS)

        let errorMessage = await subject.details()

        XCTAssertTrue(errorMessage.contains("History locked"))
        XCTAssertTrue(errorMessage.contains("Requires iOS 16 or later"))
        XCTAssertFalse(errorMessage.contains("Install count:"))
        XCTAssertEqual(historyStore.resetCallCount, 0)
    }
    #endif

    // MARK: - Helper
    private func createSubject() -> AppSettingsTableViewController {
        let subject = AppSettingsTableViewController(
            with: profile,
            and: tabManager,
            settingsDelegate: mockSettingsDelegate,
            parentCoordinator: mockParentCoordinator,
            gleanUsageReportingMetricsService: mockGleanUsageReportingMetricsService,
            appAuthenticator: appAuthenticator,
            applicationHelper: applicationHelper
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

#if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
@MainActor
private final class ResetHistorySettingsSpy: SettingsTableViewController {
    private(set) var alert: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
        alert = viewControllerToPresent as? UIAlertController
    }
}

@MainActor
private final class ResetHistoryStoreMock: InstallationHistoryStoring {
    var state: InstallationHistoryState = .missing
    var error: Error?
    private(set) var loadCallCount = 0
    private(set) var resetCallCount = 0

    func load() throws -> InstallationHistoryState {
        loadCallCount += 1
        if let error { throw error }
        return state
    }

    func save(_ history: InstallationHistory) throws {
        XCTFail("Reset must not save history")
    }

    func resetForTesting() throws {
        resetCallCount += 1
        if let error { throw error }
        state = .missing
    }
}

@MainActor
private final class InstallationDetailsAcquisitionMock: AppAcquisitionProviding {
    var result: AcquisitionOutcome = .unavailable(.storeKitFailure)

    func fetch() async -> AcquisitionOutcome { result }
}
#endif
