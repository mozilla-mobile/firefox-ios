/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

private func getWindow(populateTabs: Bool) -> [String : Any?]? {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
        let tabManager = appDelegate.tabManager,
        let selectedTab = tabManager.selectedTab,
        let keyWindow = UIApplication.shared.keyWindow else {
        return nil
    }

    let isFullscreen = keyWindow.screen.bounds.width == keyWindow.bounds.width

    let window: [String : Any?] = [
        "alwaysOnTop": false,
        "focused": true,
        "height": Int(keyWindow.bounds.height),
        "id": 0,
        "incognito": selectedTab.isPrivate,
        "left": 0,
        "sessionId": 0,
        "state": isFullscreen ? "fullscreen" : "docked",
        "tabs": [], // TODO: Populate if `populateTabs` is `true`.
        "title": selectedTab.title,
        "top": 0,
        "type": "normal",
        "width": Int(keyWindow.bounds.width)
    ]

    return window
}

class WebExtensionWindowsAPI: WebExtensionAPIEventDispatcher {
    override class var Name: String { return "windows" }

    enum Method: String {
        case get
        case getCurrent
        case getLastFocused
        case getAll
        case create
        case update
        case remove
    }

    func get(_ connection: WebExtensionAPIConnection) {
        let args = connection.payload ?? [:]

        guard let windowId = args["windowId"] as? Int else {
            connection.error("No Window ID specified")
            return
        }

        guard windowId == 0 else {
            connection.error("Unable to get Window with ID \(windowId)")
            return
        }

        let getInfo = args["getInfo"] as? [String : Any?] ?? [:]
        let populate = getInfo["populate"] as? Bool ?? false

        guard let window = getWindow(populateTabs: populate) else {
            connection.error("Unable to get current Window")
            return
        }

        connection.respond(window)
    }

    func getCurrent(_ connection: WebExtensionAPIConnection) {
        let getInfo = connection.payload ?? [:]
        let populate = getInfo["populate"] as? Bool ?? false

        guard let window = getWindow(populateTabs: populate) else {
            connection.error("Unable to get current Window")
            return
        }

        connection.respond(window)
    }

    func getLastFocused(_ connection: WebExtensionAPIConnection) {
        let getInfo = connection.payload ?? [:]
        let populate = getInfo["populate"] as? Bool ?? false

        guard let window = getWindow(populateTabs: populate) else {
            connection.error("Unable to get current Window")
            return
        }

        connection.respond(window)
    }

    func getAll(_ connection: WebExtensionAPIConnection) {
        let getInfo = connection.payload ?? [:]
        let populate = getInfo["populate"] as? Bool ?? false

        guard let window = getWindow(populateTabs: populate) else {
            connection.error("Unable to get current Window")
            return
        }

        connection.respond([window])
    }
}

extension WebExtensionWindowsAPI: WebExtensionAPIConnectionHandler {
    func webExtension(_ webExtension: WebExtension, didReceiveConnection connection: WebExtensionAPIConnection) {
        guard let method = Method.init(rawValue: connection.method) else {
            connection.error("Unknown method: \(connection.method)")
            return
        }

        switch method {
        case .get:
            get(connection)
        case .getCurrent:
            getCurrent(connection)
        case .getLastFocused:
            getLastFocused(connection)
        case .getAll:
            getAll(connection)
        default:
            connection.error("Method not implemented: \(connection.method)")
        }
    }
}
