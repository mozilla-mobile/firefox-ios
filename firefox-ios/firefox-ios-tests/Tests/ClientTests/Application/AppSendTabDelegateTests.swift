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
        super.tearDown()
        self.applicationStateProvider = nil
        self.applicationHelper = nil
    }

    @MainActor
    func testOpenSendTabs_inactiveState_doesntCallDeeplink() {
        applicationStateProvider.applicationState = .inactive
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 0)
    }

    @MainActor
    func testOpenSendTabs_backgroundState_doesntCallDeeplink() {
        applicationStateProvider.applicationState = .background
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 0)
    }

    @MainActor
    func testOpenSendTabs_activeWithOneURL_callsDeeplink() {
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 1)
        let expectedURL = URL(string: URL.mozInternalScheme + "://open-url?url=\(url)")!
        XCTAssertEqual(applicationHelper.lastOpenURL, expectedURL)
    }

    @MainActor
    func testOpenSendTabs_activeWithMultipleURLs_callsDeeplink() {
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        subject.openSendTabs(for: [url, url, url])

        XCTAssertEqual(applicationHelper.openURLCalled, 3)
    }

    // MARK: - Close Remote Tabs Tests
    func testCloseSendTabs_activeWithOneURL_callsDeeplink() async {
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        let task = Task {
            subject.closeTabs(for: [url])
        }
        await task.value
        XCTAssertEqual(applicationHelper.closeTabsCalled, 1)
    }

    func testCloseSendTabs_activeWithMultipleURLs_callsDeeplink() async {
        let url1 = URL(string: "https://example.com")!
        let url2 = URL(string: "https://example.com/1")!
        let url3 = URL(string: "https://example.com/2")!
        let subject = createSubject()
        let task = Task {
            subject.closeTabs(for: [url1, url2, url3])
        }
        await task.value
        XCTAssertEqual(applicationHelper.closeTabsCalled, 1)
    }

    // MARK: - Helper methods

    func createSubject() -> AppFxACommandsDelegate {
        let subject = AppFxACommandsDelegate(app: applicationStateProvider,
                                             applicationHelper: applicationHelper)
        trackForMemoryLeaks(subject)
        return subject
    }
}

// MARK: MockApplicationStateProvider
final class MockApplicationStateProvider: ApplicationStateProvider {
    var applicationState: UIApplication.State = .active
}
