// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import WebEngine

class MockWKFrameInfo: WKFrameInfo {
    let overridenWebView: WKWebView?
    let overridenIsMainFrame: Bool

    init(webView: MockWKWebView? = nil, isMainFrame: Bool = true) {
        overridenWebView = webView
        overridenIsMainFrame = isMainFrame
    }

    override var isMainFrame: Bool {
        return overridenIsMainFrame
    }

    override var webView: WKWebView? {
        return overridenWebView
    }
}
