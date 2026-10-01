// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import WebEngine

class MockWKEngineWebViewDelegate: WKEngineWebViewDelegate {
    var webViewNeedsReloadCalled = 0
    var webViewPropertyChangedCalled = 0
    var lastWebViewPropertyChanged: WKEngineWebViewProperty?
    var webViewPropertyChangedCallback: ((WKEngineWebViewProperty) -> Void)?

    func tabWebView(_ webView: WKEngineWebView, findInPageSelection: String) {}

    func tabWebView(_ webView: WKEngineWebView, searchSelection: String) {}

    func tabWebViewInputAccessoryView(_ webView: WKEngineWebView) -> EngineInputAccessoryView {
        return .default
    }

    func webViewPropertyChanged(_ property: WKEngineWebViewProperty) {
        webViewPropertyChangedCalled += 1
        lastWebViewPropertyChanged = property
        webViewPropertyChangedCallback?(property)
    }

    func webViewNeedsReload() {
        webViewNeedsReloadCalled += 1
    }
}
