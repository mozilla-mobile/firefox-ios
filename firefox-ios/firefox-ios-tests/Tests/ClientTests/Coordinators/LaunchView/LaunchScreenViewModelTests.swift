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

        guard case .intro = delegate.savedLaunchType else {
            XCTFail("Expected intro, but was \(String(describing: delegate.savedLaunchType))")
            return
        }
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
    }

    func testLaunchType_termsOfService() {
        FxNimbus.shared.features.tosFeature.with(initializer: { _, _ in
            TosFeature(status: true)
        })

        let subject = createSubject()
        subject.delegate = delegate
        subject.startLoading(appVersion: "112.0")

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.finishedLoadingLaunchOrderCalled, 1)

        subject.loadNextLaunchType()

        guard case .termsOfService = delegate.savedLaunchType else {
            XCTFail("Expected terms of service, but was \(String(describing: delegate.savedLaunchType))")
            return
        }
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

        guard case .update = delegate.savedLaunchType else {
            XCTFail("Expected update, but was \(String(describing: delegate.savedLaunchType))")
            return
        }
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

        guard case .survey = delegate.savedLaunchType else {
            XCTFail("Expected survey, but was \(String(describing: delegate.savedLaunchType))")
            return
        }
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

    // MARK: - Helpers
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
