/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class WebExtensionDownloadsAPI: WebExtensionAPIEventDispatcher {
    override class var Name: String { return "downloads" }

    enum Method: String {
        case download
        case search
        case pause
        case resume
        case cancel
        case getFileIcon
        case open
        case show
        case showDefaultFolder
        case erase
        case removeFile
        case acceptDanger
        case drag
        case setShelfEnabled
    }
}

extension WebExtensionDownloadsAPI: WebExtensionAPIConnectionHandler {
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
