// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@preconcurrency import WebKit

@testable import Client

class TabManagerNavDelegateTests: XCTestCase {
    let navigation = WKNavigation()

    func test_webViewDidCommit_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webView(anyWebView(), didCommit: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidCommit])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidCommit])
    }

    func test_webViewDidFail_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webView(anyWebView(), didFail: navigation, withError: anyError())

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidFail])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidFail])
    }

    func test_webViewDidFailProvisionalNavigation_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webView(anyWebView(), didFailProvisionalNavigation: navigation, withError: anyError())

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidFailProvisionalNavigation])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidFailProvisionalNavigation])
    }

    func test_webViewDidFinish_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webView(anyWebView(), didFinish: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidFinish])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidFinish])
    }

    func test_webViewWebContentProcessDidTerminate_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webViewWebContentProcessDidTerminate(anyWebView())

        XCTAssertEqual(delegate1.receivedMessages, [.webViewWebContentProcessDidTerminate])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewWebContentProcessDidTerminate])
    }

    func test_webViewDidReceiveAuthenticationChallenge_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webView(anyWebView(), didReceive: anyAuthenticationChallenge()) { (_, _) in }

        // This message is send only to the first delegate that respond to to authentication challenge (BVC)
        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidReceiveAuthenticationChallenge])
        XCTAssertEqual(delegate2.receivedMessages, [])
    }

    func test_webViewDidReceiveServerRedirectForProvisionalNavigation_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webView(anyWebView(), didReceiveServerRedirectForProvisionalNavigation: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidReceiveServerRedirectForProvisionalNavigation])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidReceiveServerRedirectForProvisionalNavigation])
    }

    func test_webViewDidStartProvisionalNavigation_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webView(anyWebView(), didStartProvisionalNavigation: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidStartProvisionalNavigation])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidStartProvisionalNavigation])
    }

    func test_webViewDecidePolicyFor_actionPolicy_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webView(anyWebView(),
                        decidePolicyFor: WKNavigationAction(),
                        decisionHandler: { _ in })

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDecidePolicyWithActionPolicy])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDecidePolicyWithActionPolicy])
    }

    func test_webViewDecidePolicyFor_responsePolicy_sendsCorrectMessage() {
        let subjectConstructor = createSubject()
        let subject = subjectConstructor.subject
        let delegate1 = subjectConstructor.delegate1
        let delegate2 = subjectConstructor.delegate2

        subject.insert(delegate1)
        subject.insert(delegate2)
        subject.webView(anyWebView(),
                        decidePolicyFor: WKNavigationResponse(),
                        decisionHandler: { _ in })

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDecidePolicyWithResponsePolicy])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDecidePolicyWithResponsePolicy])
    }
}

// MARK: - Helpers

private extension TabManagerNavDelegateTests {
    struct Subject {
        let subject: TabManagerNavDelegate
        let delegate1: WKNavigationDelegateSpy
        let delegate2: WKNavigationDelegateSpy
    }

    func createSubject(file: StaticString = #file, line: UInt = #line) -> Subject {
        let subject = TabManagerNavDelegate()
        let delegate1 = WKNavigationDelegateSpy()
        let delegate2 = WKNavigationDelegateSpy()

        trackForMemoryLeaks(subject, file: file, line: line)
        trackForMemoryLeaks(delegate1, file: file, line: line)
        trackForMemoryLeaks(delegate2, file: file, line: line)

        return Subject(subject: subject, delegate1: delegate1, delegate2: delegate2)
    }

    func anyWebView() -> WKWebView {
        return WKWebView(frame: CGRect(width: 100, height: 100))
    }

    func anyError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    func anyAuthenticationChallenge() -> URLAuthenticationChallenge {
        return URLAuthenticationChallenge()
    }
}

// MARK: - WKNavigationDelegateSpy
private class WKNavigationDelegateSpy: NSObject, WKNavigationDelegate {
    enum Message {
        case webViewDidCommit
        case webViewDidFail
        case webViewDidFailProvisionalNavigation
        case webViewDidFinish
        case webViewWebContentProcessDidTerminate
        case webViewDidReceiveAuthenticationChallenge
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

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        receivedMessages.append(.webViewDidFailProvisionalNavigation)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidFinish)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        receivedMessages.append(.webViewWebContentProcessDidTerminate)
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        receivedMessages.append(.webViewDidReceiveAuthenticationChallenge)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidReceiveServerRedirectForProvisionalNavigation)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidStartProvisionalNavigation)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        receivedMessages.append(.webViewDecidePolicyWithActionPolicy)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        receivedMessages.append(.webViewDecidePolicyWithResponsePolicy)
    }
}
