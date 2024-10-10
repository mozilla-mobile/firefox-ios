// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import WebKit
import UIKit
import GCDWebServers
@testable import Client

class ClearPrivateDataTests: KIFTestCase, UITextFieldDelegate {

    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    override func tearDown() {
        BrowserUtils.resetToAboutHomeKIF(tester())
        super.tearDown()
    }

    func visitSites(noOfSites: Int) -> [(title: String, domain: String, dispDomain: String, url: String)] {
        var urls: [(title: String, domain: String, dispDomain: String, url: String)] = []
        for pageNo in 1...noOfSites {
            let url = "\(webRoot!)/numberedPage.html?page=\(pageNo)"
            BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)

            tester().waitForAnimationsToFinish()
            tester().waitForWebViewElementWithAccessibilityLabel("Page \(pageNo)")
            let dom = URL(string: url)!.normalizedHost!
            let index = dom.index(dom.startIndex, offsetBy: 7)
            let dispDom = dom.substring(to: index)  // On IPhone, it only displays first 8 chars
            let tuple: (title: String, domain: String, dispDomain: String, url: String)
            = ("Page \(pageNo)", dom, dispDom, url)
            urls.append(tuple)
        }
        BrowserUtils.resetToAboutHomeKIF(tester())
        return urls
    }

    func testRemembersToggles() {
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        BrowserUtils.openClearPrivateDataDialogKIF(tester())
        BrowserUtils.clearPrivateData([BrowserUtils.Clearable.History], tester())
        BrowserUtils.acceptClearPrivateData(tester())
        BrowserUtils.closeClearPrivateDataDialog(tester())

        BrowserUtils.openClearPrivateDataDialogKIF(tester())

        // Ensure the toggles match our settings.
        [
            (BrowserUtils.Clearable.Cache, "0"),
            (BrowserUtils.Clearable.Cookies, "0"),
            (BrowserUtils.Clearable.OfflineData, "0"),
            (BrowserUtils.Clearable.History, "1")
        ].forEach { clearable, switchValue in
            XCTAssertNotNil(tester()
                .waitForView(withAccessibilityLabel: clearable.rawValue, value: switchValue, traits: UIAccessibilityTraits.none))
        }
        BrowserUtils.closeClearPrivateDataDialog(tester())
    }

    func testClearsHistoryPanel() {
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        let urls = visitSites(noOfSites: 2)

        let url1 = urls[0].url
        let url2 = urls[1].url
        tester().wait(forTimeInterval: 5)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().wait(forTimeInterval: 10)
        BrowserUtils.openLibraryMenu(tester())
        // Open History Panel
        tester().tapView(withAccessibilityIdentifier: StandardImageIdentifiers.Large.history)
        tester().waitForView(withAccessibilityLabel: url1)
        tester().waitForView(withAccessibilityLabel: url2)

        BrowserUtils.closeLibraryMenu(tester())
        BrowserUtils.openClearPrivateDataDialogKIF(tester())
        BrowserUtils.clearPrivateData([BrowserUtils.Clearable.History], tester())
        BrowserUtils.acceptClearPrivateData(tester())
        BrowserUtils.closeClearPrivateDataDialog(tester())

        BrowserUtils.openLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: StandardImageIdentifiers.Large.history)

        // Open History Panel
        tester().waitForAbsenceOfView(withAccessibilityLabel: url1)
        tester().waitForAbsenceOfView(withAccessibilityLabel: url2)

        BrowserUtils.closeLibraryMenu(tester())
    }

    func testDisabledHistoryDoesNotClearHistoryPanel() {
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        let urls = visitSites(noOfSites: 2)
        var errorOrNil: NSError?

        let url1 = urls[0].url
        let url2 = urls[1].url
        tester().wait(forTimeInterval: 5)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().wait(forTimeInterval: 5)
        BrowserUtils.openClearPrivateDataDialogKIF(tester())
        BrowserUtils.clearPrivateData(BrowserUtils.AllClearables.subtracting([BrowserUtils.Clearable.History]), tester())
        BrowserUtils.acceptClearPrivateData(tester())
        BrowserUtils.closeClearPrivateDataDialog(tester())
        tester().waitForAnimationsToFinish()
        BrowserUtils.openLibraryMenu(tester())
        // Open History Panel
        tester().tapView(withAccessibilityIdentifier: StandardImageIdentifiers.Large.history)
        tester().waitForAnimationsToFinish()

        tester().waitForView(withAccessibilityLabel: url1)
        tester().waitForView(withAccessibilityLabel: url2)

        // Close History (and so Library) panel
        BrowserUtils.closeLibraryMenu(tester())
    }
    // Disabled due to https://github.com/mozilla-mobile/firefox-ios/issues/7727
    /*func testClearsCookies() {
        let url = "\(webRoot!)/numberedPage.html?page=1"
        tester().waitForAnimationsToFinish(withTimeout: 5)

        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView

        // Set and verify a dummy cookie value.
        setCookies(webView, cookie: "foo=bar")
        var cookies = getCookies(webView)
        XCTAssertEqual(cookies.cookie, "foo=bar")
        XCTAssertEqual(cookies.localStorage, "foo=bar")
        XCTAssertEqual(cookies.sessionStorage, "foo=bar")

        // Verify that cookies are not cleared when Cookies is deselected.
        BrowserUtils.openClearPrivateDataDialogKIF(tester())
        BrowserUtils.clearPrivateData(BrowserUtils.AllClearables.subtracting([BrowserUtils.Clearable.Cookies]), tester())
        BrowserUtils.acceptClearPrivateData(tester())
        BrowserUtils.closeClearPrivateDataDialog(tester())

        tester().waitForAnimationsToFinish(withTimeout: 5)
        cookies = getCookies(webView)
        XCTAssertEqual(cookies.cookie, "foo=bar")
        XCTAssertEqual(cookies.localStorage, "foo=bar")
        XCTAssertEqual(cookies.sessionStorage, "foo=bar")

        // Verify that cookies are cleared when Cookies is selected.
        BrowserUtils.openClearPrivateDataDialogKIF(tester())
        BrowserUtils.clearPrivateData([BrowserUtils.Clearable.Cookies], tester())
        BrowserUtils.acceptClearPrivateData(tester())
        BrowserUtils.closeClearPrivateDataDialog(tester())

        tester().waitForAnimationsToFinish(withTimeout: 5)
        cookies = getCookies(webView)
        XCTAssertEqual(cookies.cookie, "")
        XCTAssertEqual(cookies.localStorage, "null")
        XCTAssertEqual(cookies.sessionStorage, "null")
    }*/

    func testClearsCache() {
        let cachedServer = CachedPageServer()
        let cacheRoot = cachedServer.start()
        let url = "\(cacheRoot)/cachedPage.html"
        tester().wait(forTimeInterval: 3)
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
        tester().waitForWebViewElementWithAccessibilityLabel("Cache test")

        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        let requests = cachedServer.requests

        // Verify that clearing non-cache items will keep the page in the cache.
        BrowserUtils.openClearPrivateDataDialogKIF(tester())
        BrowserUtils.clearPrivateData(BrowserUtils.AllClearables.subtracting([BrowserUtils.Clearable.Cache]), tester())
        BrowserUtils.acceptClearPrivateData(tester())
        BrowserUtils.closeClearPrivateDataDialog(tester())
        webView.reload()
        XCTAssertEqual(cachedServer.requests, requests)

        // Verify that clearing the cache will fire a new request.
        BrowserUtils.openClearPrivateDataDialogKIF(tester())
        BrowserUtils.clearPrivateData([BrowserUtils.Clearable.Cache], tester())
        BrowserUtils.acceptClearPrivateData(tester())
        BrowserUtils.closeClearPrivateDataDialog(tester())
        webView.reload()
        XCTAssertEqual(cachedServer.requests, requests + 1)
    }

    fileprivate func setCookies(_ webView: WKWebView, cookie: String) {
        let expectation = self.expectation(description: "Set cookie")
        webView.evaluateJavascriptInDefaultContentWorld("document.cookie = \"\(cookie)\"; localStorage.cookie = \"\(cookie)\"; sessionStorage.cookie = \"\(cookie)\";") { result, _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    fileprivate func getCookies(_ webView: WKWebView) -> (cookie: String, localStorage: String?, sessionStorage: String?) {
        var cookie: (String, String?, String?)!
        var value: String!
        let expectation = self.expectation(description: "Got cookie")

        webView.evaluateJavascriptInDefaultContentWorld("JSON.stringify([document.cookie, localStorage.cookie, sessionStorage.cookie])") { result, _ in
            value = result as! String
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
        value = value.replacingOccurrences(of: "[", with: "")
        value = value.replacingOccurrences(of: "]", with: "")
        value = value.replacingOccurrences(of: "\"", with: "")
        let items = value.components(separatedBy: ",")
        cookie = (items[0], items[1], items[2])
        return cookie
    }

    func testClearsTrackingProtectionSafelist() {
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        let wait = expectation(description: "wait for file write")
        ContentBlocker.shared.safelist(enable: true, url: URL(string: "http://www.mozilla.com")!) {
            wait.fulfill()
        }
        waitForExpectations(timeout: 5)
        BrowserUtils.openClearPrivateDataDialogKIF(tester())
        BrowserUtils.clearPrivateData([BrowserUtils.Clearable.TrackingProtection], tester())
        BrowserUtils.acceptClearPrivateData(tester())
        BrowserUtils.closeClearPrivateDataDialog(tester())

        let data = ContentBlocker.shared.readSafelistFile()
        XCTAssert(data == nil || data!.isEmpty)
    }

}

/// Server that keeps track of requests.
private class CachedPageServer {
    var requests = 0

    func start() -> String {
        let webServer = GCDWebServer()
        webServer.addHandler(forMethod: "GET", path: "/cachedPage.html", request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse? in
            self.requests += 1
            return GCDWebServerDataResponse(html: "<html><head><title>Cached page</title></head><body>Cache test</body></html>")
        }

        webServer.start(withPort: 0, bonjourName: nil)

        // We use 127.0.0.1 explicitly here, rather than localhost, in order to avoid our
        // history exclusion code (Bug 1188626).
        let port = (webServer.port)
        let webRoot = "http://127.0.0.1:\(port)"
        return webRoot
    }
}
