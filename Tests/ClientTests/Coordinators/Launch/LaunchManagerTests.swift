// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client

final class LaunchManagerTests: XCTestCase {
    private var messageManager: MockGleanPlumbMessageManagerProtocol!
    var profile: MockProfile!
    var delegate: MockOpenURLDelegate!

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
        delegate = nil
        messageManager = nil

        UserDefaults.standard.set(false, forKey: PrefsKeys.NimbusFeatureTestsOverride)
    }

    func testLaunchFromSceneCoordinator_isiPhone() {
        let subject = DefaultLaunchManager(profile: profile,
                                           openURLDelegate: delegate,
                                           isIphone: true)
        XCTAssertTrue(subject.canLaunchFromSceneCoordinator)
    }

    func testLaunchFromSceneCoordinator_isNotiPhone() {
        let subject = DefaultLaunchManager(profile: profile,
                                           openURLDelegate: delegate,
                                           isIphone: false)
        XCTAssertFalse(subject.canLaunchFromSceneCoordinator)
    }

    func testLaunchType_intro() {
        let subject = DefaultLaunchManager(profile: profile,
                                           openURLDelegate: delegate,
                                           isIphone: true)
        XCTAssertEqual(subject.getLaunchType(), .intro)
    }

    func testLaunchType_update() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        let subject = DefaultLaunchManager(profile: profile,
                                           openURLDelegate: delegate,
                                           isIphone: true)

        XCTAssertEqual(subject.getLaunchType(appVersion: "113.0"), .update)
    }

    func testLaunchType_survey() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        let subject = DefaultLaunchManager(profile: profile,
                                           openURLDelegate: delegate,
                                           isIphone: true)

        XCTAssertEqual(subject.getLaunchType(appVersion: "112.0"), .survey)
    }

    func testLaunchType_nilNoOnboardingShown() {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        let expiredMessage = createMessage(isExpired: true)
        messageManager.message = expiredMessage
        let subject = DefaultLaunchManager(profile: profile,
                                           openURLDelegate: delegate,
                                           messageManager: messageManager,
                                           isIphone: true)

        XCTAssertNil(subject.getLaunchType(appVersion: "112.0"))
    }

    // MARK: Helpers

    private func createMessage(
        for surface: MessageSurfaceId = .notification,
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
