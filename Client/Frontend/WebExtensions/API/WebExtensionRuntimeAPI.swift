/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class WebExtensionRuntimeAPI: WebExtensionAPIEventDispatcher {
    override class var Name: String { return "runtime" }

    enum Method: String {
        case getBackgroundPage
        case openOptionsPage
        case getManifest
        case getURL
        case setUninstallURL
        case reload
        case requestUpdateCheck
        case connect
        case connectNative
        case sendMessage
        case sendNativeMessage
        case getPlatformInfo
        case getBrowserInfo
        case getPackageDirectoryEntry
    }

    func sendMessage(_ connection: WebExtensionAPIConnection) {
        guard let payload = connection.payload,
            let message = payload["message"] as? [String : Any?] else {
            return
        }

        let extensionId = payload["extensionId"] as? String ?? webExtension.id
        let options = payload["options"] as? [String : Any?]

        guard let targetWebExtension = WebExtensionManager.default.webExtensions.find({ $0.id == extensionId }) else {
            return
        }

        targetWebExtension.interface.runtime.dispatchToAllWebViews(listener: "onMessage", args: [message, options])
    }
}

extension WebExtensionRuntimeAPI: WebExtensionAPIConnectionHandler {
    func webExtension(_ webExtension: WebExtension, didReceiveConnection connection: WebExtensionAPIConnection) {
        guard let method = Method.init(rawValue: connection.method) else {
            connection.error("Unknown method: \(connection.method)")
            return
        }

        switch method {
        case .sendMessage:
            sendMessage(connection)
        default:
            connection.error("Method not implemented: \(connection.method)")
        }
    }
}
