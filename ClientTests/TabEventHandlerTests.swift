/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client
import WebKit
import GCDWebServers
import XCTest
import Shared

class TabEventHandlerTests: XCTestCase {

    func testEventDelivery() {
        let tab = Tab(bvc: BrowserViewController.foregroundBVC(), configuration: WKWebViewConfiguration())
        let handler = DummyHandler()

        XCTAssertNil(handler.isFocused)

        TabEvent.post(.didGainFocus, for: tab)
        XCTAssertTrue(handler.isFocused!)

        TabEvent.post(.didLoseFocus, for: tab)
        XCTAssertFalse(handler.isFocused!)
    }


    func testBlankPopupURL() {
        let webServer = GCDWebServer()
        webServer.addHandler(forMethod: "GET", path: "/blankpopup", request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse in
            let page = """
                <html>
                <body onload="window.open('')">open about:blank popup</body>
                </html>
            """
            return GCDWebServerDataResponse(html: page)!
        }

        if webServer.start(withPort: 0, bonjourName: nil) == false {
            XCTFail("Can't start the GCDWebServer")
        }
        let webServerBase = "http://localhost:\(webServer.port)"

        BrowserViewController.foregroundBVC().profile.prefs.setBool(false, forKey: PrefsKeys.KeyBlockPopups)
        BrowserViewController.foregroundBVC().tabManager.addTab(URLRequest(url: URL(string: "\(webServerBase)/blankpopup")!))
        let expectation = self.expectation(description: "Waiting on about:blank window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            BrowserViewController.foregroundBVC().tabManager.tabs.forEach { tab in
                if tab.url?.absoluteString == "about:blank" {
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 20, handler: nil)
    }
}


class DummyHandler: TabEventHandler {
    // This is not how this should be written in production — the handler shouldn't be keeping track
    // of individual tab state.
    var isFocused: Bool? = nil

    init() {
         register(self, forTabEvents: .didGainFocus, .didLoseFocus)
    }

    func tabDidGainFocus(_ tab: Tab) {
        isFocused = true
    }

    func tabDidLoseFocus(_ tab: Tab) {
        isFocused = false
    }
}
