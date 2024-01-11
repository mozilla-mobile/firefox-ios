// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class WKContentScriptManagerTests: XCTestCase {
    private var script: MockWKContentScript!

    override func setUp() {
        super.setUp()
        script = MockWKContentScript()
    }

    override func tearDown() {
        super.tearDown()
        script = nil
    }

    func testAddContentGivenAddedTwiceThenOnlyAddOnce() {
        let subject = createSubject()
        let session = MockWKEngineSession()

        subject.addContentScript(script,
                                 name: MockWKContentScript.name(),
                                 forSession: session)
        subject.addContentScript(script,
                                 name: MockWKContentScript.name(),
                                 forSession: session)

        XCTAssertEqual(subject.scripts.count, 1)
    }

    func testAddContentGivenAddedThenCallsMessageHandlers() {
        let subject = createSubject()
        let session = MockWKEngineSession()

        subject.addContentScript(script,
                                 name: MockWKContentScript.name(),
                                 forSession: session)

        XCTAssertEqual(script.scriptMessageHandlerNamesCalled, 1)
        // FXIOS-8115 Test that configuration has the scripts
    }

    func testAddContentToPageGivenAddedTwiceThenOnlyAddOnce() {
        let subject = createSubject()
        let session = MockWKEngineSession()

        subject.addContentScriptToPage(script,
                                       name: MockWKContentScript.name(),
                                       forSession: session)
        subject.addContentScriptToPage(script,
                                       name: MockWKContentScript.name(),
                                       forSession: session)

        XCTAssertEqual(subject.scripts.count, 1)
    }

    func testAddContentToPageGivenAddedThenCallsMessageHandlers() {
        let subject = createSubject()
        let session = MockWKEngineSession()

        subject.addContentScriptToPage(script,
                                       name: MockWKContentScript.name(),
                                       forSession: session)

        XCTAssertEqual(script.scriptMessageHandlerNamesCalled, 1)
        // FXIOS-8115 Test that configuration has the scripts
    }

    func testUninstallGivenAScriptThenCallsDeinitAndMessageHandlerNames() {
        let subject = createSubject()
        let session = MockWKEngineSession()
        subject.addContentScript(script,
                                 name: MockWKContentScript.name(),
                                 forSession: session)

        subject.uninstall(session: session)

        XCTAssertEqual(script.scriptMessageHandlerNamesCalled, 2)
        XCTAssertEqual(script.prepareForDeinitCalled, 1)
    }

    // MARK: Helper

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> DefaultContentScriptManager {
        let subject = DefaultContentScriptManager()
        // FXIOS-8115 Leaks caused by WKWebViewConfiguration
//        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
