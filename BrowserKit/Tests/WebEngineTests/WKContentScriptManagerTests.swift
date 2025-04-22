// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

@available(iOS 16.0, *)
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

    @MainActor
    func testAddContentGivenAddedTwiceThenOnlyAddOnce() async {
        let subject = createSubject()
        let session = await MockWKEngineSession()

        subject.addContentScript(script,
                                 name: MockWKContentScript.name(),
                                 forSession: session)
        subject.addContentScript(script,
                                 name: MockWKContentScript.name(),
                                 forSession: session)

        XCTAssertEqual(subject.scripts.count, 1)
    }

    func testAddContentGivenAddedThenCallsMessageHandlers() async {
        let subject = createSubject()
        let session = await MockWKEngineSession()

        await subject.addContentScript(script,
                                       name: MockWKContentScript.name(),
                                       forSession: session)

        XCTAssertEqual(script.scriptMessageHandlerNamesCalled, 1)
        guard let config = session.webView.engineConfiguration as? MockWKEngineConfiguration else {
            XCTFail("Failed to cast engine configuration in testAddContentGivenAddedThenCallsMessageHandlers")
            return
        }
        XCTAssertEqual(config.addInDefaultContentWorldCalled, 1)
        XCTAssertEqual(config.scriptNameAdded, "MockWKContentScriptHandler")
    }

    @MainActor
    func testAddContentToPageGivenAddedTwiceThenOnlyAddOnce() async {
        let subject = createSubject()
        let session = await MockWKEngineSession()

        subject.addContentScriptToPage(script,
                                       name: MockWKContentScript.name(),
                                       forSession: session)
        subject.addContentScriptToPage(script,
                                       name: MockWKContentScript.name(),
                                       forSession: session)

        XCTAssertEqual(subject.scripts.count, 1)
    }

    func testAddContentToPageGivenAddedThenCallsMessageHandlers() async {
        let subject = createSubject()
        let session = await MockWKEngineSession()

        await subject.addContentScriptToPage(script,
                                             name: MockWKContentScript.name(),
                                             forSession: session)

        XCTAssertEqual(script.scriptMessageHandlerNamesCalled, 1)
        guard let config = session.webView.engineConfiguration as? MockWKEngineConfiguration else {
            XCTFail("Failed to cast engine configuration in testAddContentToPageGivenAddedThenCallsMessageHandlers")
            return
        }
        XCTAssertEqual(config.addInPageContentWorldCalled, 1)
        XCTAssertEqual(config.scriptNameAdded, "MockWKContentScriptHandler")
    }

    func testUninstallGivenAScriptThenCallsDeinitAndMessageHandlerNames() async {
        let subject = createSubject()
        let session = await MockWKEngineSession()
        await subject.addContentScript(script,
                                       name: MockWKContentScript.name(),
                                       forSession: session)

        await subject.uninstall(session: session)

        XCTAssertEqual(script.scriptMessageHandlerNamesCalled, 2)
        XCTAssertEqual(script.prepareForDeinitCalled, 1)
    }

    // MARK: Helper

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> DefaultContentScriptManager {
        let subject = DefaultContentScriptManager()
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
