// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import WebEngine

class MockWKContentScriptManager: NSObject, WKContentScriptManager {
    var scripts = [String: WKContentScript]()
    var addContentScriptCalled = 0
    var addContentScriptToPageCalled = 0
    var addContentScriptToCustomWorldCalled = 0
    var uninstallCalled = 0
    var userContentControllerCalled = 0

    var savedContentScriptNames = [String]()
    var savedContentScriptPageNames = [String]()
    var savedContentScriptCustomWorldNames = [String]()

    func addContentScript(_ script: WKContentScript,
                          name: String,
                          forSession session: WKEngineSession) {
        scripts[name] = script
        savedContentScriptNames.append(name)
        addContentScriptCalled += 1
    }

    func addContentScriptToPage(_ script: WKContentScript,
                                name: String,
                                forSession session: WKEngineSession) {
        scripts[name] = script
        savedContentScriptPageNames.append(name)
        addContentScriptToPageCalled += 1
    }

    func addContentScriptToCustomWorld(_ script: WKContentScript,
                                       name: String,
                                       forSession session: WKEngineSession) {
        scripts[name] = script
        savedContentScriptCustomWorldNames.append(name)
        addContentScriptToCustomWorldCalled += 1
    }

    func uninstall(session: WKEngineSession) {
        uninstallCalled += 1
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        userContentControllerCalled += 1
    }

    /// Helper method to call an injected content script `userContentController` method.
    func callScriptUserContentController(script: String, message: Any) {
        guard let contentScript = scripts[script] else { return }
        contentScript.userContentController(didReceiveMessage: message)
    }
}
