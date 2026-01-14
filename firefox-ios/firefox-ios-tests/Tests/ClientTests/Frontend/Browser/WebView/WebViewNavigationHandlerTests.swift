// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import WebKit
import XCTest

class WebViewNavigationHandlerTests: XCTestCase {
    // MARK: - Data scheme

    func testShouldNotHandleNonDataSchemeURL() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTFail("Handler should not be called")
        }
        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)

        let shouldFilter = navigationHandler.shouldFilterDataScheme(url: URL(string: "www.testURL.com")!)
        XCTAssertFalse(shouldFilter, "Should not filter non data scheme URL")
    }

    func testShouldHandleDataSchemeURL() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTFail("Handler should not be called")
        }
        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)

        let shouldFilter = navigationHandler.shouldFilterDataScheme(url: URL(string: "data:text/html,")!)
        XCTAssertTrue(shouldFilter, "Should filter data scheme URL")
    }

    @MainActor
    func testAllowsSubframes() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows subframes")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:text/html,")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: false)
    }

    @MainActor
    func testFilterNullFrame() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .cancel, "Doesnt allow null target frame")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:text/html,")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: nil)
    }

    @MainActor
    func testFilterMainFrame_hasNoDataURL() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .cancel, "Cancel no data URL on main frame")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:text/html,")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_cancelGenericDataURL() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .cancel, "Cancel generic data URL")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_allowsImage() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows image")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:image/")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_cancelImageSVG() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .cancel, "Cancel SVG + XML images")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:image/svg+xml")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_cancelImageSVGCaplocks() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .cancel, "Cancel SVG + XML images")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:image/SVG+xml")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_allowsOtherImages() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows jpg images")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:image/jpg")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_allowsVideo() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows video")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:video/")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_allowsApplicationPDF() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows application PDF")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:application/pdf")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_allowsApplicationJSON() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows application JSON")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:application/json")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_allowsBase64() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows base 64")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:;base64,")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_allowsDataComma() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows data comma")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:,")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_allowsTextPlainComma() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows text plain comma")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:text/plain,")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }

    @MainActor
    func testFilterMainFrame_allowsTextPlainSemicolon() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows text plain semicolon")
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: handler)
        let url = URL(string: "data:text/plain;")!
        navigationHandler.filterDataScheme(url: url, isMainFrame: true)
    }
}
