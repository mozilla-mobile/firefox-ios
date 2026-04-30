// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

final class TabContentScriptManager: NSObject, WKScriptMessageHandler {
    private var helpers = [String: TabContentScript]()

    // Without calling this, the TabContentScriptManager will leak.
    func uninstall(tab: Tab) {
        helpers.forEach { helper in
            helper.value.scriptMessageHandlerNames()?.forEach { name in
                tab.webView?.configuration.userContentController.removeScriptMessageHandler(forName: name)
            }
            helper.value.prepareForDeinit()
        }
        helpers.removeAll()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        for helper in helpers.values {
            if let scriptMessageHandlerNames = helper.scriptMessageHandlerNames(),
               scriptMessageHandlerNames.contains(message.name) {
                helper.userContentController(userContentController, didReceiveScriptMessage: message)
                return
            }
        }
    }

    func addContentScript(_ helper: TabContentScript, name: String, forTab tab: Tab) {
        // If a helper script already exists on a tab, skip adding this duplicate.
        guard helpers[name] == nil else { return }

        helpers[name] = helper

        // If this helper handles script messages, then get the handlers names and register them. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        helper.scriptMessageHandlerNames()?.forEach { scriptMessageHandlerName in
            tab.webView?.configuration.userContentController.addInDefaultContentWorld(
                scriptMessageHandler: self,
                name: scriptMessageHandlerName
            )
        }
    }

    func addContentScriptToPage(_ helper: TabContentScript, name: String, forTab tab: Tab) {
        // If a helper script already exists on the page, skip adding this duplicate.
        guard helpers[name] == nil else { return }

        helpers[name] = helper

        // If this helper handles script messages, then get the handlers names and register them. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        helper.scriptMessageHandlerNames()?.forEach { scriptMessageHandlerName in
            tab.webView?.configuration.userContentController.addInPageContentWorld(
                scriptMessageHandler: self,
                name: scriptMessageHandlerName
            )
        }
    }

    func addContentScriptToCustomWorld(_ helper: TabContentScript, name: String, forTab tab: Tab) {
        // If a helper script already exists on the page, skip adding this duplicate.
        guard helpers[name] == nil else { return }

        helpers[name] = helper

        // If this helper handles script messages, then get the handlers names and register them. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        helper.scriptMessageHandlerNames()?.forEach { scriptMessageHandlerName in
            tab.webView?.configuration.userContentController.addInCustomContentWorld(
                scriptMessageHandler: self,
                name: scriptMessageHandlerName
            )
        }
    }

    func getContentScript(_ name: String) -> TabContentScript? {
        return helpers[name]
    }
}
