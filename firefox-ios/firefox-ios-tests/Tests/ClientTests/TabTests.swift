// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client

class TabTests: XCTestCase {
    private var tabDelegate: MockLegacyTabDelegate!
    private var urlDidChangeDelegate: MockUrlDidChangeDelegate!

    override func setUp() {
        super.setUp()
        tabDelegate = MockLegacyTabDelegate()
        urlDidChangeDelegate = MockUrlDidChangeDelegate()
    }

    override func tearDown() {
        super.tearDown()
        tabDelegate = nil
        urlDidChangeDelegate = nil
    }

    func testWithoutMobilePrefixRemovesMobilePrefixes() {
        let url = URL(string: "https://m.wikipedia.org/wiki/Firefox")!
        let newUrl = url.withoutMobilePrefix()
        XCTAssertEqual(newUrl.host, "wikipedia.org")
    }

    func testWithoutMobilePrefixRemovesMobile() {
        let url = URL(string: "https://en.mobile.wikipedia.org/wiki/Firefox")!
        let newUrl = url.withoutMobilePrefix()
        XCTAssertEqual(newUrl.host, "en.wikipedia.org")
    }

    func testWithoutMobilePrefixOnlyRemovesMobileSubdomains() {
        var url = URL(string: "https://plum.com")!
        var newUrl = url.withoutMobilePrefix()
        XCTAssertEqual(newUrl.host, "plum.com")

        url = URL(string: "https://mobile.co.uk")!
        newUrl = url.withoutMobilePrefix()
        XCTAssertEqual(newUrl.host, "mobile.co.uk")
    }

    func testShareURL_RemovingReaderModeComponents() {
        let url = URL(string: "http://localhost:123/reader-mode/page?url=https://mozilla.org")!

        guard let newUrl = url.displayURL else {
            XCTFail("expected valid url without reader mode components")
            return
        }

        XCTAssertEqual(newUrl.host, "mozilla.org")
    }

    func testTabDoesntLeak() {
        let tab = Tab(profile: MockProfile(), configuration: WKWebViewConfiguration())
        tab.tabDelegate = tabDelegate
        tab.urlDidChangeDelegate = urlDidChangeDelegate
        trackForMemoryLeaks(tab)
    }
}

// MARK: - MockLegacyTabDelegate
class MockLegacyTabDelegate: LegacyTabDelegate {
    func tab(_ tab: Client.Tab, didAddSnackbar bar: Client.SnackBar) {}

    func tab(_ tab: Client.Tab, didRemoveSnackbar bar: Client.SnackBar) {}

    func tab(_ tab: Client.Tab, didSelectFindInPageForSelection selection: String) {}

    func tab(_ tab: Client.Tab, didSelectSearchWithFirefoxForSelection selection: String) {}

    func tab(_ tab: Client.Tab, didCreateWebView webView: WKWebView) {}

    func tab(_ tab: Client.Tab, willDeleteWebView webView: WKWebView) {}
}

// MARK: - MockUrlDidChangeDelegate
class MockUrlDidChangeDelegate: URLChangeDelegate {
    func tab(_ tab: Client.Tab, urlDidChangeTo url: URL) {}
}
