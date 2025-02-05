// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class WKEngineTests: XCTestCase {
    private var userScriptManager: MockWKUserScriptManager!

    override func setUp() {
        super.setUp()
        userScriptManager = MockWKUserScriptManager()
    }

    override func tearDown() {
        super.tearDown()
        userScriptManager = nil
    }

    func testCreateViewThenCreatesView() {
        let subject = createSubject()
        XCTAssertNotNil(subject.createView())
    }

    func testCreateSessionThenCreatesSession() throws {
        let subject = createSubject()

        let session = try XCTUnwrap(subject.createSession(dependencies: nil))
        XCTAssertNotNil(session)
    }

    // MARK: Helper

    func createSubject() -> WKEngine {
        let subject = WKEngine(userScriptManager: userScriptManager)
        trackForMemoryLeaks(subject)
        return subject
    }
}
