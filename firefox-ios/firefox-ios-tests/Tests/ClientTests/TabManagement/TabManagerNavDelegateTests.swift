// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@preconcurrency import WebKit

@testable import Client

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
