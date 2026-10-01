// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import WebEngine

class MockEngineTelemetryProxy: EngineTelemetryProxy {
    var lastTelemetryEvent: EngineTelemetryEvent?
    var handleTelemetryCalled = 0

    func handleTelemetry(event: EngineTelemetryEvent) {
        handleTelemetryCalled += 1
        lastTelemetryEvent = event
    }
}
