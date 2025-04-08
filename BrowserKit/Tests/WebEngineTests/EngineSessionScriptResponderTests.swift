//
//  EngineSessionScriptResponderTests.swift
//  BrowserKit
//
//  Created by Filippo Zazzeroni on 08.04.25.
//

import XCTest
@testable import WebEngine

@available(iOS 16, *)
class EngineSessionScriptResponderTests: XCTestCase {
    private var session: MockWKEngineSession!

    override func setUp() {
        super.setUp()
        session = MockWKEngineSession()
    }

    override func tearDown() {
        session = nil
        super.tearDown()
    }

    func testContentScriptDidSendEventRespondsToJavaScriptCommand() {
        let subject = createSubject()

        subject.contentScriptDidSendEvent(.requestJavascriptCommand(command: "", scope: nil))

        XCTAssertEqual(session.callJavascriptMethodCalled, 1)
    }

    func testContentScriptDidSendEventRespondsToTrackAdsClickedOnPage() throws {
        let provider = "mockprovider"
        let subject = createSubject()
        
        subject.contentScriptDidSendEvent(.trackedAdsClickedOnPage(provider: provider))

        let event = try XCTUnwrap(session.mockTelemetryProxy.lastTelemetryEvent)
        XCTAssertEqual(session.mockTelemetryProxy.handleTelemetryCalled, 1)
        XCTAssertEqual(event, .trackAdsClickedOnPage(providerName: provider))
    }

    func testContentScriptDidSendEventRespondsToTracksAdsFoundOnPage() throws {
        let provider = "mockprovider"
        let urls = ["test.url"]
        let subject = createSubject()

        subject.contentScriptDidSendEvent(.trackedAdsFoundOnPage(provider: provider, urls: urls))

        let event = try XCTUnwrap(session.mockTelemetryProxy.lastTelemetryEvent)
        XCTAssertEqual(session.mockTelemetryProxy.handleTelemetryCalled, 1)
        XCTAssertEqual(event, .trackAdsFoundOnPage(providerName: provider, adUrls: urls))
    }

    private func createSubject() -> EngineSessionScriptResponder {
        let subject = EngineSessionScriptResponder()
        subject.session = session
        trackForMemoryLeaks(subject)

        return subject
    }
}
