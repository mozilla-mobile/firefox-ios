// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import WebKit
import GCDWebServers
import XCTest
import Shared
import Common

class TabEventHandlerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    func testEventDelivery() {
        let tab = Tab(profile: MockProfile(),
                      windowUUID: windowUUID)
        let handler = DummyHandler()

        XCTAssertNil(handler.isFocused)

        TabEvent.post(.didGainFocus, for: tab)
        XCTAssertTrue(handler.isFocused!)

        TabEvent.post(.didLoseFocus, for: tab)
        XCTAssertFalse(handler.isFocused!)
    }

    func testBlankPopupURL() throws {
        throw XCTSkip("Test doesn't complete anymore, was probably relying on behavior from setup in App delegate")
//        let profile = MockProfile()
//        let manager = TabManager(profile: profile)
//
//        // Hide intro so it is easier to see the test running and debug it
//        IntroScreenManager(prefs: profile.prefs).didSeeIntroScreen()
//
//        let webServer = GCDWebServer()
//        webServer.addHandler(
//            forMethod: "GET",
//            path: "/blankpopup",
//            request: GCDWebServerRequest.self
//        ) { (request) -> GCDWebServerResponse in
//            let page = """
//                <html>
//                <body onload="window.open('')">open about:blank popup</body>
//                </html>
//            """
//            return GCDWebServerDataResponse(html: page)!
//        }
//
//        if !webServer.start(withPort: 0, bonjourName: nil) {
//            XCTFail("Can't start the GCDWebServer")
//        }
//        let webServerBase = "http://localhost:\(webServer.port)"
//
//        profile.prefs.setBool(false, forKey: PrefsKeys.KeyBlockPopups)
//        manager.addTab(URLRequest(url: URL(string: "\(webServerBase)/blankpopup")!))
//
//        // Wait for tab count to increase by one with the popup open
//        let actualTabCount = manager.tabs.count
//        let exists = NSPredicate { obj, _ in
//            let tabManager = obj as! TabManager
//            return tabManager.tabs.count > actualTabCount
//        }
//
//        expectation(for: exists, evaluatedWith: manager) {
//            guard let lastTabUrl = manager.tabs.last?.url?.absoluteString else {
//                XCTFail("Should have the last tab url")
//                return true
//            }
//
//            XCTAssertEqual(lastTabUrl, "about:blank", "URLs should contain \"about:blank:\" \(lastTabUrl)")
//            return true
//        }
//
//        waitForExpectations(timeout: 20, handler: nil)
    }
}

class DummyHandler: TabEventHandler {
    // This is not how this should be written in production — the handler shouldn't be keeping track
    // of individual tab state.
    var isFocused: Bool?

    let tabEventWindowResponseType: TabEventHandlerWindowResponseType = .singleWindow(.XCTestDefaultUUID)

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
