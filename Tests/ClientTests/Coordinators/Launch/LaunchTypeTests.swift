// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class LaunchTypeTests: XCTestCase {
    func testCanLaunch_surveyFromBrowserCoordinator() {
        let launchType = LaunchType.survey
        XCTAssertFalse(launchType.canLaunch(fromType: .BrowserCoordinator, isIphone: true))
        XCTAssertFalse(launchType.canLaunch(fromType: .BrowserCoordinator, isIphone: false))
    }

    func testCanLaunch_surveyFromSceneCoordinator() {
        let launchType = LaunchType.survey
        XCTAssertTrue(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: true))
        XCTAssertTrue(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: false))
    }

    func testCanLaunch_defaultBrowserFromBrowserCoordinator() {
        let launchType = LaunchType.defaultBrowser
        XCTAssertTrue(launchType.canLaunch(fromType: .BrowserCoordinator, isIphone: true))
        XCTAssertTrue(launchType.canLaunch(fromType: .BrowserCoordinator, isIphone: false))
    }

    func testCanLaunch_defaultBrowserFromSceneCoordinator() {
        let launchType = LaunchType.defaultBrowser
        XCTAssertFalse(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: true))
        XCTAssertFalse(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: false))
    }

    func testCanLaunch_introFromBrowserCoordinator() {
        let launchType = LaunchType.intro
        XCTAssertFalse(launchType.canLaunch(fromType: .BrowserCoordinator, isIphone: true))
        XCTAssertTrue(launchType.canLaunch(fromType: .BrowserCoordinator, isIphone: false))
    }

    func testCanLaunch_introFromSceneCoordinator() {
        let launchType = LaunchType.intro
        XCTAssertTrue(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: true))
        XCTAssertFalse(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: false))
    }

    func testCanLaunch_updateFromBrowserCoordinator() {
        let launchType = LaunchType.update
        XCTAssertTrue(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: true))
        XCTAssertFalse(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: false))
    }

    func testCanLaunch_updateFromSceneCoordinator() {
        let launchType = LaunchType.update
        XCTAssertTrue(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: true))
        XCTAssertFalse(launchType.canLaunch(fromType: .SceneCoordinator, isIphone: false))
    }

    // MARK: - Is full screen

    func testIsFullScreen_surveyIsAlwaysFullScreen() {
        let launchType = LaunchType.survey
        XCTAssertTrue(launchType.isFullScreenAvailable(isIphone: true))
        XCTAssertTrue(launchType.isFullScreenAvailable(isIphone: false))
    }

    func testIsFullScreen_defaultBrowserIsNeverFullScreen() {
        let launchType = LaunchType.defaultBrowser
        XCTAssertFalse(launchType.isFullScreenAvailable(isIphone: true))
        XCTAssertFalse(launchType.isFullScreenAvailable(isIphone: false))
    }

    func testIsFullScreen_introFullScreenOnIphone() {
        let launchType = LaunchType.intro
        XCTAssertTrue(launchType.isFullScreenAvailable(isIphone: true))
        XCTAssertFalse(launchType.isFullScreenAvailable(isIphone: false))
    }

    func testIsFullScreen_updateFullScreenOnIphone() {
        let launchType = LaunchType.update
        XCTAssertTrue(launchType.isFullScreenAvailable(isIphone: true))
        XCTAssertFalse(launchType.isFullScreenAvailable(isIphone: false))
    }
}
