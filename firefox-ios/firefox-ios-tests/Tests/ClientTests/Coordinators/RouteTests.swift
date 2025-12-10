// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
class RouteTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testSearchRouteWithUrl() {
        let subject = createSubject()
        let url = URL(string: "http://google.com?a=1&b=2&c=foo%20bar")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .search(let url, let isPrivate, let options):
            XCTAssertEqual(url, URL(string: "http://google.com?a=1&b=2&c=foo%20bar")!)
            XCTAssertFalse(isPrivate)
            XCTAssertEqual(options, [.focusLocationField])
        default:
            XCTFail("The route should be a search route")
        }
    }

    func testSearchRouteWithJS_shouldReturnFalse() {
        let subject = createSubject()
        let url = URL(string: "javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testSearchRouteWithEncodedUrl() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?url=http%3A%2F%2Fgoogle.com%3Fa%3D1%26b%3D2%26c%3Dfoo%2520bar")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .search(let url, let isPrivate, _):
            XCTAssertEqual(url, URL(string: "http://google.com?a=1&b=2&c=foo%20bar")!)
            XCTAssertFalse(isPrivate)
        default:
            XCTFail("The route should be a search route")
        }
    }

    func testSearchRouteWithPrivateFlag() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?private=true")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .search(let url, let isPrivate, _):
            XCTAssertNil(url)
            XCTAssertTrue(isPrivate)
        default:
            XCTFail("The route should be a search route")
        }
    }

    func testSettingsRouteWithClearPrivateData() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/clear-private-data")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .settings(let section):
            XCTAssertEqual(section, .clearPrivateData)
        default:
            XCTFail("The route should be a settings route")
        }
    }

    func testSettingsRouteWithNewTab() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/newTab")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .settings(let section):
            XCTAssertEqual(section, .newTab)
        default:
            XCTFail("The route should be a settings route")
        }
    }

    func testSettingsRouteWithNewTabTrailingSlash() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/newTab/")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .settings(let section):
            XCTAssertEqual(section, .newTab)
        default:
            XCTFail("The route should be a settings route")
        }
    }

    func testSettingsRouteWithHomePage() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/homePage")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .settings(let section):
            XCTAssertEqual(section, .homePage)
        default:
            XCTFail("The route should be a settings route")
        }
    }

    func testSettingsRouteWithMailto() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/mailto")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .settings(let section):
            XCTAssertEqual(section, .mailto)
        default:
            XCTFail("The route should be a settings route")
        }
    }

    func testSettingsRouteWithSearch() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/search")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .settings(let section):
            XCTAssertEqual(section, .search)
        default:
            XCTFail("The route should be a settings route")
        }
    }

    func testSettingsRouteWithFxa() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/settings/fxa")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .settings(let section):
            XCTAssertEqual(section, .fxa)
        default:
            XCTFail("The route should be a settings route")
        }
    }

    func testHomepanelRouteWithBookmarks() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/homepanel/bookmarks")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .homepanel(let section):
            XCTAssertEqual(section, .bookmarks)
        default:
            XCTFail("The route should be a homepanel route")
        }
    }

    func testHomepanelRouteWithTopSites() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/homepanel/top-sites")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .homepanel(let section):
            XCTAssertEqual(section, .topSites)
        default:
            XCTFail("The route should be a homepanel route")
        }
    }

    func testHomepanelRouteWithHistory() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/homepanel/history")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .homepanel(let section):
            XCTAssertEqual(section, .history)
        default:
            XCTFail("The route should be a homepanel route")
        }
    }

    func testHomepanelRouteWithReadingList() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/homepanel/reading-list")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .homepanel(let section):
            XCTAssertEqual(section, .readingList)
        default:
            XCTFail("The route should be a homepanel route")
        }
    }

    func testDefaultBrowserRouteWithTutorial() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/default-browser/tutorial")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .defaultBrowser(let section):
            XCTAssertEqual(section, .tutorial)
        default:
            XCTFail("The route should be a default browser route")
        }
    }

    func testDefaultBrowserRouteWithSystemSettings() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/default-browser/system-settings")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .defaultBrowser(let section):
            XCTAssertEqual(section, .systemSettings)
        default:
            XCTFail("The route should be a default browser route")
        }
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

        let expectedParams = FxALaunchParams(entrypoint: .fxaDeepLinkNavigation,
                                             query: expectedQuery)

        switch route {
        case .fxaSignIn(let params):
            XCTAssertEqual(params, expectedParams)
        default:
            XCTFail("The route should be a fxa sign in route")
        }
    }

    func test_makeRoute_forFXASignIn_withJS_doesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://fxa-signin?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
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

    func test_makeRoute_forDeepLinks_withJS_doesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    // MARK: Widgets
    func testWidgetMediumTopSitesOpenUrl() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-medium-topsites-open-url?url=https://google.com")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .search(let url, let isPrivate, _):
            XCTAssertEqual(url, URL(string: "https://google.com")!)
            XCTAssertFalse(isPrivate)
        default:
            XCTFail("The route should be a search route")
        }
    }

    func test_makeRoute_forMediumTopSitesWidget_withJS_doesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-medium-topsites-open-url?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testWidgetSmallQuicklinkOpenUrlWithPrivateFlag() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-small-quicklink-open-url?private=true&url=https://google.com")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .search(let url, let isPrivate, let options):
            XCTAssertEqual(url, URL(string: "https://google.com")!)
            XCTAssertTrue(isPrivate)
            XCTAssertEqual(options, [.focusLocationField])
        default:
            XCTFail("The route should be a search route")
        }
    }

    func test_makeRoute_forSmallQuickLinkWidget_withJS_doesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-small-quicklink-open-url?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testWidgetMediumQuicklinkOpenUrlWithoutPrivateFlag() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-medium-quicklink-open-url?url=https://google.com")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .search(let url, let isPrivate, let options):
            XCTAssertEqual(url, URL(string: "https://google.com")!)
            XCTAssertFalse(isPrivate)
            XCTAssertEqual(options, [.focusLocationField])
        default:
            XCTFail("The route should be a search route")
        }
    }

    func test_makeRoute_forMediumQuickLinkWidget_withJS_doesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-medium-quicklink-open-url?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testWidgetSmallQuicklinkOpenCopied() {
        let subject = createSubject()
        UIPasteboard.general.string = "test search text"
        let url = URL(string: "firefox://widget-small-quicklink-open-copied")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .searchQuery(let query, let isPrivate):
            XCTAssertEqual(query, "test search text")
            XCTAssertFalse(isPrivate)
        default:
            XCTFail("The route should be a search route")
        }
    }

    func test_makeRoute_forSmallQuickLinkOpenCopedWidget_withJS_doesntOpenRoute() {
        let subject = createSubject()
        UIPasteboard.general.string = "javascript://https://google.com%2Fsearch?q=foo"
        let url = URL(string: "firefox://widget-small-quicklink-open-copied")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testWidgetSmallQuicklinkOpenCopiedWithUrl() {
        let subject = createSubject()
        UIPasteboard.general.url = URL(string: "https://google.com")
        let url = URL(string: "firefox://widget-small-quicklink-open-copied")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .search(let url, let isPrivate, _):
            XCTAssertEqual(url, URL(string: "https://google.com")!)
            XCTAssertFalse(isPrivate)
        default:
            XCTFail("The route should be a search route")
        }
    }

    func test_makeRoute_forSmallQuickLinkWithURLWidgetOpenCopied_withJS_doesntOpenRoute() {
        let subject = createSubject()
        UIPasteboard.general.url = URL(string: "javascript://https://google.com%2Fsearch?q=foo")
        let url = URL(string: "firefox://widget-small-quicklink-open-copied")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testWidgetSmallQuicklinkClosePrivateTabs() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-small-quicklink-close-private-tabs")!

        let route = subject.makeRoute(url: url)
        switch route {
        case .action(let action):
            XCTAssertEqual(action, .closePrivateTabs)
        default:
            XCTFail("The route should be an action route")
        }
    }

    func test_makeRoute_forMediumQuickLinkCloseWidget_withJS_doesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-small-quicklink-close-private-tabs?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .action(let action):
            XCTAssertEqual(action, .closePrivateTabs)
        default:
            XCTFail("The route should be an action route")
        }
    }

    func testWidgetMediumQuicklinkClosePrivateTabs() {
        let subject = createSubject()
        let url = URL(string: "firefox://widget-medium-quicklink-close-private-tabs?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        switch route {
        case .action(let action):
            XCTAssertEqual(action, .closePrivateTabs)
        default:
            XCTFail("The route should be an action route")
        }
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

        switch route {
        case .search(let url, let isPrivate, _):
            XCTAssertNil(url)
            XCTAssertFalse(isPrivate)
        default:
            XCTFail("The route should be a search route")
        }
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

        switch route {
        case .searchQuery(let query, let isPrivate):
            XCTAssertEqual(query, "google")
            XCTAssertFalse(isPrivate)
        default:
            XCTFail("The route should be a search route")
        }
    }

    func test_makeRoute_forOpenText_withJS_doesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-text?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testShareSheetRouteUrlOnly() {
        let testURL = URL(string: "https://www.google.com")!
        let shareURL = URL(string: "firefox://share-sheet?url=\(testURL.absoluteString)")!
        let subject = createSubject()

        let route = subject.makeRoute(url: shareURL)

        switch route {
        case .sharesheet(let shareType, let shareMessage):
            switch shareType {
            case .site(let url):
                XCTAssertEqual(url, testURL)
            default:
                XCTFail("The share type should be a site share type")
            }
            XCTAssertNil(shareMessage)
        default:
            XCTFail("The route should be a search route")
        }
    }

    func testShareSheetRouteUrlTitle() {
        let testURL = URL(string: "https://www.google.com")!
        let testTitle = "TEST TITLE"
        let shareURL: URL?

        // URL(string:) changed between iOS 17 and if the string includes a space
        // it returns nil. We updated to using URLComponents, since under the hood
        // URL(string:) was updated in iOS17+ to use same RFC 3986 parsing as URLComponents.
        if #available(iOS 17, *) {
            shareURL = URL(string: "firefox://share-sheet?url=\(testURL.absoluteString)&title=\(testTitle)")
        } else {
            var components = URLComponents()
            components.scheme = "firefox"
            components.host = "share-sheet"
            components.queryItems = [
                URLQueryItem(name: "url", value: testURL.absoluteString),
                URLQueryItem(name: "title", value: testTitle)
            ]
            shareURL = components.url
        }

        let subject = createSubject()

        let route = subject.makeRoute(url: shareURL!)

        let expectedShareMessage = ShareMessage(message: testTitle, subtitle: nil)

        switch route {
        case .sharesheet(let shareType, let shareMessage):
            switch shareType {
            case .site(let url):
                XCTAssertEqual(url, testURL)
            default:
                XCTFail("The share type should be a site share type")
            }
            XCTAssertEqual(shareMessage, expectedShareMessage)
        default:
            XCTFail("The route should be a search route")
        }
    }

    func testShareSheetRouteUrlTitleAndSubtitle() {
        let testURL = URL(string: "https://www.google.com")!
        let testTitle = "TEST TITLE"
        let testSubtitle = "TEST SUBTITLE"
        let shareURL: URL?

        // URL(string:) changed between iOS 17 and if the string includes a space
        // it returns nil. We updated to using URLComponents, since under the hood
        // URL(string:) was updated in iOS17+ to use same RFC 3986 parsing as URLComponents.
        if #available(iOS 17, *) {
            shareURL = URL(string: "firefox://share-sheet?url=\(testURL.absoluteString)&title=\(testTitle)&subtitle=\(testSubtitle)")
        } else {
            var components = URLComponents()
            components.scheme = "firefox"
            components.host = "share-sheet"
            components.queryItems = [
                URLQueryItem(name: "url", value: testURL.absoluteString),
                URLQueryItem(name: "title", value: testTitle),
                URLQueryItem(name: "subtitle", value: testSubtitle)
            ]
            shareURL = components.url
        }

        let subject = createSubject()

        let route = subject.makeRoute(url: shareURL!)

        let expectedShareMessage = ShareMessage(message: testTitle, subtitle: testSubtitle)

        switch route {
        case .sharesheet(let shareType, let shareMessage):
            switch shareType {
            case .site(let url):
                XCTAssertEqual(url, testURL)
            default:
                XCTFail("The share type should be a site share type")
            }
            XCTAssertEqual(shareMessage, expectedShareMessage)
        default:
            XCTFail("The route should be a search route")
        }
    }

    func test_makeRoute_forShareSheet_withJS_doesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://share-sheet?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    // MARK: - AppAction

    func testAppAction_showIntroOnboarding() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/action/show-intro-onboarding")!

        let route = subject.makeRoute(url: url)
        switch route {
        case .action(let action):
            XCTAssertEqual(action, .showIntroOnboarding)
        default:
            XCTFail("The route should be a search route")
        }
    }

    // MARK: - Helper

    func createSubject() -> RouteBuilder {
        let subject = RouteBuilder()
        subject.configure(isPrivate: false, prefs: MockProfile().prefs)
        trackForMemoryLeaks(subject)
        return subject
    }
}
