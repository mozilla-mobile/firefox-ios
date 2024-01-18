// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Abstraction on top of `WKWebViewConfiguration` and the `WKUserContentController`
protocol WKEngineConfiguration {
    func addUserScript(_ userScript: WKUserScript)
    func addInDefaultContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String)
    func addInPageContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String)
    func removeScriptMessageHandler(forName name: String)
    func removeAllUserScripts()
}

struct DefaultEngineConfiguration: WKEngineConfiguration {
    var webViewConfiguration: WKWebViewConfiguration

    func addUserScript(_ userScript: WKUserScript) {
        webViewConfiguration.userContentController.addUserScript(userScript)
    }

    func addInDefaultContentWorld(scriptMessageHandler: WKScriptMessageHandler,
                                  name: String) {
        webViewConfiguration.userContentController.add(scriptMessageHandler,
                                                       contentWorld: .defaultClient,
                                                       name: name)
    }

    func addInPageContentWorld(scriptMessageHandler: WKScriptMessageHandler,
                               name: String) {
        webViewConfiguration.userContentController.add(scriptMessageHandler,
                                                       contentWorld: .page,
                                                       name: name)
    }

    func removeScriptMessageHandler(forName name: String) {
        webViewConfiguration.userContentController.removeScriptMessageHandler(forName: name)
    }

    func removeAllUserScripts() {
        webViewConfiguration.userContentController.removeAllUserScripts()
    }
}
