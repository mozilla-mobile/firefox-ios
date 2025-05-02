// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebEngine

class EngineDependencyManager {
    let sessionDependencies: EngineSessionDependencies
    let engineDependencies: EngineDependencies
    let telemetryHandler = TelemetryHandler()

    init() {
        let parameters = WKWebViewParameters(blockPopups: false,
                                             isPrivate: false,
                                             autoPlay: .all,
                                             schemeHandler: WKInternalSchemeHandler(),
                                             pullRefreshType: PullRefreshView.self)
        self.sessionDependencies = EngineSessionDependencies(webviewParameters: parameters,
                                                             readerModeDelegate: ReaderModeDelegate(),
                                                             telemetryProxy: telemetryHandler)

        let readerModeConfig = ReaderModeConfiguration(loadingText: "Loading",
                                                       loadingFailedText: "Loading failed",
                                                       loadOriginalText: "Loading",
                                                       readerModeErrorText: "Error")
        self.engineDependencies = EngineDependencies(readerModeConfiguration: readerModeConfig)
    }
}

class ReaderModeDelegate: WKReaderModeDelegate {
    func readerMode(_ readerMode: ReaderModeStyleSetter,
                    didChangeReaderModeState state: ReaderModeState,
                    forSession session: EngineSession) {
        // TODO: FXIOS-11373 - finish handling reader mode in WebEngine - Sample browser should react to reader mode
    }

    func readerMode(_ readerMode: ReaderModeStyleSetter,
                    didDisplayReaderizedContentForSession session: EngineSession) {
        // TODO: FXIOS-11373 - finish handling reader mode in WebEngine - Sample browser should react to reader mode
    }

    func readerMode(_ readerMode: ReaderModeStyleSetter,
                    didParseReadabilityResult readabilityResult: ReadabilityResult,
                    forSession session: EngineSession) {
        // TODO: FXIOS-11373 - finish handling reader mode in WebEngine - Sample browser should react to reader mode
    }
}
