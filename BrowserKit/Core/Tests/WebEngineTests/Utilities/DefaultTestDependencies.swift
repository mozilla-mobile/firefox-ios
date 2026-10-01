// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import WebEngine

@MainActor
struct DefaultTestDependencies {
    var mockTelemetryProxy: MockEngineTelemetryProxy
    var webViewParameters = WKWebViewParameters(blockPopups: true,
                                                isPrivate: true,
                                                autoPlay: .all,
                                                schemeHandler: WKInternalSchemeHandler())

    init(mockTelemetryProxy: MockEngineTelemetryProxy = MockEngineTelemetryProxy()) {
        self.mockTelemetryProxy = mockTelemetryProxy
    }

    var sessionDependencies: EngineSessionDependencies {
        return EngineSessionDependencies(webviewParameters: webViewParameters,
                                         telemetryProxy: mockTelemetryProxy)
    }
}
