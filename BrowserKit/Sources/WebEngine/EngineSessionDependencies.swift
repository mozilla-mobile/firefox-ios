// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Dependencies injected during engine session creation.
public struct EngineSessionDependencies {
    var webviewParameters: WKWebviewParameters
    var telemetryProxy: EngineTelemetryProxy?

    public init(webviewParameters: WKWebviewParameters,
                telemetryProxy: EngineTelemetryProxy? = nil) {
        self.webviewParameters = webviewParameters
        self.telemetryProxy = telemetryProxy
    }
}
