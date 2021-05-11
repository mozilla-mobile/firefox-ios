/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared

class LocalRequestHelper: TabContentScript {
    func scriptMessageHandlerName() -> String? {
        return "localRequestHelper"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let requestUrl = message.frameInfo.request.url, let internalUrl = InternalURL(requestUrl) else { return }

        let params = message.body as! [String: String]

        guard let token = params["appIdToken"], token == UserScriptManager.appIdToken else {
            print("Missing required appid token.")
            return
        }

        if params["type"] == "reload" {
            // If this is triggered by session restore pages, the url to reload is a nested url argument.
            if let _url = internalUrl.extractedUrlParam, let nested = InternalURL(_url), let url = nested.extractedUrlParam {
                message.webView?.replaceLocation(with: url)
            } else {
            _ = message.webView?.reload()
            }
        } else {
            assertionFailure("Invalid message: \(message.body)")
        }
    }

    class func name() -> String {
        return "LocalRequestHelper"
    }
}
