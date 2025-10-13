// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import XCTest
import Common
@testable import WebEngine

@MainActor
final class WKUIHandlerTests: XCTestCase {
    private var sessionDelegate: MockEngineSessionDelegate!
    private var mockDecider: MockPolicyDecider!
    private var mockApplication: MockApplication!
    private let testURL = URL(string: "https://www.example.com")!
    private var sessionCreator: MockSessionCreator!
    private var modalPresenter: MockModalPresenter!
    private var alertFactory: MockWKJavaScriptAlertFactory!

    override func setUp() {
        super.setUp()
        sessionCreator = MockSessionCreator()
        mockApplication = MockApplication()
        mockDecider = MockPolicyDecider()
        sessionDelegate = MockEngineSessionDelegate()
        modalPresenter = MockModalPresenter()
        alertFactory = MockWKJavaScriptAlertFactory()
    }

    override func tearDown() {
        sessionCreator = nil
        mockApplication = nil
        mockDecider = nil
        sessionDelegate = nil
        modalPresenter = nil
        alertFactory = nil
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
        XCTAssertEqual(sessionCreator.createPopupSessionCalled, 1)
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
        XCTAssertEqual(sessionCreator.createPopupSessionCalled, 0)
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
        XCTAssertEqual(sessionCreator.createPopupSessionCalled, 0)
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
        XCTAssertEqual(sessionCreator.createPopupSessionCalled, 0)
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
        XCTAssertEqual(sessionCreator.createPopupSessionCalled, 0)
        XCTAssertEqual(mockApplication.canOpenCalled, 1)
        XCTAssertEqual(mockApplication.openCalled, 0)
    }

    // MARK: - JS Alerts tests

    func test_runJavaScriptAlertPanel_whenAlertIsThrottled() {
        let subject = createSubject()
        let throttler = MockPopupThrottler()
        let store = MockWKJavaScriptAlertStore(popupThrottler: throttler)
        throttler.stubCanShowAlert = false
        sessionCreator.stubStore = store

        subject.webView(MockWKWebView(), runJavaScriptAlertPanelWithMessage: "", initiatedByFrame: MockWKFrameInfo()) {}

        XCTAssertEqual(throttler.canShowAlertCalled, 1)
        XCTAssertEqual(throttler.willShowAlertCalled, 0)
    }

    func test_runJavaScriptAlertPanel_whenAlertIsNotThrottled() {
        let subject = createSubject()
        let throttler = MockPopupThrottler()
        let store = MockWKJavaScriptAlertStore(popupThrottler: throttler)

        sessionCreator.stubStore = store

        subject.webView(MockWKWebView(), runJavaScriptAlertPanelWithMessage: "", initiatedByFrame: MockWKFrameInfo()) {}

        XCTAssertEqual(throttler.canShowAlertCalled, 1)
        XCTAssertEqual(throttler.willShowAlertCalled, 1)
    }

    func test_runJavaScriptAlertPanel_whenSessionActive_andCanPresentAlert() {
        let subject = createSubject()

        subject.webView(MockWKWebView(), runJavaScriptAlertPanelWithMessage: "", initiatedByFrame: MockWKFrameInfo()) {}

        XCTAssertEqual(sessionCreator.isSessionActiveCalled, 2)
        XCTAssertEqual(alertFactory.makeMessageAlertCalled, 1)
        XCTAssertEqual(alertFactory.stubAlert.alertControllerCalled, 1)
        XCTAssertEqual(modalPresenter.canPresentCalled, 1)
        XCTAssertEqual(modalPresenter.presentCalled, 1)
    }

    func test_runJavaScriptAlertPanel_whenAlertIsStored() {
        let subject = createSubject()
        let store = MockWKJavaScriptAlertStore(popupThrottler: MockPopupThrottler())
        sessionCreator.stubStore = store
        modalPresenter.stubCanPresent = false

        subject.webView(MockWKWebView(), runJavaScriptAlertPanelWithMessage: "", initiatedByFrame: MockWKFrameInfo()) {}

        XCTAssertEqual(sessionCreator.isSessionActiveCalled, 2)
        XCTAssertEqual(alertFactory.makeMessageAlertCalled, 1)
        XCTAssertEqual(sessionCreator.alertStoreCalled, 2)
        XCTAssertEqual(store.queueJavascriptAlertPromptCalled, 1)
    }

    func test_runJavaScriptConfirmPanel_makeConfirmAlert() {
        let subject = createSubject()

        subject.webView(
            MockWKWebView(),
            runJavaScriptConfirmPanelWithMessage: "",
            initiatedByFrame: MockWKFrameInfo()
        ) { _ in }

        XCTAssertEqual(alertFactory.makeConfirmationAlertCalled, 1)
    }

    func test_runJavaScriptTextInputPanel_makeConfirmAlert() {
        let subject = createSubject()

        subject.webView(
            MockWKWebView(),
            runJavaScriptTextInputPanelWithPrompt: "",
            defaultText: "",
            initiatedByFrame: MockWKFrameInfo()
        ) { _ in }

        XCTAssertEqual(alertFactory.makeTextInputAlertCalled, 1)
    }

    func createSubject(isActive: Bool = false) -> WKUIHandler {
        let uiHandler = DefaultUIHandler(
            sessionDependencies: DefaultTestDependencies().sessionDependencies,
            sessionCreator: sessionCreator,
            alertFactory: alertFactory,
            modalPresenter: modalPresenter,
            application: mockApplication,
            policyDecider: mockDecider
        )
        uiHandler.delegate = sessionDelegate
        uiHandler.isActive = isActive
        trackForMemoryLeaks(uiHandler)
        return uiHandler
    }
}
