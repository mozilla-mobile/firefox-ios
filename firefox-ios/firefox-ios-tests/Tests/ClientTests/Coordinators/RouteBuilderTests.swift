// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
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
    func test_makeRoute_whenUniversalLinkIsDisabled_HandlesAnyACtivityType() {
        setupNimbusUniversalLinksTesting(isEnabled: false)
        let routeBuilder = createSubject()

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

    func test_makeRoute_whenUniversalLinkIsEnabled_handlesWebpageURLForActivityTypeBrowsingActivityAndBrowsingWeb() {
        setupNimbusUniversalLinksTesting(isEnabled: true)
        let routeBuilder = createSubject()

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
        XCTAssertNil(randomRoute)
    }

    private func createSubject() -> RouteBuilder {
        let subject = RouteBuilder()
        trackForMemoryLeaks(subject)
        return subject
    }

    private func setupNimbusUniversalLinksTesting(isEnabled: Bool) {
        FxNimbus.shared.features.universalLinks.with { _, _ in
            return UniversalLinks(
                enabled: isEnabled
            )
        }
    }
}
