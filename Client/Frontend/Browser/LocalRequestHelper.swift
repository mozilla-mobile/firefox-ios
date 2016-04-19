/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class LocalRequestHelper: TabHelper {
    func scriptMessageHandlerName() -> String? {
        return "localRequestHelper"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard message.frameInfo.request.URL?.isLocal ?? false else { return }

        let params = message.body as! [String: String]

        if params["type"] == "load",
           let url = NSURL(string: params["url"]!) {
            message.webView?.loadRequest(PrivilegedRequest(URL: url))
        } else if params["type"] == "reload" {
            message.webView?.reload()
        } else {
            assertionFailure("Invalid message: \(message.body)")
        }
    }

    class func name() -> String {
        return "LocalRequestHelper"
    }
}
