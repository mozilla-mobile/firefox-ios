// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common

@testable import Client

class AccountSyncHandlerTests: XCTestCase {
    private var profile: MockProfile!
    private var syncManager: ClientSyncManagerSpy!
    private var queue: MockDispatchQueue!
    private var mockWindowManager: MockWindowManager!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        self.syncManager = profile.syncManager as? ClientSyncManagerSpy
        self.queue = MockDispatchQueue()
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: MockTabManager(
                recentlyAccessedNormalTabs: [createTab(profile: profile)]
            )
        )
        DependencyHelperMock().bootstrapDependencies(injectedWindowManager: mockWindowManager)
    }

    override func tearDown() {
        super.tearDown()
        self.syncManager = nil
        self.profile = nil
        self.queue = nil
        self.mockWindowManager = nil
        DependencyHelperMock().reset()
    }

    func testTabDidGainFocus_doesntSyncWithoutAccount() {
        profile.hasSyncableAccountMock = false
        let subject = AccountSyncHandler(with: profile, queue: queue)
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)

        XCTAssertEqual(profile.storeAndSyncTabsCalled, 0)
    }

    func testTabDidGainFocus_syncWithAccount() {
        let subject = AccountSyncHandler(with: profile, debounceTime: 0.1, queue: queue, queueDelay: 0.1)
        let tab = createTab(profile: profile)
        let expectation = XCTestExpectation(description: "storeAndSyncTabs called after listed time of tab gaining focus")
        subject.tabDidGainFocus(tab)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            XCTAssertEqual(profile.storeAndSyncTabsCalled, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testTabDidGainFocus_multipleActions_executedAtMostOnce() {
        let delay = 0.5
        let stepWaitTime = 1.0
        let subject = AccountSyncHandler(with: profile, debounceTime: delay, queue: DispatchQueue.global(), queueDelay: 0.1)
        let tab = createTab(profile: profile)

        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)

        let expectation = XCTestExpectation(description: "storeAndSyncTabs only called once from multiple actions")
        DispatchQueue.main.asyncAfter(deadline: .now() + stepWaitTime) { [self] in
            XCTAssertEqual(profile.storeAndSyncTabsCalled, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: stepWaitTime * 2)
    }

    func testTabDidGainFocus_multipleThrottle_withWaitSyncOnce() {
        let subject = AccountSyncHandler(with: profile, debounceTime: 0.1, queue: DispatchQueue.global(), queueDelay: 0.1)
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)
        subject.tabDidLoseFocus(tab)
        subject.tabDidGainFocus(tab)
        subject.tabDidLoseFocus(tab)
        subject.tabDidGainFocus(tab)
        wait(0.5)

        XCTAssertEqual(profile.storeAndSyncTabsCalled, 1)
    }
}

// MARK: - Helper methods
private extension AccountSyncHandlerTests {
    func createTab(profile: MockProfile,
                   urlString: String? = "www.website.com") -> Tab {
        let tab = Tab(profile: profile, windowUUID: windowUUID)

        if let urlString = urlString {
            tab.url = URL(string: urlString)!
        }
        return tab
    }
}
