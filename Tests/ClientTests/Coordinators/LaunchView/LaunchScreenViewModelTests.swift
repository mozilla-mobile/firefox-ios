// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client

final class LaunchScreenViewModelTests: XCTestCase, LaunchFinishedLoadingDelegate {
    private var messageManager: MockGleanPlumbMessageManagerProtocol!
    private var profile: MockProfile!

    private var launchTypeLoadedClosure: ((LaunchType) -> Void)?
    private var launchBrowserClosure: (() -> Void)?

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        messageManager = MockGleanPlumbMessageManagerProtocol()

        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
        messageManager = nil
        launchTypeLoadedClosure = nil
        launchBrowserClosure = nil

        UserDefaults.standard.set(false, forKey: PrefsKeys.NimbusFeatureTestsOverride)
    }

    func testLaunchDoesntCallLoadedIfNotStarted() {
        let expectation = expectation(description: "LaunchTypeLoaded called")
        expectation.isInverted = true
        launchTypeLoadedClosure = { _ in expectation.fulfill() }
        let subject = LaunchScreenViewModel(profile: profile,
                                            messageManager: messageManager)
        subject.delegate = self

        waitForExpectations(timeout: 0.1)
    }

    func testLaunchType_intro() {
        let expectation = expectation(description: "LaunchTypeLoaded called")
        launchTypeLoadedClosure = { launchType in
            guard case .intro = launchType else {
                XCTFail("Expected intro, but was \(launchType)")
                return
            }
            expectation.fulfill()
        }

        let subject = LaunchScreenViewModel(profile: profile,
                                            messageManager: messageManager)
        subject.delegate = self
        subject.startLoading(appVersion: "112.0")

        waitForExpectations(timeout: 0.1)
    }

    func testLaunchType_update() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        let expectation = expectation(description: "LaunchTypeLoaded called")
        launchTypeLoadedClosure = { launchType in
            guard case .update = launchType else {
                XCTFail("Expected update, but was \(launchType)")
                return
            }
            expectation.fulfill()
        }

        let subject = LaunchScreenViewModel(profile: profile,
                                            messageManager: messageManager)
        subject.delegate = self
        subject.startLoading(appVersion: "113.0")

        waitForExpectations(timeout: 0.1)
    }

    func testLaunchType_survey() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        let message = createMessage(isExpired: false)
        messageManager.message = message

        let expectation = expectation(description: "LaunchTypeLoaded called")
        launchTypeLoadedClosure = { launchType in
            guard case .survey = launchType else {
                XCTFail("Expected survey, but was \(launchType)")
                return
            }
            expectation.fulfill()
        }
        let subject = LaunchScreenViewModel(profile: profile,
                                            messageManager: messageManager)
        subject.delegate = self
        subject.startLoading()

        waitForExpectations(timeout: 0.1)
    }

    func testLaunchType_nilBrowserIsStarted() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        let message = createMessage(isExpired: true)
        messageManager.message = message

        let expectation = expectation(description: "LaunchBrowserClosure called")
        launchBrowserClosure = { expectation.fulfill() }
        let subject = LaunchScreenViewModel(profile: profile,
                                            messageManager: messageManager)
        subject.delegate = self
        subject.startLoading()

        waitForExpectations(timeout: 0.1)
    }

    // MARK: - LaunchFinishedLoadingDelegate

    func launchWith(launchType: LaunchType) {
        launchTypeLoadedClosure?(launchType)
    }

    func launchBrowser() {
        launchBrowserClosure?()
    }

    // MARK: - Helpers

    private func createMessage(
        for surface: MessageSurfaceId = .survey,
        isExpired: Bool,
        action: String = "OPEN_NEW_TAB"
    ) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: isExpired)

        return GleanPlumbMessage(id: "test-notification",
                                 data: MockNotificationMessageDataProtocol(surface: surface),
                                 action: action,
                                 triggers: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }
}
