/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

private func anyToJavaScript(_ any: Any?) -> String {
    if let string = any as? String {
        return "\"\(string.replacingOccurrences(of: "\"", with: "\\\""))\""
    } else if let int = any as? Int {
        return "\(int)"
    } else if let float = any as? Float {
        return "\(float)"
    } else if let bool = any as? Bool {
        return bool ? "true" : "false"
    } else if let array = any as? [Any?] {
        var result: [String] = []
        for value in array {
            result.append(anyToJavaScript(value))
        }
        return "[" + result.joined(separator: ",") + "]"
    } else if let dictionary = any as? [String : Any?] {
        var result: [String] = []
        for (key, value) in dictionary {
            result.append("\"\(key)\":\(anyToJavaScript(value))")
        }
        return "{" + result.joined(separator: ",") + "}"
    } else if let _ = any as? NSNull {
        return "null"
    } else {
        return "undefined"
    }
}

protocol WebExtensionAPIConnectionHandler {
    func webExtension(_ webExtension: WebExtension, didReceiveConnection connection: WebExtensionAPIConnection)
}

class WebExtensionAPIEventDispatcher {
    class var Name: String { return "" }

    let webExtension: WebExtension

    init(webExtension: WebExtension) {
        self.webExtension = webExtension
    }

    func dispatch(to webView: WKWebView, listener: String, args: [Any?]? = nil) {
        DispatchQueue.main.async {
            let name = type(of: self).Name;
            webView.evaluateJavaScript("""
                (function() {
                    if (document.readyState !== \"complete\") {
                        document.addEventListener(\"readystatechange\", function() {
                            if (document.readyState === \"complete\") {
                                dispatchNativeEvent();
                            }
                        });
                    } else {
                        dispatchNativeEvent();
                    }

                    function dispatchNativeEvent() {
                        __firefox__.NativeEvent.dispatch(\"\(UserScriptManager.securityToken)\", \"\(self.webExtension.id)\", \"browser.\(name).\(listener)\", \(anyToJavaScript(args)));
                    }
                })();
                """)
        }
    }

    func dispatchToAllWebViews(listener: String, args: [Any?]? = nil) {
        DispatchQueue.main.async {
            for webView in WebExtensionManager.default.allWebViews {
                self.dispatch(to: webView, listener: listener, args: args)
            }
        }
    }
}

class WebExtensionAPIConnection {
    private let pipeId: String
    private let connectionId: String

    let type: String
    let method: String
    let payload: [String : Any?]?
    let webView: WKWebView

    private(set) var closed = false

    init?(message: WKScriptMessage, webExtension: WebExtension) {
        guard message.name == "webExtensionAPI",
            let webView = message.webView,
            let body = message.body as? [String : Any?],
            let pipeId = body["pipeId"] as? String,
            pipeId == webExtension.id, // Ensure we're only handling messages intended for this WebExtension
            let connectionId = body["connectionId"] as? String,
            let type = body["type"] as? String,
            let method = body["method"] as? String,
            let payload = body["payload"] as? [String : Any?]? else {
            return nil
        }

        self.pipeId = pipeId
        self.connectionId = connectionId

        self.type = type
        self.method = method
        self.payload = payload
        self.webView = webView
    }

    func error(_ description: String) {
        guard !closed else {
            print("WebExtension API connection \(connectionId) is closed for pipe \(pipeId)")
            return
        }

        webView.evaluateJavaScript("__firefox__.MessagePipe.respond('\(pipeId)', '\(connectionId)', null, new Error(\"\(description)\"));")
        closed = true
    }

    func respond(_ args: Any?...) {
        guard !closed else {
            print("WebExtension API connection \(connectionId) is closed for pipe \(pipeId)")
            return
        }

        var jsArgs: [String] = []
        for arg in args {
            jsArgs.append(anyToJavaScript(arg))
        }

        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("__firefox__.MessagePipe.respond('\(self.pipeId)', '\(self.connectionId)', [\(jsArgs.joined(separator: ","))]);")
        }

        closed = true
    }
}

class WebExtensionAPI: NSObject {
    let webExtension: WebExtension

