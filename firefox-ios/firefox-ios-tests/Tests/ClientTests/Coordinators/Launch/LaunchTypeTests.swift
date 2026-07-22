// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

final class LaunchTypeTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Video Intro
    func testCanLaunch_videoIntroFromSceneCoordinator() {
        let launchType = LaunchType.videoIntro
        XCTAssertTrue(launchType.canLaunch(fromType: .SceneCoordinator))
    }

    func testCanLaunch_videoIntroFromBrowserCoordinator() {
        let launchType = LaunchType.videoIntro
        XCTAssertFalse(launchType.canLaunch(fromType: .BrowserCoordinator))
    }

    func testIsFullScreen_videoIntroIsAlwaysFullScreen() {
        let launchType = LaunchType.videoIntro
        XCTAssertTrue(launchType.isFullScreenAvailable())
    }

    func testCanLaunch_surveyFromBrowserCoordinator() {
        let launchType = LaunchType.survey(manager: SurveySurfaceManager(windowUUID: windowUUID))
        XCTAssertFalse(launchType.canLaunch(fromType: .BrowserCoordinator))
    }

    func testCanLaunch_surveyFromSceneCoordinator() {
        let launchType = LaunchType.survey(manager: SurveySurfaceManager(windowUUID: windowUUID))
        XCTAssertTrue(launchType.canLaunch(fromType: .SceneCoordinator))
    }

    func testCanLaunch_defaultBrowserFromBrowserCoordinator() {
        let launchType = LaunchType.defaultBrowser
        XCTAssertTrue(launchType.canLaunch(fromType: .BrowserCoordinator))
    }

    func testCanLaunch_defaultBrowserFromSceneCoordinator() {
        let launchType = LaunchType.defaultBrowser
        XCTAssertFalse(launchType.canLaunch(fromType: .SceneCoordinator))
    }

    func testCanLaunch_termsOfServiceFromBrowserCoordinator() {
        let launchType = LaunchType.termsOfService(manager: TermsOfServiceManager(prefs: profile.prefs))
        XCTAssertFalse(launchType.canLaunch(fromType: .BrowserCoordinator))
    }

    func testCanLaunch_termsOfServiceFromSceneCoordinator() {
        let launchType = LaunchType.termsOfService(manager: TermsOfServiceManager(prefs: profile.prefs))
        XCTAssertTrue(launchType.canLaunch(fromType: .SceneCoordinator))
    }

    func testCanLaunch_introFromBrowserCoordinator() {
        let launchType = LaunchType.intro(manager: IntroScreenManager(prefs: profile.prefs))
        XCTAssertFalse(launchType.canLaunch(fromType: .BrowserCoordinator))
    }

    func testCanLaunch_introFromSceneCoordinator() {
        let launchType = LaunchType.intro(manager: IntroScreenManager(prefs: profile.prefs))
        XCTAssertTrue(launchType.canLaunch(fromType: .SceneCoordinator))
    }

    // MARK: - Is full screen

    func testIsFullScreen_surveyIsAlwaysFullScreen() {
        let launchType = LaunchType.survey(manager: SurveySurfaceManager(windowUUID: windowUUID))
        XCTAssertTrue(launchType.isFullScreenAvailable())
    }

    func testIsFullScreen_defaultBrowserIsNeverFullScreen() {
        let launchType = LaunchType.defaultBrowser
        XCTAssertFalse(launchType.isFullScreenAvailable())
    }

    func testIsFullScreen_introIsAlwaysFullScreen() {
        let launchType = LaunchType.intro(manager: IntroScreenManager(prefs: profile.prefs))
        XCTAssertTrue(launchType.isFullScreenAvailable())
    }
}
