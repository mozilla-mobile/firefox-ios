// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockWKWebViewProvider: WKWebViewProvider {
    var webView: MockWKEngineWebView!

    func createWebview(configurationProvider: WKEngineConfigurationProvider) -> WKEngineWebView? {
        let webView = MockWKEngineWebView(frame: .zero, configurationProvider: configurationProvider)
        self.webView = webView
        return webView
    }
}