    let alarms: WebExtensionAlarmsAPI
    let browserAction: WebExtensionBrowserActionAPI
    let browserSettings: WebExtensionBrowserSettingsAPI
    let clipboard: WebExtensionClipboardAPI
    let commands: WebExtensionCommandsAPI
    let contentScripts: WebExtensionContentScriptsAPI
    let cookies: WebExtensionCookiesAPI
    let dns: WebExtensionDNSAPI
    let `extension`: WebExtensionExtensionAPI
    let find: WebExtensionFindAPI
    let i18n: WebExtensionI18nAPI
    let identity: WebExtensionIdentityAPI
    let idle: WebExtensionIdleAPI
    let management: WebExtensionManagementAPI
    let notifications: WebExtensionNotificationsAPI
    let pageAction: WebExtensionPageActionAPI
    let permissions: WebExtensionPermissionsAPI
    let privacy: WebExtensionPrivacyAPI
    let proxy: WebExtensionProxyAPI
    let runtime: WebExtensionRuntimeAPI
    let search: WebExtensionSearchAPI
    let sidebarAction: WebExtensionSidebarActionAPI
    let storage: WebExtensionStorageAPI
    let tabs: WebExtensionTabsAPI
    let theme: WebExtensionThemeAPI
    let topSites: WebExtensionTopSitesAPI
    let webNavigation: WebExtensionWebNavigationAPI
    let webRequest: WebExtensionWebRequestAPI
    let windows: WebExtensionWindowsAPI

    init(webExtension: WebExtension) {
        self.webExtension = webExtension

        self.alarms = WebExtensionAlarmsAPI(webExtension: webExtension)
        self.browserAction = WebExtensionBrowserActionAPI(webExtension: webExtension)
        self.browserSettings = WebExtensionBrowserSettingsAPI(webExtension: webExtension)
        self.clipboard = WebExtensionClipboardAPI(webExtension: webExtension)
        self.commands = WebExtensionCommandsAPI(webExtension: webExtension)
        self.contentScripts = WebExtensionContentScriptsAPI(webExtension: webExtension)
        self.cookies = WebExtensionCookiesAPI(webExtension: webExtension)
        self.dns = WebExtensionDNSAPI(webExtension: webExtension)
        self.`extension` = WebExtensionExtensionAPI(webExtension: webExtension)
        self.find = WebExtensionFindAPI(webExtension: webExtension)
        self.i18n = WebExtensionI18nAPI(webExtension: webExtension)
        self.identity = WebExtensionIdentityAPI(webExtension: webExtension)
        self.idle = WebExtensionIdleAPI(webExtension: webExtension)
        self.management = WebExtensionManagementAPI(webExtension: webExtension)
        self.notifications = WebExtensionNotificationsAPI(webExtension: webExtension)
        self.pageAction = WebExtensionPageActionAPI(webExtension: webExtension)
        self.permissions = WebExtensionPermissionsAPI(webExtension: webExtension)
        self.privacy = WebExtensionPrivacyAPI(webExtension: webExtension)
        self.proxy = WebExtensionProxyAPI(webExtension: webExtension)
        self.runtime = WebExtensionRuntimeAPI(webExtension: webExtension)
        self.search = WebExtensionSearchAPI(webExtension: webExtension)
        self.sidebarAction = WebExtensionSidebarActionAPI(webExtension: webExtension)
        self.storage = WebExtensionStorageAPI(webExtension: webExtension)
        self.tabs = WebExtensionTabsAPI(webExtension: webExtension)
        self.theme = WebExtensionThemeAPI(webExtension: webExtension)
        self.topSites = WebExtensionTopSitesAPI(webExtension: webExtension)
        self.webNavigation = WebExtensionWebNavigationAPI(webExtension: webExtension)
        self.webRequest = WebExtensionWebRequestAPI(webExtension: webExtension)
        self.windows = WebExtensionWindowsAPI(webExtension: webExtension)

        super.init()
    }
}

extension WebExtensionAPI: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let connection = WebExtensionAPIConnection(message: message, webExtension: webExtension) else {
            print("Unable to establish API connection")
            return
        }

        let mirror = Mirror(reflecting: self)
        if let child = mirror.children.first(where: { $0.label == connection.type }),
            let connectionHandler = child.value as? WebExtensionAPIConnectionHandler {
            connectionHandler.webExtension(webExtension, didReceiveConnection: connection)
        } else {
            connection.error("API not implemented: \(connection.type)")
        }
    }
}
