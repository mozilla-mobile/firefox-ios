// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// ⚠️⚠️⚠️⚠️ Careful, don't use this ⚠️⚠️⚠️⚠️
/// Resumes a continuation once the navigation it is given reaches a terminal state. For
/// awaiting a single navigation on a webview whose usual delegate should not see it.
///
/// Every navigation ends in `didFinish`, one of the two failure callbacks, or the loss of its
/// content process, so there is always exactly one resume and no need for a timeout.
@MainActor
final class BlankPageNavigationDelegate: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var awaitedNavigation: WKNavigation?

    init(continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation
        super.init()
    }

    /// Starts awaiting `navigation`, or resumes straight away when `load` returned nothing to
    /// wait for. Must be called before returning to the runloop, which is the earliest WebKit
    /// can deliver a callback for the navigation.
    func beginAwaiting(_ navigation: WKNavigation?) {
        guard let navigation else {
            finish()
            return
        }
        awaitedNavigation = navigation
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        finish(for: navigation)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
        finish(for: navigation)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        finish(for: navigation)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // The document and every load it owned went with the process, so there is nothing
        // left to wait for.
        finish()
    }

    /// Ignores callbacks for any other navigation, so a late failure from the load being
    /// replaced cannot resume us before the awaited one has finished.
    private func finish(for navigation: WKNavigation?) {
        guard navigation === awaitedNavigation else { return }
        finish()
    }

    private func finish() {
        continuation?.resume()
        continuation = nil
    }
}
