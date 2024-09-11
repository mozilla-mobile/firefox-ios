// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import CoreSpotlight

@testable import Client

class UserActivityRouteTests: XCTestCase {
    // Test the Route initializer with a Siri shortcut user activity.
    func testSiriShortcutUserActivity() {
        let subject = createSubject()
        let userActivity = NSUserActivity(activityType: SiriShortcuts.activityType.openURL.rawValue)

        let route = subject.makeRoute(userActivity: userActivity)

        XCTAssertEqual(route, .search(url: nil, isPrivate: false))
    }

    // Test the Route initializer with a deep link user activity.
    func testDeepLinkUserActivity() {
        let subject = createSubject()
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://www.example.com")

        let route = subject.makeRoute(userActivity: userActivity)

        XCTAssertEqual(route, .search(url: URL(string: "https://www.example.com"), isPrivate: false))
    }

    // Test the Route initializer with a CoreSpotlight user activity.
    func testCoreSpotlightUserActivity() {
        let subject = createSubject()
        let userActivity = NSUserActivity(activityType: CSSearchableItemActionType)
        userActivity.userInfo = [CSSearchableItemActivityIdentifier: "https://www.example.com"]

        let route = subject.makeRoute(userActivity: userActivity)

        XCTAssertEqual(route, .search(url: URL(string: "https://www.example.com"), isPrivate: false))
    }

    // Test the Route initializer with an unsupported user activity.
    func testUnsupportedUserActivity() {
        let subject = createSubject()
        let userActivity = NSUserActivity(activityType: "unsupported.activity.type")

        let route = subject.makeRoute(userActivity: userActivity)

        XCTAssertNil(route)
    }

    // MARK: - Helper

    func createSubject() -> RouteBuilder {
        let subject = RouteBuilder()
        subject.configure(isPrivate: false, prefs: MockProfile().prefs)
        trackForMemoryLeaks(subject)
        return subject
    }
}
