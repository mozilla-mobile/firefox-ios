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
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        delegate = MockLaunchFinishedLoadingDelegate()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        messageManager = MockGleanPlumbMessageManagerProtocol()

        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
        setTermsOfServiceFeatureEnabled(false)
    }

    override func tearDown() async throws {
        AppContainer.shared.reset()
        UserDefaults.standard.removeObject(forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
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

    func testLaunchType_update() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "113.0")

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)

        subject.loadNextLaunchType()

        let onboardingModel = createOnboardingViewModel()
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel, onboardingReason: .newUser)
        assertSavedLaunchType(.update(viewModel: UpdateViewModel(
            profile: profile,
            model: onboardingModel,
            telemetryUtility: telemetryUtility,
            windowUUID: windowUUID
        )))
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
            onboardingModel: createOnboardingViewModel(),
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
            onboardingModel: createOnboardingViewModel(),
            introScreenManager: mockIntroManager
        )
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(subject.launchOrder.count, 0)
    }

    // MARK: - App Version Tests

    func testStartLoading_withCustomAppVersion_usesProvidedVersion() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profile.hasSyncableAccountMock = true

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "113.0")

        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)
        XCTAssertEqual(subject.launchOrder.count, 1)
    }

    func testStartLoading_withDefaultAppVersion_usesAppInfoVersion() {
        profile.prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading()

        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)
    }

    // MARK: - Update Screen Tests

    func testLaunchType_update_withSyncableAccount_showsUpdate() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profile.hasSyncableAccountMock = true

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "113.0")

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)

        subject.loadNextLaunchType()

        let onboardingModel = createOnboardingViewModel()
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel, onboardingReason: .newUser)
        assertSavedLaunchType(.update(viewModel: UpdateViewModel(
            profile: profile,
            model: onboardingModel,
            telemetryUtility: telemetryUtility,
            windowUUID: windowUUID
        )))
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
    }

    func testLaunchType_update_withoutSyncableAccount_doesNotShowUpdate() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profile.hasSyncableAccountMock = false

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "113.0")

        XCTAssertEqual(subject.launchOrder.count, 0)
        XCTAssertEqual(delegate.launchBrowserCalled, 1)
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

    // MARK: - Priority Tests

    func testLaunchType_priority_introTakesPrecedenceOverUpdate() {
        profile.prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.hasSyncableAccountMock = true

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "113.0")

        XCTAssertEqual(subject.launchOrder.count, 1)
        subject.loadNextLaunchType()
        assertSavedLaunchType(.intro(manager: IntroScreenManager(prefs: profile.prefs)))
    }

    func testLaunchType_priority_updateTakesPrecedenceOverSurvey() {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.hasSyncableAccountMock = true
        let message = createMessage()
        messageManager.message = message

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "113.0")

        XCTAssertEqual(subject.launchOrder.count, 1)
        subject.loadNextLaunchType()
        let onboardingModel = createOnboardingViewModel()
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel, onboardingReason: .newUser)
        assertSavedLaunchType(.update(viewModel: UpdateViewModel(
            profile: profile,
            model: onboardingModel,
            telemetryUtility: telemetryUtility,
            windowUUID: windowUUID
        )))
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
             (.update, .update),
             (.survey, .survey),
             (.defaultBrowser, .defaultBrowser):
            break
        default:
            XCTFail("Expected \(expected) but was \(saved)", file: file, line: line)
        }
    }

    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> LaunchScreenViewModel {
        let onboardingModel = createOnboardingViewModel()

        let subject = LaunchScreenViewModel(windowUUID: windowUUID,
                                            profile: profile,
                                            messageManager: messageManager,
                                            onboardingModel: onboardingModel)
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

    func createOnboardingViewModel() -> OnboardingKitViewModel {
        let cards: [OnboardingKitCardInfoModel] = [
            createCard(index: 1),
            createCard(index: 2)
        ]

        return OnboardingKitViewModel(cards: cards,
                                      isDismissible: true)
    }

    func createCard(index: Int) -> OnboardingKitCardInfoModel {
        let buttons = OnboardingButtons<OnboardingActions>(
            primary: OnboardingButtonInfoModel<OnboardingActions>(
                title: "Button title \(index)",
                action: .forwardOneCard))
        return OnboardingKitCardInfoModel(
            cardType: .basic,
            name: "Name \(index)",
            order: index,
            title: "Title \(index)",
            body: "Body \(index)",
            link: nil,
            buttons: buttons,
            multipleChoiceButtons: [],
            onboardingType: .upgrade,
            a11yIdRoot: "A11y id \(index)",
            imageID: "Image id \(index)",
            instructionsPopup: nil,
            embededLinkText: []
        )
    }
}
