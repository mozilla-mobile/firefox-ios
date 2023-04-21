// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class RouteTests: XCTestCase {
    var routeBuilder: RouteBuilder!

    override func setUp() {
        super.setUp()
        self.routeBuilder = RouteBuilder { false }
    }

    override func tearDown() {
        super.tearDown()
        routeBuilder = nil
    }

    func testSearchRouteWithUrl() {
        let url = URL(string: "http://google.com?a=1&b=2&c=foo%20bar")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(url: URL(string: "http://google.com?a=1&b=2&c=foo%20bar")!, isPrivate: false))
    }

    func testSearchRouteWithEncodedUrl() {
        let url = URL(string: "firefox://open-url?url=http%3A%2F%2Fgoogle.com%3Fa%3D1%26b%3D2%26c%3Dfoo%2520bar")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(url: URL(string: "http://google.com?a=1&b=2&c=foo%20bar"), isPrivate: false))
    }

    func testSearchRouteWithPrivateFlag() {
        let url = URL(string: "firefox://open-url?private=true")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(url: nil, isPrivate: true))
    }

    func testSettingsRouteWithClearPrivateData() {
        let url = URL(string: "firefox://deep-link?url=/settings/clear-private-data")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .settings(section: .clearPrivateData))
    }

    func testSettingsRouteWithNewTab() {
        let url = URL(string: "firefox://deep-link?url=/settings/newTab")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .settings(section: .newTab))
    }

    func testSettingsRouteWithNewTabTrailingSlash() {
        let url = URL(string: "firefox://deep-link?url=/settings/newTab/")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .settings(section: .newTab))
    }

    func testSettingsRouteWithHomePage() {
        let url = URL(string: "firefox://deep-link?url=/settings/homePage")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .settings(section: .homePage))
    }

    func testSettingsRouteWithMailto() {
        let url = URL(string: "firefox://deep-link?url=/settings/mailto")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .settings(section: .mailto))
    }

    func testSettingsRouteWithSearch() {
        let url = URL(string: "firefox://deep-link?url=/settings/search")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .settings(section: .search))
    }

    func testSettingsRouteWithFxa() {
        let url = URL(string: "firefox://deep-link?url=/settings/fxa")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .settings(section: .fxa))
    }

    func testHomepanelRouteWithBookmarks() {
        let url = URL(string: "firefox://deep-link?url=/homepanel/bookmarks")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .homepanel(section: .bookmarks))
    }

    func testHomepanelRouteWithTopSites() {
        let url = URL(string: "firefox://deep-link?url=/homepanel/top-sites")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .homepanel(section: .topSites))
    }

    func testHomepanelRouteWithHistory() {
        let url = URL(string: "firefox://deep-link?url=/homepanel/history")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .homepanel(section: .history))
    }

    func testHomepanelRouteWithReadingList() {
        let url = URL(string: "firefox://deep-link?url=/homepanel/reading-list")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .homepanel(section: .readingList))
    }

    func testDefaultBrowserRouteWithTutorial() {
        let url = URL(string: "firefox://deep-link?url=/default-browser/tutorial")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .defaultBrowser(section: .tutorial))
    }

    func testDefaultBrowserRouteWithSystemSettings() {
        let url = URL(string: "firefox://deep-link?url=/default-browser/system-settings")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .defaultBrowser(section: .systemSettings))
    }

    func testInvalidRouteWithBadPath() {
        let url = URL(string: "firefox://deep-link?url=/homepanel/badbad")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertNil(route)
    }

    func testFxaSignInrouteBuilderRoute() {
        let url = URL(string: "firefox://fxa-signin?signin=coolcodes&user=foo&email=bar")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .fxaSignIn(FxALaunchParams(entrypoint: .fxaDeepLinkNavigation, query: ["signin": "coolcodes", "user": "foo", "email": "bar"])))
    }

    func testInvalidScheme() {
        let url = URL(string: "focus://deep-link?url=/settings/newTab")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertNil(route)
    }

    func testInvalidDeepLink() {
        let url = URL(string: "firefox://deep-links-are-fun?url=/settings/newTab/")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertNil(route)
    }

    func testWidgetMediumTopSitesOpenUrl() {
        let url = URL(string: "firefox://widget-medium-topsites-open-url?url=https://google.com")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(url: URL(string: "https://google.com"), isPrivate: false))
    }

    func testWidgetSmallQuicklinkOpenUrlWithPrivateFlag() {
        let url = URL(string: "firefox://widget-small-quicklink-open-url?private=true&url=https://google.com")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(url: URL(string: "https://google.com"), isPrivate: true))
    }

    func testWidgetMediumQuicklinkOpenUrlWithoutPrivateFlag() {
        let url = URL(string: "firefox://widget-medium-quicklink-open-url?url=https://google.com")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(url: URL(string: "https://google.com"), isPrivate: false))
    }

    func testWidgetSmallQuicklinkOpenCopied() {
        UIPasteboard.general.string = "test search text"
        let url = URL(string: "firefox://widget-small-quicklink-open-copied")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(query: "test search text"))
    }

    func testWidgetSmallQuicklinkOpenCopiedWithUrl() {
        UIPasteboard.general.url = URL(string: "https://google.com")
        let url = URL(string: "firefox://widget-small-quicklink-open-copied")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(url: URL(string: "https://google.com"), isPrivate: false))
    }

    func testWidgetSmallQuicklinkClosePrivateTabs() {
        let url = URL(string: "firefox://widget-small-quicklink-close-private-tabs")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .action(action: .closePrivateTabs))
    }

    func testWidgetMediumQuicklinkClosePrivateTabs() {
        let url = URL(string: "firefox://widget-medium-quicklink-close-private-tabs")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .action(action: .closePrivateTabs))
    }

    func testUnsupportedScheme() {
        let url = URL(string: "chrome://example.com")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertNil(route)
    }

    func testInvalidHost() {
        let url = URL(string: "firefox://")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertNil(route)
    }

    func testInvalidDeepLinking() {
        let url = URL(string: "firefox://deep-link?url=/invalid-path")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertNil(route)
    }

    func testInvalidWidgetTabUuid() {
        let url = URL(string: "firefox://widget-tabs-medium-open-url?uuid=invalid")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(url: nil, isPrivate: false))
    }

    func testInvalidFxaSignIn() {
        let url = URL(string: "firefox://fxa-signin")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertNil(route)
    }

    func testOpenText() {
        let url = URL(string: "firefox://open-text?text=google")!
        let route = routeBuilder.makeRoute(url: url)
        XCTAssertEqual(route, .search(query: "google"))
    }
}
