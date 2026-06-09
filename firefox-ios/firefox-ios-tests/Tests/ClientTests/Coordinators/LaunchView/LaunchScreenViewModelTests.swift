// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
import OnboardingKit
@testable import Client

@MainActor
final class LaunchScreenViewModelTests: XCTestCase {
    private var messageManager: MockGleanPlumbMessageManagerProtocol!
    private var profile: MockProfile!
    private var delegate: MockLaunchFinishedLoadingDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
        delegate = MockLaunchFinishedLoadingDelegate()
        messageManager = MockGleanPlumbMessageManagerProtocol()

        setTermsOfServiceFeatureEnabled(false)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        AppContainer.shared.reset()
        profile = nil
        messageManager = nil
        delegate = nil
        try await super.tearDown()
    }

    func testLaunchDoesntCallLoadedIfNotStarted() {
        let subject = createSubject()
        subject.delegate = delegate

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 0)
    }

    func testLaunchType_intro() {
        profile.prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)

        subject.loadNextLaunchType()

        assertSavedLaunchType(.intro(manager: IntroScreenManager(prefs: profile.prefs)))
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
    }

    func testLaunchType_termsOfService() {
        setTermsOfServiceFeatureEnabled(true)

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)

        subject.loadNextLaunchType()

        assertSavedLaunchType(.termsOfService(manager: TermsOfServiceManager(prefs: profile.prefs)))
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
    }

    func testLaunchType_survey() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        let message = createMessage()
        messageManager.message = message

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)

        subject.loadNextLaunchType()

        assertSavedLaunchType(.survey(manager: SurveySurfaceManager(windowUUID: windowUUID, and: messageManager)))
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
    }

    func testSplashScreenExperiment_afterShown_returnsTrue() {
        let subject = createSubject()
        let value = subject.getSplashScreenExperimentHasShown()
        XCTAssertFalse(value)

        subject.setSplashScreenExperimentHasShown()

        let updatedValue = subject.getSplashScreenExperimentHasShown()
        XCTAssertTrue(updatedValue)
    }

    // MARK: - Multiple Launch Types Tests

    func testLaunchType_termsOfServiceAndIntro_sequence() {
        setTermsOfServiceFeatureEnabled(true)

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)
        XCTAssertEqual(subject.launchOrder.count, 2)

        subject.loadNextLaunchType()
        assertSavedLaunchType(.termsOfService(manager: TermsOfServiceManager(prefs: profile.prefs)))
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
        XCTAssertEqual(subject.launchOrder.count, 1)

        subject.loadNextLaunchType()
        assertSavedLaunchType(.intro(manager: IntroScreenManager(prefs: profile.prefs)))
        XCTAssertEqual(delegate.launchWithTypeCalled, 2)
        XCTAssertEqual(subject.launchOrder.count, 0)

        subject.loadNextLaunchType()
        XCTAssertEqual(delegate.launchBrowserCalled, 1)
        XCTAssertEqual(delegate.launchWithTypeCalled, 2)
    }

    // MARK: - Empty Launch Order Tests

    func testLaunchType_noScreensToShow_launchesBrowserDirectly() {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        messageManager.message = nil

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(subject.launchOrder.count, 0)
        XCTAssertEqual(delegate.launchBrowserCalled, 1)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 0)
    }

    func testLoadNextLaunchType_whenEmpty_launchesBrowser() {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        messageManager.message = nil

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        subject.loadNextLaunchType()
        XCTAssertEqual(delegate.launchBrowserCalled, 2)
        XCTAssertEqual(subject.launchOrder.count, 0)
    }

    // MARK: - Delegate Tests

    func testLoadNextLaunchType_withoutDelegate_doesNotCrash() {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        messageManager.message = nil

        let subject = createSubject()
        subject.delegate = nil
        subject.startLoading(appVersion: "112.0")

        subject.loadNextLaunchType()
        XCTAssertEqual(subject.launchOrder.count, 0)
    }

    func testStartLoading_withoutDelegate_doesNotCrash() {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        messageManager.message = nil

        let subject = createSubject()
        subject.delegate = nil

        subject.startLoading(appVersion: "112.0")
        XCTAssertEqual(subject.launchOrder.count, 0)
    }

    // MARK: - Launch Order Property Tests

    func testLaunchOrder_initiallyEmpty() {
        let subject = createSubject()
        XCTAssertEqual(subject.launchOrder.count, 0)
    }

    func testLaunchOrder_afterStartLoading_containsExpectedTypes() {
        profile.prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(subject.launchOrder.count, 1)
        if case .intro = subject.launchOrder.first {
        } else {
            XCTFail("Expected intro as first launch type")
        }
    }

    func testLaunchOrder_afterLoadingAllTypes_isEmpty() {
        profile.prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(subject.launchOrder.count, 1)
        subject.loadNextLaunchType()
        XCTAssertEqual(subject.launchOrder.count, 0)
    }

    // MARK: - Custom IntroScreenManager Tests

    func testInit_withCustomIntroScreenManager_usesInjectedManager() {
        profile.prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)

        let mockIntroManager = MockIntroScreenManager(
            shouldShowIntro: true,
            isModernEnabled: false
        )

        let subject = LaunchScreenViewModel(
            windowUUID: windowUUID,
            profile: profile,
            messageManager: messageManager,
            introScreenManager: mockIntroManager
        )
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)
        XCTAssertEqual(subject.launchOrder.count, 1)
        if case .intro = subject.launchOrder.first {
        } else {
            XCTFail("Expected intro launch type")
        }
    }

    func testInit_withCustomIntroScreenManager_notShowingIntro_skipsIntro() {
        let mockIntroManager = MockIntroScreenManager(
            shouldShowIntro: false,
            isModernEnabled: false
        )

        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        let subject = LaunchScreenViewModel(
            windowUUID: windowUUID,
            profile: profile,
            messageManager: messageManager,
            introScreenManager: mockIntroManager
        )
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(subject.launchOrder.count, 0)
    }

    // MARK: - App Version Tests

    func testStartLoading_withDefaultAppVersion_usesAppInfoVersion() {
        profile.prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading()

        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)
    }

    // MARK: - Survey Screen Tests

    func testLaunchType_survey_whenAvailable_showsSurvey() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        let message = createMessage()
        messageManager.message = message

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)

        subject.loadNextLaunchType()

        assertSavedLaunchType(.survey(manager: SurveySurfaceManager(windowUUID: windowUUID, and: messageManager)))
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
    }

    func testLaunchType_survey_whenNotAvailable_doesNotShowSurvey() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        messageManager.message = nil

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(subject.launchOrder.count, 0)
        XCTAssertEqual(delegate.launchBrowserCalled, 1)
    }

    // MARK: - Splash Screen Experiment Tests

    func testSplashScreenExperiment_initiallyNotShown() {
        let subject = createSubject()
        XCTAssertFalse(subject.getSplashScreenExperimentHasShown())
    }

    func testSplashScreenExperiment_setThenGet_returnsTrue() {
        let subject = createSubject()
        subject.setSplashScreenExperimentHasShown()
        XCTAssertTrue(subject.getSplashScreenExperimentHasShown())
    }

    func testSplashScreenExperiment_multipleSets_staysTrue() {
        let subject = createSubject()
        subject.setSplashScreenExperimentHasShown()
        subject.setSplashScreenExperimentHasShown()
        subject.setSplashScreenExperimentHasShown()
        XCTAssertTrue(subject.getSplashScreenExperimentHasShown())
    }

    // MARK: - Helpers

    private func setTermsOfServiceFeatureEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.tosFeature.with(initializer: { _, _ in
            TosFeature(status: enabled)
        })
    }

    private func assertSavedLaunchType(
        _ expected: LaunchType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let saved = delegate.savedLaunchType else {
            XCTFail("Expected \(expected) but savedLaunchType was nil", file: file, line: line)
            return
        }

        switch (saved, expected) {
        case (.intro, .intro),
             (.termsOfService, .termsOfService),
             (.survey, .survey),
             (.defaultBrowser, .defaultBrowser):
            break
        default:
            XCTFail("Expected \(expected) but was \(saved)", file: file, line: line)
        }
    }

    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> LaunchScreenViewModel {
        let subject = LaunchScreenViewModel(windowUUID: windowUUID,
                                            profile: profile,
                                            messageManager: messageManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createMessage(
        for surface: MessageSurfaceId = .survey,
        action: String = "OPEN_NEW_TAB"
    ) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: false)

        return GleanPlumbMessage(id: "test-notification",
                                 data: MockNotificationMessageDataProtocol(surface: surface),
                                 action: action,
                                 triggerIfAll: [],
                                 exceptIfAny: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }
}
