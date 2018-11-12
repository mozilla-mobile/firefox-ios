/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class WebExtensionTabsAPI: WebExtensionAPIEventDispatcher {
    override class var Name: String { return "tabs" }

    enum Method: String {
        case captureTab
        case captureVisibleTab
        case connect
        case create
        case detectLanguage
        case discard
        case duplicate
        case executeScript
        case get
        case getAllInWindow
        case getCurrent
        case getSelected
        case getZoom
        case getZoomSettings
        case hide
        case highlight
        case insertCSS
        case move
        case print
        case printPreview
        case query
        case reload
        case remove
        case removeCSS
        case saveAsPDF
        case sendMessage
        case sendRequest
        case setZoom
        case setZoomSettings
        case show
        case toggleReaderMode
        case update
    }

    func create(_ connection: WebExtensionAPIConnection) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let tabManager = appDelegate.tabManager else {
            return
        }

        webExtension.backgroundProcess?.createTab { tab in
            tabManager.selectTab(tab)

            DispatchQueue.main.async {
                let createProperties = connection.payload ?? [:]
                if let urlPath = createProperties["url"] as? String {
                    let url = self.webExtension.urlForResource(at: urlPath)
                    tab.loadRequest(PrivilegedRequest(url: url) as URLRequest)
                }

                let tabDictionary: [String : Any?] = [
                    "id": tab.id,
                    "active": true,
                    "hidden": false,
                    "highlighted": true,
                    "incognito": tab.isPrivate,
                    "index": tabManager.tabs.firstIndex(of: tab) ?? -1,
                    "isArticle": tab.readerModeAvailableOrActive,
                    "isInReaderMode": tab.url?.isReaderModeURL ?? false,
                    "lastAccessed": tab.lastExecutedTime ?? 0,
                    "pinned": false,
                    "selected": true,
                    "url": tab.url?.absoluteString
                ]

                connection.respond([tabDictionary])
            }
        }
    }

    func executeScript(_ connection: WebExtensionAPIConnection) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let tabManager = appDelegate.tabManager else {
            connection.error("An unexpected error has occurred")
            return
        }

        let args = connection.payload ?? [:]

        let tab: Tab?
        if let tabId = args["tabId"] as? Int {
            tab = tabManager.tabs.find({ $0.id == tabId })
        } else {
            tab = tabManager.selectedTab
        }

        guard tab != nil else {
            connection.error("Unable to get Tab")
            return
        }

        let details = args["details"] as? [String : Any?] ?? [:]

        var code: String?
        if let file = details["file"] as? String {
            let url = webExtension.tempDirectoryURL.appendingPathComponent(file)
            if let string = try? NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String {
                code = string
            }
        } else {
            code = details["code"] as? String
        }

        guard let javaScriptString = code else {
            connection.error("No JavaScript found to execute")
            return
        }

        tab?.webView?.evaluateJavaScript(javaScriptString, completionHandler: { (result, error) in
            if let error = error {
                connection.error(error.localizedDescription)
                return
            }

            connection.respond(result)
        })
    }

    func query(_ connection: WebExtensionAPIConnection) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let tabManager = appDelegate.tabManager else {
            return
        }

        let queryInfo = connection.payload ?? [:]
        if let active = queryInfo["active"] as? Bool, active,
            let selectedTab = tabManager.selectedTab {
            let tab: [String : Any?] = [
                "id": selectedTab.id,
                "active": true,
                "hidden": false,
                "highlighted": true,
                "incognito": selectedTab.isPrivate,
                "index": tabManager.tabs.firstIndex(of: selectedTab) ?? -1,
                "isArticle": selectedTab.readerModeAvailableOrActive,
                "isInReaderMode": selectedTab.url?.isReaderModeURL ?? false,
                "lastAccessed": selectedTab.lastExecutedTime ?? 0,
                "pinned": false,
                "selected": true,
                "url": selectedTab.url?.absoluteString
            ]

            connection.respond([tab])
        }

        connection.respond([])
    }

    func sendMessage(_ connection: WebExtensionAPIConnection) {
        guard let payload = connection.payload,
            let tabId = payload["tabId"] as? Int,
            let message = payload["message"] as? [String : Any?] else {
            return
        }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let tabManager = appDelegate.tabManager else {
            return
        }

        guard let tab = tabManager.tabs.find({ $0.id == tabId }),
            let webView = tab.webView else {
            return
        }

        webExtension.interface.runtime.dispatch(to: webView, listener: "onMessage", args: [message])
    }
}

extension WebExtensionTabsAPI: WebExtensionAPIConnectionHandler {
    func webExtension(_ webExtension: WebExtension, didReceiveConnection connection: WebExtensionAPIConnection) {
        guard let method = Method.init(rawValue: connection.method) else {
            connection.error("Unknown method: \(connection.method)")
            return
        }

        switch method {
        case .create:
            create(connection)
        case .executeScript:
            executeScript(connection)
        case .query:
            query(connection)
        case .sendMessage:
            sendMessage(connection)
        default:
            connection.error("Method not implemented: \(connection.method)")
        }
    }
}
