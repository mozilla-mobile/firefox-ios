// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import CoreSpotlight

@testable import Client

class UserActivityRouteTests: XCTestCase {
    var routeBuilder: RouteBuilder!

    override func setUp() {
        super.setUp()
        self.routeBuilder = RouteBuilder { false }
    }

    override func tearDown() {
        super.tearDown()
        self.routeBuilder = nil
    }

    // Test the Route initializer with a Siri shortcut user activity.
    func testSiriShortcutUserActivity() {
        let userActivity = NSUserActivity(activityType: SiriShortcuts.activityType.openURL.rawValue)
        let route = routeBuilder.makeRoute(userActivity: userActivity)
        XCTAssertEqual(route, .search(url: nil, isPrivate: false))
    }

    // Test the Route initializer with a deep link user activity.
    func testDeepLinkUserActivity() {
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://www.example.com")
        let route = routeBuilder.makeRoute(userActivity: userActivity)
        XCTAssertEqual(route, .search(url: URL(string: "https://www.example.com"), isPrivate: false))
    }

    // Test the Route initializer with a CoreSpotlight user activity.
    func testCoreSpotlightUserActivity() {
        let userActivity = NSUserActivity(activityType: CSSearchableItemActionType)
        userActivity.userInfo = [CSSearchableItemActivityIdentifier: "https://www.example.com"]
        let route = routeBuilder.makeRoute(userActivity: userActivity)
        XCTAssertEqual(route, .search(url: URL(string: "https://www.example.com"), isPrivate: false))
    }

    // Test the Route initializer with an unsupported user activity.
    func testUnsupportedUserActivity() {
        let userActivity = NSUserActivity(activityType: "unsupported.activity.type")
        let route = routeBuilder.makeRoute(userActivity: userActivity)
        XCTAssertNil(route)
    }
}
