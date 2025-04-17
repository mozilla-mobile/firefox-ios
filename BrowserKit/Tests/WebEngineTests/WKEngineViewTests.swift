// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

@available(iOS 16.0, *)
final class WKEngineViewTests: XCTestCase {
    private var engineSession: WKEngineSession!

    override func setUp() async throws {
        try await super.setUp()
        engineSession = await MockWKEngineSession()
    }

    override func tearDown() {
        engineSession = nil
        super.tearDown()
    }

    func testRenderSetsIsActiveTrue() {
        let subject = createSubject()

        subject.render(session: engineSession)

        XCTAssertTrue(engineSession.isActive)
    }

    @MainActor
    func testRemoveSetsIsActiveFalse() async {
        let subject = createSubject()
        let newEngineSession = await MockWKEngineSession()

        subject.render(session: engineSession)
        subject.render(session: newEngineSession)

        XCTAssertFalse(engineSession.isActive)
        XCTAssertTrue(newEngineSession.isActive)
    }

    func createSubject() -> WKEngineView {
        let subject = WKEngineView(frame: CGRect.zero)
        return subject
    }
}
