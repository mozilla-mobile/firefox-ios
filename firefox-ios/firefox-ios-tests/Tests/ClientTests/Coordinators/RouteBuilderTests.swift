// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class RouteBuilderTests: XCTestCase {
    let testURL = URL(string: "https://example.com")
    let handoffUserActivity = NSUserActivity(activityType: browsingActivityType)
    let universalLinkUserActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    let randomActivity = NSUserActivity(activityType: "random")

    override func setUp() async throws {
        try await super.setUp()
        handoffUserActivity.webpageURL = testURL
        universalLinkUserActivity.webpageURL = testURL
        randomActivity.webpageURL = testURL
    }

    override func tearDown() async throws {
        handoffUserActivity.webpageURL = nil
        universalLinkUserActivity.webpageURL = nil
        randomActivity.webpageURL = nil
        try await super.tearDown()
    }

    func test_makeRoute_HandlesAnyActivityType() {
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

        switch route {
        case .search(let url, let isPrivate, _):
            XCTAssertEqual(url, testURL)
            XCTAssertFalse(isPrivate)
        default:
            break
        }

        switch universalLinkRoute {
        case .search(let url, let isPrivate, _):
            XCTAssertEqual(url, testURL)
            XCTAssertFalse(isPrivate)
        default:
            break
        }

        switch randomRoute {
        case .search(let url, let isPrivate, _):
            XCTAssertEqual(url, testURL)
            XCTAssertFalse(isPrivate)
        default:
            break
        }
    }

    func test_makeRoute_AppIconShortcut_ReturnsAppIconSettingsRoute() {
        let routeBuilder = createSubject()
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let shortcut = UIApplicationShortcutItem(
            type: "\(bundleId).AppIcon",
            localizedTitle: "App Icon"
        )

        let route = routeBuilder.makeRoute(shortcutItem: shortcut, tabSetting: .topSites)

        guard case let .settings(section) = route else {
            XCTFail("Expected .settings route, got \(String(describing: route))")
            return
        }
        XCTAssertEqual(section, .appIcon)
    }

    func test_makeRoute_RapidSiriOpenTabActivitiesAreThrottledAndReset() async {
        let routeBuilder = createSubject()
        let userActivity = NSUserActivity(activityType: SiriShortcuts.activityType.openURL.rawValue)

        let firstRoute = routeBuilder.makeRoute(userActivity: userActivity)
        XCTAssertNotNil(firstRoute)

        let duplicateActivityRoute = routeBuilder.makeRoute(userActivity: userActivity)
        XCTAssertNil(duplicateActivityRoute)

        // Pretend time has passed by cancelling the Task.sleep and waiting for the task to finish
        routeBuilder.siriOpenTabThrottleResetTask?.cancel()
        await routeBuilder.siriOpenTabThrottleResetTask?.value

        let routeAfterThrottleReset = routeBuilder.makeRoute(userActivity: userActivity)
        XCTAssertNotNil(routeAfterThrottleReset)
    }

    private func createSubject() -> RouteBuilder {
        let subject = RouteBuilder()
        trackForMemoryLeaks(subject)
        return subject
    }
}
