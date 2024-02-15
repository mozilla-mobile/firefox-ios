// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Manager used to add and remove scripts inside a WKEngineSession
protocol WKContentScriptManager: WKScriptMessageHandler {
    var scripts: [String: WKContentScript] { get }

    func addContentScript(_ script: WKContentScript,
                          name: String,
                          forSession session: WKEngineSession)

    func addContentScriptToPage(_ script: WKContentScript,
                                name: String,
                                forSession session: WKEngineSession)

    func uninstall(session: WKEngineSession)
}

class DefaultContentScriptManager: NSObject, WKContentScriptManager {
    private(set) var scripts = [String: WKContentScript]()

    func addContentScript(_ script: WKContentScript,
                          name: String,
                          forSession session: WKEngineSession) {
        // If a script already exists on a session, skip adding this duplicate.
        guard scripts[name] == nil else { return }

        scripts[name] = script

        // If this helper handles script messages, then get the handlers names and register them
        script.scriptMessageHandlerNames().forEach { scriptMessageHandlerName in
            session.webView.engineConfiguration.addInDefaultContentWorld(
                scriptMessageHandler: self,
                name: scriptMessageHandlerName
            )
        }
    }

    func addContentScriptToPage(_ script: WKContentScript,
                                name: String,
                                forSession session: WKEngineSession) {
        // If a script already exists on the page, skip adding this duplicate.
        guard scripts[name] == nil else { return }

        scripts[name] = script

        // If this helper handles script messages, then get the handlers names and register them
        script.scriptMessageHandlerNames().forEach { scriptMessageHandlerName in
            session.webView.engineConfiguration.addInPageContentWorld(
                scriptMessageHandler: self,
                name: scriptMessageHandlerName
            )
        }
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        for script in scripts.values where script.scriptMessageHandlerNames().contains(message.name) {
            script.userContentController(didReceiveMessage: message.body)
            return
        }
    }

    func uninstall(session: WKEngineSession) {
        scripts.forEach { script in
            script.value.scriptMessageHandlerNames().forEach { name in
                session.webView.engineConfiguration.removeScriptMessageHandler(forName: name)
            }
            script.value.prepareForDeinit()
        }
    }
}
