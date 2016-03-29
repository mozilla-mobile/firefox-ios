/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit
import UIKit
import GCDWebServers

// Needs to be in sync with Client Clearables.
private enum Clearable: String {
    case History = "Browsing History"
    case Cache = "Cache"
    case OfflineData = "Offline Website Data"
    case Cookies = "Cookies"
}

private let AllClearables = Set([Clearable.History, Clearable.Cache, Clearable.OfflineData, Clearable.Cookies])

class ClearPrivateDataTests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    override func tearDown() {
        BrowserUtils.clearHistoryItems(tester())
    }

    private func openClearPrivateDataDialog() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Clear Private Data")
    }

    private func closeClearPrivateDataDialog(lastTabLabel lastTabLabel: String) {
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel(lastTabLabel)
    }

    private func acceptClearPrivateData() {
        tester().waitForViewWithAccessibilityLabel("Clear")
        tester().tapViewWithAccessibilityLabel("Clear")
        tester().waitForViewWithAccessibilityLabel("Clear Private Data")
    }

    private func cancelClearPrivateData() {
        tester().waitForViewWithAccessibilityLabel("Clear")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Clear Private Data")
    }

    private func clearPrivateData(clearables: Set<Clearable>) {
        let webView = tester().waitForViewWithAccessibilityLabel("Web content") as! WKWebView
        let lastTabLabel = webView.title!.isEmpty ? "home" : webView.title!

        openClearPrivateDataDialog()

        // Disable all items that we don't want to clear.
        for clearable in AllClearables {
            // If we don't wait here, setOn:forSwitchWithAccessibilityLabel tries to use the UITableViewCell
            // instead of the UISwitch. KIF bug?
            tester().waitForViewWithAccessibilityLabel(clearable.rawValue)

            tester().setOn(clearables.contains(clearable), forSwitchWithAccessibilityLabel: clearable.rawValue)
        }

        tester().tapViewWithAccessibilityLabel("Clear Private Data", traits: UIAccessibilityTraitButton)
        acceptClearPrivateData()

        closeClearPrivateDataDialog(lastTabLabel: lastTabLabel)
    }

    func visitSites(noOfSites noOfSites: Int) -> [(title: String, domain: String, url: String)] {
        var urls: [(title: String, domain: String, url: String)] = []
        for pageNo in 1...noOfSites {
            tester().tapViewWithAccessibilityIdentifier("url")
            let url = "\(webRoot)/numberedPage.html?page=\(pageNo)"
            tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
            tester().waitForWebViewElementWithAccessibilityLabel("Page \(pageNo)")
            let tuple: (title: String, domain: String, url: String) = ("Page \(pageNo)", NSURL(string: url)!.normalizedHost()!, url)
            urls.append(tuple)
        }
        BrowserUtils.resetToAboutHome(tester())
        return urls
    }

    func anyDomainsExistOnTopSites(domains: Set<String>) {
        for domain in domains {
            if self.tester().viewExistsWithLabel(domain) {
                return
            }
        }
        XCTFail("Couldn't find any domains in top sites.")
    }

    func testRemembersToggles() {
        clearPrivateData([Clearable.History])

        openClearPrivateDataDialog()

        // Ensure the toggles match our settings.
        [
            (Clearable.Cache, "0"),
            (Clearable.Cookies, "0"),
            (Clearable.OfflineData, "0"),
            (Clearable.History, "1"),
        ].forEach { clearable, value in
            XCTAssertEqual(value, tester().waitForViewWithAccessibilityLabel(clearable.rawValue).accessibilityValue)
        }


        closeClearPrivateDataDialog(lastTabLabel: "home")
    }

    func testClearsTopSitesPanel() {
        let urls = visitSites(noOfSites: 2)
        let domains = Set<String>(urls.map { $0.domain })

        tester().tapViewWithAccessibilityLabel("Top sites")

        // Only one will be found -- we collapse by domain.
        anyDomainsExistOnTopSites(domains)

        clearPrivateData([Clearable.History])

        XCTAssertFalse(tester().viewExistsWithLabel(urls[0].title), "Expected to have removed top site panel \(urls[0])")
        XCTAssertFalse(tester().viewExistsWithLabel(urls[1].title), "We shouldn't find the other URL, either.")
    }

    func testDisabledHistoryDoesNotClearTopSitesPanel() {
        let urls = visitSites(noOfSites: 2)
        let domains = Set<String>(urls.map { $0.domain })

        anyDomainsExistOnTopSites(domains)
        clearPrivateData(AllClearables.subtract([Clearable.History]))
        anyDomainsExistOnTopSites(domains)
    }

    func testClearsHistoryPanel() {
        let urls = visitSites(noOfSites: 2)

        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)"
        let url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().viewExistsWithLabel(url1), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().viewExistsWithLabel(url2), "Expected to have history row \(url2)")

        clearPrivateData([Clearable.History])

        tester().tapViewWithAccessibilityLabel("History")
        XCTAssertFalse(tester().viewExistsWithLabel(url1), "Expected to have removed history row \(url1)")
        XCTAssertFalse(tester().viewExistsWithLabel(url2), "Expected to have removed history row \(url2)")
    }

    func testDisabledHistoryDoesNotClearHistoryPanel() {
        let urls = visitSites(noOfSites: 2)

        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)"
        let url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().viewExistsWithLabel(url1), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().viewExistsWithLabel(url2), "Expected to have history row \(url2)")

        clearPrivateData(AllClearables.subtract([Clearable.History]))

        XCTAssertTrue(tester().viewExistsWithLabel(url1), "Expected to not have removed history row \(url1)")
        XCTAssertTrue(tester().viewExistsWithLabel(url2), "Expected to not have removed history row \(url2)")
    }

    func testClearsCookies() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        let webView = tester().waitForViewWithAccessibilityLabel("Web content") as! WKWebView

        // Set and verify a dummy cookie value.
        setCookies(webView, cookie: "foo=bar")
        var cookies = getCookies(webView)
        XCTAssertEqual(cookies.cookie, "foo=bar")
        XCTAssertEqual(cookies.localStorage, "foo=bar")
        XCTAssertEqual(cookies.sessionStorage, "foo=bar")

        // Verify that cookies are not cleared when Cookies is deselected.
        clearPrivateData(AllClearables.subtract([Clearable.Cookies]))
        cookies = getCookies(webView)
        XCTAssertEqual(cookies.cookie, "foo=bar")
        XCTAssertEqual(cookies.localStorage, "foo=bar")
        XCTAssertEqual(cookies.sessionStorage, "foo=bar")

        // Verify that cookies are cleared when Cookies is selected.
        clearPrivateData([Clearable.Cookies])
        cookies = getCookies(webView)
        XCTAssertEqual(cookies.cookie, "")
        XCTAssertNil(cookies.localStorage)
        XCTAssertNil(cookies.sessionStorage)
    }

    @available(iOS 9.0, *)
    func testClearsCache() {
        let cachedServer = CachedPageServer()
        let cacheRoot = cachedServer.start()
        let url = "\(cacheRoot)/cachedPage.html"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Cache test")

        let webView = tester().waitForViewWithAccessibilityLabel("Web content") as! WKWebView
        let requests = cachedServer.requests

        // Verify that clearing non-cache items will keep the page in the cache.
        clearPrivateData(AllClearables.subtract([Clearable.Cache]))
        webView.reload()
        XCTAssertEqual(cachedServer.requests, requests)

        // Verify that clearing the cache will fire a new request.
        clearPrivateData([Clearable.Cache])
        webView.reload()
        XCTAssertEqual(cachedServer.requests, requests + 1)
    }

    private func setCookies(webView: WKWebView, cookie: String) {
        let expectation = expectationWithDescription("Set cookie")
        webView.evaluateJavaScript("document.cookie = \"\(cookie)\"; localStorage.cookie = \"\(cookie)\"; sessionStorage.cookie = \"\(cookie)\";") { result, _ in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    private func getCookies(webView: WKWebView) -> (cookie: String, localStorage: String?, sessionStorage: String?) {
        var cookie: (String, String?, String?)!
        let expectation = expectationWithDescription("Got cookie")
        webView.evaluateJavaScript("JSON.stringify([document.cookie, localStorage.cookie, sessionStorage.cookie])") { result, _ in
            let cookies = JSON.parse(result as! String).asArray!
            cookie = (cookies[0].asString!, cookies[1].asString, cookies[2].asString)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
        return cookie
    }
}

/// Server that keeps track of requests.
private class CachedPageServer {
    var requests = 0

    func start() -> String {
        let webServer = GCDWebServer()
        webServer.addHandlerForMethod("GET", path: "/cachedPage.html", requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            self.requests += 1
            return GCDWebServerDataResponse(HTML: "<html><head><title>Cached page</title></head><body>Cache test</body></html>")
        }

        webServer.startWithPort(0, bonjourName: nil)

        // We use 127.0.0.1 explicitly here, rather than localhost, in order to avoid our
        // history exclusion code (Bug 1188626).
        let webRoot = "http://127.0.0.1:\(webServer.port)"
        return webRoot
    }
}
