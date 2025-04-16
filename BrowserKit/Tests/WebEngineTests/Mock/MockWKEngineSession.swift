// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import WebEngine

@available(iOS 16.0, *)
class MockWKEngineSession: WKEngineSession {
    let webviewProvider = MockWKWebViewProvider()
    let mockTelemetryProxy = MockEngineTelemetryProxy()
    var callJavascriptMethodCalled = 0

    init() {
        let defaultDependencies =  DefaultTestDependencies(mockTelemetryProxy: mockTelemetryProxy)
        super.init(userScriptManager: MockWKUserScriptManager(),
                   dependencies: defaultDependencies.sessionDependencies,
                   configurationProvider: MockWKEngineConfigurationProvider(),
                   webViewProvider: webviewProvider,
                   contentScriptManager: MockWKContentScriptManager())!
    }

    override func callJavascriptMethod(_ method: String, scope: String?) {
        callJavascriptMethodCalled += 1
    }
}
