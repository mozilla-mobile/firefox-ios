// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class PrintContentScriptTests: XCTestCase {
    private var session: MockEngineSession!

    override func setUp() {
        super.setUp()
        session = MockEngineSession()
    }

    override func tearDown() {
        session = nil
        super.tearDown()
    }

    func test_userContentController_withEmptyMessage_returnsDelegateCalled() {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [])

        XCTAssertEqual(session.viewPrintFormatterCalled, 1)
    }

    func test_userContentController_withMessage_returnsProperDelegateCall() {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: ["any message"])

        XCTAssertEqual(session.viewPrintFormatterCalled, 1)
    }

    private func createSubject() -> PrintContentScript {
        let subject = PrintContentScript(session: session)
        trackForMemoryLeaks(subject)
        return subject
    }
}
