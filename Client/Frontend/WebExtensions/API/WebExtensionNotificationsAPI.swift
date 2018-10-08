/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UserNotifications
import WebKit

class WebExtensionNotificationsAPI: WebExtensionAPIEventDispatcher {
    override class var Name: String { return "notifications" }

    enum Method: String {
        case clear
        case create
        case getAll
        case update
    }

    enum NotificationOptionsTemplateType: String {
        case basic
        case image
        case list
        case progress
    }

    func create(_ connection: WebExtensionAPIConnection) {
        guard let payload = connection.payload,
            let id = payload["id"] as? String,
            let options = payload["options"] as? [String : Any?],
            let message = options["message"] as? String,
            let title = options["title"] as? String,
            let typeString = options["type"] as? String,
            let type = NotificationOptionsTemplateType(rawValue: typeString) else {
            return
        }

        switch type {
        default:
            print("Unknown notification TemplateType: \(typeString)")
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message

        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            connection.respond([])
        }
    }
}

extension WebExtensionNotificationsAPI: WebExtensionAPIConnectionHandler {
    func webExtension(_ webExtension: WebExtension, didReceiveConnection connection: WebExtensionAPIConnection) {
        guard let method = Method.init(rawValue: connection.method) else {
            connection.error("Unknown method: \(connection.method)")
            return
        }

        switch method {
        case .create:
            create(connection)
        default:
            connection.error("Method not implemented: \(connection.method)")
        }
    }
}
