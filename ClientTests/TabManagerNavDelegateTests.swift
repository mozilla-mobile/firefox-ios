// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit

@testable import Client

class TabManagerNavDelegateTests: XCTestCase {
    let navigation = WKNavigation()

    func test_webViewDidCommit_sendsCorrectMessage() {
        let (sut, delegate1, delegate2) = makeSUT()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didCommit: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidCommit])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidCommit])
    }

    func test_webViewDidFail_sendsCorrectMessage() {
        let (sut, delegate1, delegate2) = makeSUT()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didFail: navigation, withError: anyError())

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidFail])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidFail])
    }

    func test_webViewDidFailProvisionalNavigation_sendsCorrectMessage() {
        let (sut, delegate1, delegate2) = makeSUT()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didFailProvisionalNavigation: navigation, withError: anyError())

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidFailProvisionalNavigation])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidFailProvisionalNavigation])
    }

    func test_webViewDidFinish_sendsCorrectMessage() {
        let (sut, delegate1, delegate2) = makeSUT()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didFinish: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidFinish])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidFinish])
    }

    func test_webViewWebContentProcessDidTerminate_sendsCorrectMessage() {
        let (sut, delegate1, delegate2) = makeSUT()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webViewWebContentProcessDidTerminate(anyWebView())

        XCTAssertEqual(delegate1.receivedMessages, [.webViewWebContentProcessDidTerminate])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewWebContentProcessDidTerminate])
    }

    func test_webViewDidReceiveServerRedirectForProvisionalNavigation_sendsCorrectMessage() {
        let (sut, delegate1, delegate2) = makeSUT()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didReceiveServerRedirectForProvisionalNavigation: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidReceiveServerRedirectForProvisionalNavigation])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidReceiveServerRedirectForProvisionalNavigation])
    }

    func test_webViewDidStartProvisionalNavigation_sendsCorrectMessage() {
        let (sut, delegate1, delegate2) = makeSUT()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didStartProvisionalNavigation: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidStartProvisionalNavigation])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidStartProvisionalNavigation])
    }

    func test_webViewDecidePolicyFor_actionPolicy_sendsCorrectMessage() {
        let (sut, delegate1, delegate2) = makeSUT()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(),
                    decidePolicyFor: WKNavigationAction(),
                    decisionHandler: { _ in })

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDecidePolicyWithActionPolicy])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDecidePolicyWithActionPolicy])
    }

    func test_webViewDecidePolicyFor_responsePolicy_sendsCorrectMessage() {
        let (sut, delegate1, delegate2) = makeSUT()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(),
                    decidePolicyFor: WKNavigationResponse(),
                    decisionHandler: { _ in })

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDecidePolicyWithResponsePolicy])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDecidePolicyWithResponsePolicy])
    }
}

// MARK: - Helpers

private func makeSUT() -> (sut: TabManagerNavDelegate, delegate1: WKNavigationDelegateSpy, delegate2: WKNavigationDelegateSpy) {
    let sut = TabManagerNavDelegate()
    let delegate1 = WKNavigationDelegateSpy()
    let delegate2 = WKNavigationDelegateSpy()

    return (sut, delegate1, delegate2)
}

private func anyWebView() -> WKWebView {
    return WKWebView(frame: CGRect(width: 100, height: 100))
}

private func anyError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

private class WKNavigationDelegateSpy: NSObject, WKNavigationDelegate {
    enum Message {
        case webViewDidCommit
        case webViewDidFail
        case webViewDidFailProvisionalNavigation
        case webViewDidFinish
        case webViewWebContentProcessDidTerminate
        case webViewDidReceiveServerRedirectForProvisionalNavigation
        case webViewDidStartProvisionalNavigation
        case webViewDecidePolicyWithActionPolicy
        case webViewDecidePolicyWithResponsePolicy
    }

    var receivedMessages = [Message]()

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidCommit)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        receivedMessages.append(.webViewDidFail)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        receivedMessages.append(.webViewDidFailProvisionalNavigation)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidFinish)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        receivedMessages.append(.webViewWebContentProcessDidTerminate)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidReceiveServerRedirectForProvisionalNavigation)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidStartProvisionalNavigation)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        receivedMessages.append(.webViewDecidePolicyWithActionPolicy)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        receivedMessages.append(.webViewDecidePolicyWithResponsePolicy)
    }
}
