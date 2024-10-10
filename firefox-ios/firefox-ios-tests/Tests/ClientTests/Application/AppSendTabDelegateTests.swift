// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class AppFxACommandsTests: XCTestCase {
    private var applicationStateProvider: MockApplicationStateProvider!
    private var applicationHelper: MockApplicationHelper!

    override func setUp() {
        super.setUp()
        self.applicationStateProvider = MockApplicationStateProvider()
        self.applicationHelper = MockApplicationHelper()
    }

    override func tearDown() {
        self.applicationStateProvider = nil
        self.applicationHelper = nil
        super.tearDown()
    }

    func testOpenSendTabs_inactiveState_doesntCallDeeplink() {
        applicationStateProvider.applicationState = .inactive
        let url = URL(string: "https://mozilla.com", invalidCharacters: false)!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 0)
    }

    func testOpenSendTabs_backgroundState_doesntCallDeeplink() {
        applicationStateProvider.applicationState = .background
        let url = URL(string: "https://mozilla.com", invalidCharacters: false)!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 0)
    }

    func testOpenSendTabs_activeWithOneURL_callsDeeplink() {
        let url = URL(string: "https://mozilla.com", invalidCharacters: false)!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 1)
        let expectedURL = URL(string: URL.mozInternalScheme + "://open-url?url=\(url)")!
        XCTAssertEqual(applicationHelper.lastOpenURL, expectedURL)
    }

    func testOpenSendTabs_activeWithMultipleURLs_callsDeeplink() {
        let url = URL(string: "https://mozilla.com", invalidCharacters: false)!
        let subject = createSubject()
        subject.openSendTabs(for: [url, url, url])

        XCTAssertEqual(applicationHelper.openURLCalled, 3)
    }

    // MARK: - Close Remote Tabs Tests
    func testCloseSendTabs_activeWithOneURL_callsDeeplink() async {
        let url = URL(string: "https://mozilla.com", invalidCharacters: false)!
        let subject = createSubject()
        let expectation = XCTestExpectation(description: "Close tabs called")
        subject.closeTabs(for: [url])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
            XCTAssertEqual(self.applicationHelper.closeTabsCalled, 1)
        }
        await fulfillment(of: [expectation])
    }

    func testCloseSendTabs_activeWithMultipleURLs_callsDeeplink() async {
        let url1 = URL(string: "https://example.com", invalidCharacters: false)!
        let url2 = URL(string: "https://example.com/1", invalidCharacters: false)!
        let url3 = URL(string: "https://example.com/2", invalidCharacters: false)!
        let subject = createSubject()
        let expectation = XCTestExpectation(description: "Close tabs called multiple times")
        subject.closeTabs(for: [url1, url2, url3])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
            XCTAssertEqual(self.applicationHelper.closeTabsCalled, 1)
        }
        await fulfillment(of: [expectation])
    }

    // MARK: - Helper methods

    func createSubject() -> AppFxACommandsDelegate {
        let subject = AppFxACommandsDelegate(app: applicationStateProvider,
                                             applicationHelper: applicationHelper,
                                             mainQueue: MockDispatchQueue())
        trackForMemoryLeaks(subject)
        return subject
    }
}

// MARK: MockApplicationStateProvider
class MockApplicationStateProvider: ApplicationStateProvider {
    var applicationState: UIApplication.State = .active
}
