/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class WebExtensionManagementAPI: WebExtensionAPIEventDispatcher {
    override class var Name: String { return "management" }

    enum Method: String {
        case getAll
        case get
        case getSelf
        case install
        case uninstall
        case uninstallSelf
        case getPermissionWarningsById
        case getPermissionWarningsByManifest
        case setEnabled
    }
}

extension WebExtensionManagementAPI: WebExtensionAPIConnectionHandler {
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
