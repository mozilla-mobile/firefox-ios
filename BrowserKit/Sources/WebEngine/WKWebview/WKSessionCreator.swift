// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

public protocol SessionCreator: AnyObject {
    /// Creates a popup WKWebView given a configuration and the source WebView for the popup.
    @MainActor
    func createPopupSession(configuration: WKWebViewConfiguration, parent: WKWebView) -> WKWebView?

    func alertStore(for webView: WKWebView) -> WKJavscriptAlertStore?

    func isSessionActive(for webView: WKWebView) -> Bool

    func currentActiveStore() -> WKJavscriptAlertStore?
}

typealias VoidReturnCallback<T> = (T) -> Void
