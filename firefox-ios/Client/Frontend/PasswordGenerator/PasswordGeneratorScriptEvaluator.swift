// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

protocol PasswordGeneratorScriptEvaluator: Sendable {
    @MainActor
    func evaluateJavascriptInDefaultContentWorld(_ javascript: String,
                                                 _ frame: WKFrameInfo?,
                                                 _ completion: @MainActor @escaping (Any?, Error?) -> Void)
}

@MainActor
final class WebKitPasswordGeneratorScriptEvaluator: PasswordGeneratorScriptEvaluator {
    private weak var webView: WKWebView?

    init(webView: WKWebView?) {
        self.webView = webView
    }

    func evaluateJavascriptInDefaultContentWorld(_ javascript: String,
                                                 _ frame: WKFrameInfo?,
                                                 _ completion: @MainActor @escaping (Any?, Error?) -> Void) {
        webView?.evaluateJavascriptInDefaultContentWorld(javascript, frame, completion)
    }
}
