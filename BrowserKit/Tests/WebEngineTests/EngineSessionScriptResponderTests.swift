// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

@available(iOS 16, *)
class EngineSessionScriptResponderTests: XCTestCase {
    private var session: MockWKEngineSession!

    override func setUp() async throws {
        try await super.setUp()
        session = await MockWKEngineSession()
    }

    override func tearDown() {
        session = nil
        super.tearDown()
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
