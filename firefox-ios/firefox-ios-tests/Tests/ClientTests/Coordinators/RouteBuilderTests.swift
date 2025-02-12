// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

class RouteBuilderTests: XCTestCase {
    let testURL = URL(string: "https://example.com")
    let handoffUserActivity = NSUserActivity(activityType: browsingActivityType)
    let universalLinkUserActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    let randomActivity = NSUserActivity(activityType: "random")

    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        handoffUserActivity.webpageURL = testURL
        universalLinkUserActivity.webpageURL = testURL
        randomActivity.webpageURL = testURL
    }
    func test_makeRoute_HandlesAnyActivityType() {
        let routeBuilder = createSubject(mainQueue: MockDispatchQueue())

        let route = routeBuilder.makeRoute(
            userActivity: handoffUserActivity
        )

        let universalLinkRoute = routeBuilder.makeRoute(
            userActivity: universalLinkUserActivity
        )

        let randomRoute = routeBuilder.makeRoute(
            userActivity: randomActivity
        )

        XCTAssertEqual(route, .search(url: testURL, isPrivate: false))
        XCTAssertEqual(universalLinkRoute, .search(url: testURL, isPrivate: false))
        XCTAssertEqual(randomRoute, .search(url: testURL, isPrivate: false))
    }

    func test_makeRoute_ResetsShouldOpenNewTabAfterDelay() {
        let routeBuilder = createSubject(mainQueue: MockDispatchQueue())
        routeBuilder.shouldOpenNewTab = true
        let userActivity = NSUserActivity(activityType: SiriShortcuts.activityType.openURL.rawValue)

        _ = routeBuilder.makeRoute(userActivity: userActivity)

        XCTAssertTrue(routeBuilder.shouldOpenNewTab)
     }

    private func createSubject(mainQueue: MockDispatchQueue) -> RouteBuilder {
        let subject = RouteBuilder(mainQueue: mainQueue)
        trackForMemoryLeaks(subject)
        return subject
    }
}
