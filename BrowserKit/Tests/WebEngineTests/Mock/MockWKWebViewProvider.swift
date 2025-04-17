// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

@available(iOS 16.0, *)
class MockWKWebViewProvider: WKWebViewProvider {
    var webView: MockWKEngineWebView!

    func createWebview(configurationProvider: WKEngineConfigurationProvider,
                       parameters: WKWebViewParameters) -> WKEngineWebView? {
        let webView = MockWKEngineWebView(frame: .zero,
                                          configurationProvider: configurationProvider,
                                          parameters: parameters)
        self.webView = webView
        return webView
    }
}
