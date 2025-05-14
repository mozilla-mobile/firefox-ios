// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import XCTest
import Common
@testable import WebEngine

final class WKUIHandlerTests: XCTestCase {
    private var sessionDelegate: MockEngineSessionDelegate!
    private var mockDecider: MockPolicyDecider!
    private var mockApplication: MockApplication!
    private let testURL = URL(string: "https://www.example.com")!

    override func setUp() {
        super.setUp()
        mockApplication = MockApplication()
        mockDecider = MockPolicyDecider()
        sessionDelegate = MockEngineSessionDelegate()
    }

    override func tearDown() {
        mockApplication = nil
        mockDecider = nil
        sessionDelegate = nil
        super.tearDown()
    }

    func testRequestMediaCaptureSuccess() {
        let subject = createSubject(isActive: true)

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
        let subject = createSubject(isActive: false)
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
        sessionDelegate.hasMediaCapturePermission = false
        let subject = createSubject(isActive: true)
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

    // MARK: - createWebViewWith

    func testRequestPopupWindow_whenPolicyIsAllow_returnsWebView() {
        let subject = createSubject()

        let webView = subject.webView(
            MockWKWebView(),
            createWebViewWith: WKWebViewConfiguration(),
            for: MockWKNavigationAction(url: testURL),
            windowFeatures: .init()
        )

        XCTAssertNotNil(webView)
        XCTAssertEqual(sessionDelegate.onRequestOpenNewSessionCalled, 1)
    }

    func testRequestPopupWindow_whenPolicyIsCancel_returnsNil() {
        let subject = createSubject()
        mockDecider.policyToReturn = .cancel

        let webView = subject.webView(
            MockWKWebView(),
            createWebViewWith: WKWebViewConfiguration(),
            for: MockWKNavigationAction(url: testURL),
            windowFeatures: .init()
        )

        XCTAssertNil(webView)
        XCTAssertEqual(sessionDelegate.onRequestOpenNewSessionCalled, 0)
    }

    func testRequestPopupWindow_whenPolicyIsLaunchExternalApps_returnsNil() {
        let subject = createSubject()
        mockDecider.policyToReturn = .launchExternalApp

        let webView = subject.webView(
            MockWKWebView(),
            createWebViewWith: WKWebViewConfiguration(),
            for: MockWKNavigationAction(url: testURL),
            windowFeatures: .init()
        )

        XCTAssertNil(webView)
        XCTAssertEqual(sessionDelegate.onRequestOpenNewSessionCalled, 0)
    }

    func testRequestPopupWindow_whenPolicyIsLaunchExternalApps_launchExternalApp() {
        let subject = createSubject()
        mockDecider.policyToReturn = .launchExternalApp

        let webView = subject.webView(
            MockWKWebView(),
            createWebViewWith: WKWebViewConfiguration(),
            for: MockWKNavigationAction(url: testURL),
            windowFeatures: .init()
        )

        XCTAssertNil(webView)
        XCTAssertEqual(sessionDelegate.onRequestOpenNewSessionCalled, 0)
        XCTAssertEqual(mockApplication.canOpenCalled, 1)
        XCTAssertEqual(mockApplication.openCalled, 1)
    }

    func testRequestPopupWindow_whenPolicyIsLaunchExternalApps_doesntLaunchUnsupportedApp() {
        let subject = createSubject()
        mockDecider.policyToReturn = .launchExternalApp
        mockApplication.canOpenURL = false

        let webView = subject.webView(
            MockWKWebView(),
            createWebViewWith: WKWebViewConfiguration(),
            for: MockWKNavigationAction(url: testURL),
            windowFeatures: .init()
        )

        XCTAssertNil(webView)
        XCTAssertEqual(sessionDelegate.onRequestOpenNewSessionCalled, 0)
        XCTAssertEqual(mockApplication.canOpenCalled, 1)
        XCTAssertEqual(mockApplication.openCalled, 0)
    }

    func createSubject(isActive: Bool = false) -> WKUIHandler {
        let uiHandler = DefaultUIHandler(
            sessionDependencies: DefaultTestDependencies().sessionDependencies,
            application: mockApplication,
            policyDecider: mockDecider
        )
        uiHandler.delegate = sessionDelegate
        uiHandler.isActive = isActive
        return uiHandler
    }
}
