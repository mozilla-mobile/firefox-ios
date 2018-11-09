/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class WebExtensionBrowserSettingsAPI: WebExtensionAPIEventDispatcher {
    override class var Name: String { return "browserSettings" }

    enum Method: String {
        case noop
    }
}

extension WebExtensionBrowserSettingsAPI: WebExtensionAPIConnectionHandler {
    func webExtension(_ webExtension: WebExtension, didReceiveConnection connection: WebExtensionAPIConnection) {
        guard let method = Method.init(rawValue: connection.method) else {
            connection.error("Unknown method: \(connection.method)")
            return
        }

        switch method {
        default:
            connection.error("Method not implemented: \(connection.method)")
        }
    }
}
