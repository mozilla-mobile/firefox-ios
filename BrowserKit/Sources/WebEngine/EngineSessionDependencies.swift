// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Dependencies injected during engine session creation that can be session specific.
public struct EngineSessionDependencies {
    var webviewParameters: WKWebViewParameters
    var telemetryProxy: EngineTelemetryProxy?
    weak var readerModeDelegate: WKReaderModeDelegate?

    public init(webviewParameters: WKWebViewParameters,
                readerModeDelegate: WKReaderModeDelegate? = nil,
                telemetryProxy: EngineTelemetryProxy? = nil) {
        self.webviewParameters = webviewParameters
        self.readerModeDelegate = readerModeDelegate
        self.telemetryProxy = telemetryProxy
    }
}

/// Dependencies that are global to the engine and isn't session specific.
public struct EngineDependencies {
    var readerModeConfiguration: ReaderModeConfiguration

    public init(readerModeConfiguration: ReaderModeConfiguration) {
        self.readerModeConfiguration = readerModeConfiguration
    }
}
