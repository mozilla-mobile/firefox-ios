// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class RouteTests: XCTestCase {
    func testSearchRouteWithUrl() {
        let subject = createSubject()
        let url = URL(string: "http://google.com?a=1&b=2&c=foo%20bar")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(
            route,
            .search(
                url: URL(string: "http://google.com?a=1&b=2&c=foo%20bar")!,
                isPrivate: false,
                options: [.focusLocationField]
            )
        )
    }

    func testSearchRouteWithEncodedUrl() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?url=http%3A%2F%2Fgoogle.com%3Fa%3D1%26b%3D2%26c%3Dfoo%2520bar")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: URL(string: "http://google.com?a=1&b=2&c=foo%20bar"), isPrivate: false))
    }

    func testSearchRouteWithPrivateFlag() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?private=true")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: nil, isPrivate: true))
    }

    func testSettingsRouteWithClearPrivateData() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/clear-private-data")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .clearPrivateData))
    }

    func testSettingsRouteWithNewTab() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/newTab")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .newTab))
    }

    func testSettingsRouteWithNewTabTrailingSlash() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/newTab/")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .newTab))
    }

    func testSettingsRouteWithHomePage() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/homePage")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .homePage))
    }

    func testSettingsRouteWithMailto() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/mailto")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .mailto))
    }

    func testSettingsRouteWithSearch() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/search")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .search))
    }

    func testSettingsRouteWithFxa() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/fxa")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .fxa))
    }

    func testHomepanelRouteWithBookmarks() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/homepanel/bookmarks")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .homepanel(section: .bookmarks))
    }

    func testHomepanelRouteWithTopSites() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/homepanel/top-sites")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .homepanel(section: .topSites))
    }

    func testHomepanelRouteWithHistory() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/homepanel/history")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .homepanel(section: .history))
    }

    func testHomepanelRouteWithReadingList() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/homepanel/reading-list")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .homepanel(section: .readingList))
    }

    func testDefaultBrowserRouteWithTutorial() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/default-browser/tutorial")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .defaultBrowser(section: .tutorial))
    }

    func testDefaultBrowserRouteWithSystemSettings() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/default-browser/system-settings")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .defaultBrowser(section: .systemSettings))
    }

    func testInvalidRouteWithBadPath() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/homepanel/badbad")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testFxaSignInrouteBuilderRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://fxa-signin?signin=coolcodes&user=foo&email=bar")!

        let route = subject.makeRoute(url: url)

        let expectedQuery = ["signin": "coolcodes", "user": "foo", "email": "bar"]
        XCTAssertEqual(route, .fxaSignIn(params: FxALaunchParams(entrypoint: .fxaDeepLinkNavigation,
                                                                 query: expectedQuery)))
    }

    func testInvalidScheme() {
        let subject = createSubject()
        let url = URL(string: "focus://deep-link?url=/settings/newTab")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testWhenJSSchemeWithSearchThenDoesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testMakeRouteWhenJSSchemeWithAlertThenDoesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?url=javascript:alert(1)")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testMakeRouteWhenJSSchemeWithWindowCloseThenDoesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?url=javascript:window.close();alert(1337)")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testInvalidDeepLink() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-links-are-fun?url=/settings/newTab/")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testWidgetMediumTopSitesOpenUrl() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-medium-topsites-open-url?url=https://google.com")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: URL(string: "https://google.com"), isPrivate: false))
    }

    func testWidgetSmallQuicklinkOpenUrlWithPrivateFlag() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-small-quicklink-open-url?private=true&url=https://google.com")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(
            route,
            .search(url: URL(string: "https://google.com"), isPrivate: true, options: [.focusLocationField])
        )
    }

    func testWidgetMediumQuicklinkOpenUrlWithoutPrivateFlag() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-medium-quicklink-open-url?url=https://google.com")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(
            route,
            .search(url: URL(string: "https://google.com"), isPrivate: false, options: [.focusLocationField])
        )
    }

    func testWidgetSmallQuicklinkOpenCopied() {
        let subject = createSubject()
        UIPasteboard.general.string = "test search text"
        let url = URL(string: "firefox://widget-small-quicklink-open-copied")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .searchQuery(query: "test search text", isPrivate: false))
    }

    func testWidgetSmallQuicklinkOpenCopiedWithUrl() {
        let subject = createSubject()
        UIPasteboard.general.url = URL(string: "https://google.com")
        let url = URL(string: "firefox://widget-small-quicklink-open-copied")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: URL(string: "https://google.com"), isPrivate: false))
    }

    func testWidgetSmallQuicklinkClosePrivateTabs() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-small-quicklink-close-private-tabs")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .action(action: .closePrivateTabs))
    }

    func testWidgetMediumQuicklinkClosePrivateTabs() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-medium-quicklink-close-private-tabs")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .action(action: .closePrivateTabs))
    }

    func testUnsupportedScheme() {
        let subject = createSubject()
        let url = URL(string: "chrome://example.com")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testInvalidHost() {
        let subject = createSubject()
        let url = URL(string: "firefox://")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testInvalidDeepLinking() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/invalid-path")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testInvalidWidgetTabUuid() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-tabs-medium-open-url?uuid=invalid")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: nil, isPrivate: false))
    }

    func testInvalidFxaSignIn() {
        let subject = createSubject()
        let url = URL(string: "firefox://fxa-signin")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testOpenText() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-text?text=google")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .searchQuery(query: "google", isPrivate: false))
    }

    func testShareSheetRouteUrlOnly() {
        let testURL = URL(string: "https://www.google.com")!
        let shareURL = URL(string: "firefox://share-sheet?url=\(testURL.absoluteString)")!
        let subject = createSubject()

        let route = subject.makeRoute(url: shareURL)

        XCTAssertEqual(route, .sharesheet(shareType: .site(url: testURL), shareMessage: nil))
    }

    func testShareSheetRouteUrlTitle() {
        let testURL = URL(string: "https://www.google.com")!
        let testTitle = "TEST TITLE"
        let shareURL = URL(string: "firefox://share-sheet?url=\(testURL.absoluteString)&title=\(testTitle)")!

        let subject = createSubject()

        let route = subject.makeRoute(url: shareURL)

        let expectedShareType = ShareType.site(url: testURL)
        let expectedShareMessage = ShareMessage(message: testTitle, subtitle: nil)
        XCTAssertEqual(route, .sharesheet(shareType: expectedShareType, shareMessage: expectedShareMessage))
    }

    func testShareSheetRouteUrlTitleAndSubtitle() {
        let testURL = URL(string: "https://www.google.com")!
        let testTitle = "TEST TITLE"
        let testSubtitle = "TEST SUBTITLE"
        let shareURL = URL(string: "firefox://share-sheet?url=\(testURL.absoluteString)&title=\(testTitle)&subtitle=\(testSubtitle)")!

        let subject = createSubject()

        let route = subject.makeRoute(url: shareURL)

        let expectedShareType = ShareType.site(url: testURL)
        let expectedShareMessage = ShareMessage(message: testTitle, subtitle: testSubtitle)
        XCTAssertEqual(route, .sharesheet(shareType: expectedShareType, shareMessage: expectedShareMessage))
    }

    // MARK: - AppAction

    func testAppAction_showIntroOnboarding() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/action/show-intro-onboarding")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .action(action: .showIntroOnboarding))
    }

    // MARK: - Helper

    func createSubject() -> RouteBuilder {
        let subject = RouteBuilder()
        subject.configure(isPrivate: false, prefs: MockProfile().prefs)
        trackForMemoryLeaks(subject)
        return subject
    }
}
