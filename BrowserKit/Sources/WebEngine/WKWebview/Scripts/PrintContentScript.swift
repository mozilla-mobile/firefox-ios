// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Script utility to handle showing print preview options for the content via the system-provided UI on pages
final class PrintContentScript: WKContentScript {
    private weak var webView: WKEngineWebView?

    init(webView: WKEngineWebView?) {
        self.webView = webView
    }
    static func name() -> String {
        return "Print"
    }

    func scriptMessageHandlerNames() -> [String] {
        return ["printHandler"]
    }

    func userContentController(didReceiveMessage message: Any) {
        let printController = UIPrintInteractionController.shared
        printController.printFormatter = webView?.viewPrintFormatter()
        printController.present(animated: true, completionHandler: nil)
    }
}
