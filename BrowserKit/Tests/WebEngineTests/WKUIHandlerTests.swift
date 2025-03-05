// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import XCTest
@testable import WebEngine

final class WKUIHandlerTests: XCTestCase {
    func testRequestMediaCaptureSuccess() {
        let delegate = MockEngineSessionDelegate()
        let subject = createSubject(delegate: delegate, isActive: true)

        let expectation = expectation(description: "Wait for the decision handler to be called")

        let decisionHandler = { (decision: WKPermissionDecision) in
            XCTAssertEqual(decision, .prompt)
            expectation.fulfill()
        }
        subject.webView(MockWKWebView(),
                        requestMediaCapturePermissionFor: MockWKSecurityOrigin.new(nil),
                        initiatedByFrame: MockWKFrameInfo(),
                        type: .cameraAndMicrophone,
                        decisionHandler: decisionHandler
        )
        wait(for: [expectation])
    }

    func testRequestMediaCaptureIsActiveFalse() {
        let subject = createSubject(delegate: MockEngineSessionDelegate(), isActive: false)
        let expectation = expectation(description: "Wait for the decision handler to be called")

        let decisionHandler = { (decision: WKPermissionDecision) in
            XCTAssertEqual(decision, .deny)
            expectation.fulfill()
        }
        subject.webView(MockWKWebView(),
                        requestMediaCapturePermissionFor: MockWKSecurityOrigin.new(nil),
                        initiatedByFrame: MockWKFrameInfo(),
                        type: .cameraAndMicrophone,
                        decisionHandler: decisionHandler
        )
        wait(for: [expectation])
    }

    func testRequestMediaCaptureDelegateReturnsFalse() {
        let delegate = MockEngineSessionDelegate()
        delegate.hasMediaCapturePermission = false
        let subject = createSubject(delegate: delegate, isActive: true)
        let expectation = expectation(description: "Wait for the decision handler to be called")

        let decisionHandler = { (decision: WKPermissionDecision) in
            XCTAssertEqual(decision, .deny)
            expectation.fulfill()
        }
        subject.webView(MockWKWebView(),
                        requestMediaCapturePermissionFor: MockWKSecurityOrigin.new(nil),
                        initiatedByFrame: MockWKFrameInfo(),
                        type: .cameraAndMicrophone,
                        decisionHandler: decisionHandler
        )
        wait(for: [expectation])
    }

    func createSubject(delegate: EngineSessionDelegate, isActive: Bool = false) -> WKUIHandler {
        let uiHandler = DefaultUIHandler()
        uiHandler.delegate = delegate
        uiHandler.isActive = isActive
        return uiHandler
    }
}
