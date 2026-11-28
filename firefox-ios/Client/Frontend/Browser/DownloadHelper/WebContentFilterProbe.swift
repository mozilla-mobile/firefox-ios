// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import WebKit

/// Asks WebKit whether system web content restrictions (Screen Time "Limit Adult Websites")
/// would block `url`.
/// Downloads go through `URLSession`, which does not consult that filter,
/// so a blocked page can otherwise be saved from "Download Link".
@MainActor
final class WebContentFilterProbe: NSObject, WKNavigationDelegate {
    /// `WebKitErrorDomain` / `FrameLoadBlockedByContentFilter`. Not a public `WKError.Code` case.
    static let blockedByContentFilterErrorCode = 105
    private static let timeoutNanoseconds: UInt64 = 15 * NSEC_PER_SEC

    private var continuation: CheckedContinuation<Bool, Never>?
    private var navigation: WKNavigation?
    private var timeoutTask: Task<Void, Never>?
    private var webView: WKWebView?
    /// Keeps the probe alive until the navigation finishes. `WKWebView` does not retain its delegate.
    private var lifetime: WebContentFilterProbe?
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        super.init()
    }

    init(continuation: CheckedContinuation<Bool, Never>, logger: Logger = DefaultLogger.shared) {
        self.continuation = continuation
        self.logger = logger
        super.init()
    }

    /// `true` when restrictions block `url`. Non-http(s) URLs, and checks that never reach a
    /// decision, return `false` so a download is not refused without evidence of a block.
    func isBlocked(url: URL, dataStore: WKWebsiteDataStore, container: UIView) async -> Bool {
        guard Self.shouldCheck(url) else { return false }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.lifetime = self
            start(url: url, dataStore: dataStore, container: container)
        }
    }

    static func shouldCheck(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    static func isBlockedByContentFilter(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == WKErrorDomain && nsError.code == blockedByContentFilterErrorCode
    }

    /// WebKit substitutes this document when a content filter blocks a load.
    static func isSystemBlockPage(_ url: URL?) -> Bool {
        guard let url else { return false }
        if url.scheme?.lowercased() == "x-apple-content-filter" { return true }
        return url.lastPathComponent == "ContentFilterBlockedPage.html"
    }

    /// Starts awaiting `navigation`, or resumes allowed when `load` returned nothing to wait for.
    func beginAwaiting(_ navigation: WKNavigation?) {
        guard let navigation else {
            finish(isBlocked: false)
            return
        }
        self.navigation = navigation
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.timeoutNanoseconds)
            guard !Task.isCancelled else { return }
            self?.logger.log("Timed out checking content restrictions before download",
                             level: .warning,
                             category: .webview)
            self?.finish(isBlocked: false)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        guard matches(navigation) else { return }
        finish(isBlocked: Self.isSystemBlockPage(webView.url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        guard matches(navigation) else { return }
        finish(isBlocked: Self.isSystemBlockPage(webView.url))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
        resolveFailure(navigation, error: error)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        resolveFailure(navigation, error: error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        finish(isBlocked: false)
    }

    private func start(url: URL, dataStore: WKWebsiteDataStore, container: UIView) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = dataStore
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        configuration.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: configuration)
        webView.navigationDelegate = self
        webView.alpha = 0
        webView.isUserInteractionEnabled = false
        webView.accessibilityElementsHidden = true
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = []
        container.addSubview(webView)
        self.webView = webView
        beginAwaiting(webView.load(URLRequest(url: url)))
    }

    private func resolveFailure(_ navigation: WKNavigation?, error: Error) {
        guard matches(navigation) else { return }
        let blocked = Self.isBlockedByContentFilter(error)
        if blocked {
            logger.log("Download refused because a content filter blocked the URL",
                       level: .info,
                       category: .webview)
        }
        finish(isBlocked: blocked)
    }

    private func matches(_ navigation: WKNavigation?) -> Bool {
        guard continuation != nil, let awaited = self.navigation else { return false }
        return navigation === awaited
    }

    private func finish(isBlocked: Bool) {
        guard continuation != nil else { return }
        timeoutTask?.cancel()
        timeoutTask = nil
        webView?.navigationDelegate = nil
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil
        navigation = nil
        let continuation = self.continuation
        self.continuation = nil
        continuation?.resume(returning: isBlocked)
        lifetime = nil
    }
}
