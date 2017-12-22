/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client
import WebKit

import XCTest

class TabEventHandlerTests: XCTestCase {

    func testEventDelivery() {
        let tab = Tab(configuration: WKWebViewConfiguration())
        let handler = DummyHandler()

        XCTAssertNil(handler.isFocused)

        TabEvent.post(.didGainFocus, for: tab)
        XCTAssertTrue(handler.isFocused!)

        TabEvent.post(.didLoseFocus, for: tab)
        XCTAssertFalse(handler.isFocused!)
    }

    func testUnregistration() {
        let tab = Tab(configuration: WKWebViewConfiguration())
        let handler = DummyHandler()

        XCTAssertNil(handler.isFocused)

        TabEvent.post(.didGainFocus, for: tab)
        XCTAssertTrue(handler.isFocused!)

        handler.doUnregister()
        TabEvent.post(.didLoseFocus, for: tab)
        // The event didn't reach us, so we should still be focused.
        XCTAssertTrue(handler.isFocused!)
    }

    func testOnlyRegisteredForEvents() {
        let tab = Tab(configuration: WKWebViewConfiguration())
        let handler = DummyHandler()
        handler.doUnregister()

        let tabObservers = handler.registerFor(.didGainFocus)

        XCTAssertNil(handler.isFocused)

        TabEvent.post(.didGainFocus, for: tab)
        XCTAssertTrue(handler.isFocused!)

        TabEvent.post(.didLoseFocus, for: tab)
        XCTAssertTrue(handler.isFocused!)

        handler.unregister(tabObservers)
    }
}


class DummyHandler: TabEventHandler {
    var tabObservers: TabObservers!

    // This is not how this should be written in production — the handler shouldn't be keeping track
    // of individual tab state.
    var isFocused: Bool? = nil

    init() {
        tabObservers = registerFor(.didGainFocus, .didLoseFocus)
    }

    deinit {
        doUnregister()
    }

    fileprivate func doUnregister() {
        unregister(tabObservers)
    }

    func tabDidGainFocus(_ tab: Tab) {
        isFocused = true
    }

    func tabDidLoseFocus(_ tab: Tab) {
        isFocused = false
    }
}
