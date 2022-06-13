// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import WebKit
import XCTest

class WebviewNavigationHandlerTests: XCTestCase {

    // MARK: - Data scheme

    func testDoesntFilterSubframes() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows subframes")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: false)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "www.testurl.com")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterNullFrame() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .cancel, "Doesnt allow null target frame")
        }

        let policy = WKNavigationActionMock()
        WebviewNavigationHandler.filterDataScheme(url: URL(string: "www.testurl.com")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_hasNoDataURL() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .cancel, "Cancel no data URL on main frame")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "www.testurl.com")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_cancelGenericDataURL() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .cancel, "Cancel generic data URL")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_allowsImage() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows image")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:image/")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_cancelImageSVG() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .cancel, "Cancel SVG + XML images")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:image/svg+xml")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_allowsOtherImages() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows jpg images")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:image/jpg")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_allowsVideo() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows video")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:video/")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_allowsApplicationPDF() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows application PDF")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:application/pdf")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_allowsApplicationJSON() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows application JSON")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:application/json")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_allowsBase64() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows base 64")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:;base64,")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_allowsDataComma() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows data comma")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:,")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_allowsTextPlainComma() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows text plain comma")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:text/plain,")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }

    func testFilterMainFrame_allowsTextPlainSemicolon() {
        let handler: (WKNavigationActionPolicy) -> Void = { policy in
            XCTAssertEqual(policy, .allow, "Allows text plain semicolon")
        }

        let policy = WKNavigationActionMock()
        policy.overridenTargetFrame = WKFrameInfoMock(isMainFrame: true)

        WebviewNavigationHandler.filterDataScheme(url: URL(string: "data:text/plain;")!,
                                                  decidePolicyFor: policy,
                                                  decisionHandler: handler)
    }
}

// MARK: WKNavigationActionMock
class WKNavigationActionMock: WKNavigationAction {

    var overridenTargetFrame: WKFrameInfoMock?

    override var targetFrame: WKFrameInfo? {
        return overridenTargetFrame
    }
}

// MARK: WKFrameInfoMock
class WKFrameInfoMock: WKFrameInfo {

    let overridenTargetFrame: Bool

    init(isMainFrame: Bool) {
        overridenTargetFrame = isMainFrame
    }

    override var isMainFrame: Bool {
        return overridenTargetFrame
    }
}
