// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import WebEngine

class MockWKEngineConfiguration: WKEngineConfiguration {
    var scriptNameAdded: String?
    var addUserScriptCalled = 0
    var addInDefaultContentWorldCalled = 0
    var addInPageContentWorldCalled = 0
    var removeScriptMessageHandlerCalled = 0
    var removeAllUserScriptsCalled = 0

    func addUserScript(_ userScript: WKUserScript) {
        addUserScriptCalled += 1
    }

    func addInDefaultContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        scriptNameAdded = name
        addInDefaultContentWorldCalled += 1
    }

    func addInPageContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        scriptNameAdded = name
        addInPageContentWorldCalled += 1
    }

    func removeScriptMessageHandler(forName name: String) {
        removeScriptMessageHandlerCalled += 1
    }

    func removeAllUserScripts() {
        removeAllUserScriptsCalled += 1
    }
}
