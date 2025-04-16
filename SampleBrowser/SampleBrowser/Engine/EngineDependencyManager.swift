// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebEngine

class EngineDependencyManager {
    let sessionDependencies: EngineSessionDependencies
    let engineDependencies: EngineDependencies
    let telemetryHandler = TelemetryHandler()

    init() {
        let parameters = WKWebviewParameters(blockPopups: false,
                                             isPrivate: false,
                                             autoPlay: .all,
                                             schemeHandler: WKInternalSchemeHandler())
        self.sessionDependencies = EngineSessionDependencies(webviewParameters: parameters,
                                                             telemetryProxy: telemetryHandler)

        let readerModeConfig = ReaderModeConfiguration(loadingText: "Loading",
                                                       loadingFailedText: "Loading failed",
                                                       loadOriginalText: "Loading",
                                                       readerModeErrorText: "Error")
        self.engineDependencies = EngineDependencies(readerModeConfiguration: readerModeConfig)
    }
}
