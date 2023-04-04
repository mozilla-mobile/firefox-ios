// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client

final class LaunchScreenManagerTests: XCTestCase, LaunchFinishedLoadingDelegate {
    private var messageManager: MockGleanPlumbMessageManagerProtocol!
    var delegate: MockOpenURLDelegate!
    var profile: MockProfile!
    var launchTypeLoadedClosure: (() -> Void)?

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        delegate = MockOpenURLDelegate()
        messageManager = MockGleanPlumbMessageManagerProtocol()

        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
        messageManager = nil
        delegate = nil
        launchTypeLoadedClosure = nil

        UserDefaults.standard.set(false, forKey: PrefsKeys.NimbusFeatureTestsOverride)
    }

    func testLaunchType_intro() {
        let expectation = expectation(description: "LaunchTypeLoaded called")
        launchTypeLoadedClosure = { expectation.fulfill() }

        let subject = DefaultLaunchScreenManager(delegate: self,
                                                 profile: profile,
                                                 messageManager: messageManager,
                                                 appVersion: "112.0")

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(subject.getLaunchType(forType: .SceneCoordinator), .intro)
    }

    func testLaunchType_update() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        let expectation = expectation(description: "LaunchTypeLoaded called")
        launchTypeLoadedClosure = { expectation.fulfill() }
        let subject = DefaultLaunchScreenManager(delegate: self,
                                                 profile: profile,
                                                 messageManager: messageManager,
                                                 appVersion: "113.0")
        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(subject.getLaunchType(forType: .SceneCoordinator), .update)
    }

    func testLaunchType_survey() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        let message = createMessage(isExpired: false)
        messageManager.message = message

        let expectation = expectation(description: "LaunchTypeLoaded called")
        launchTypeLoadedClosure = { expectation.fulfill() }
        let subject = DefaultLaunchScreenManager(delegate: self,
                                                 profile: profile,
                                                 messageManager: messageManager)

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(subject.getLaunchType(forType: .SceneCoordinator), .survey)
    }

    func testLaunchType_nil() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        let message = createMessage(isExpired: true)
        messageManager.message = message

        let expectation = expectation(description: "LaunchTypeLoaded called")
        launchTypeLoadedClosure = { expectation.fulfill() }
        let subject = DefaultLaunchScreenManager(delegate: self,
                                                 profile: profile,
                                                 messageManager: messageManager)

        waitForExpectations(timeout: 0.1)
        XCTAssertNil(subject.getLaunchType(forType: .SceneCoordinator))
    }

    func testSetDelegate() {
        let subject = DefaultLaunchScreenManager(delegate: self,
                                                 profile: profile,
                                                 messageManager: messageManager)
        XCTAssertNil(subject.surveySurfaceManager.openURLDelegate)
        subject.set(openURLDelegate: delegate)
        XCTAssertNotNil(subject.surveySurfaceManager.openURLDelegate)
    }

    // MARK: LaunchFinishedLoadingDelegate

    func launchTypeLoaded() {
        launchTypeLoadedClosure?()
    }

    // MARK: Helpers

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
