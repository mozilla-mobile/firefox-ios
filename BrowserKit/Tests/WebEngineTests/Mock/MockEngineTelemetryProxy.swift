//
//  MockEngineTelemetryProxy.swift
//  BrowserKit
//
//  Created by Filippo Zazzeroni on 08.04.25.
//

@testable import WebEngine

class MockEngineTelemetryProxy: EngineTelemetryProxy {
    var lastTelemetryEvent: EngineTelemetryEvent?
    var handleTelemetryCalled = 0

    func handleTelemetry(event: EngineTelemetryEvent) {
        handleTelemetryCalled += 1
        lastTelemetryEvent = event
    }
}
