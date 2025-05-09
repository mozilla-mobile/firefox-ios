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
        DependencyHelperMock().bootstrapDependencies(injectedWindowManager: mockWindowManager)
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: MockTabManager(
                recentlyAccessedNormalTabs: [createTab(profile: profile)]
            )
        )
    }

    override func tearDown() {
        self.syncManager = nil
        self.profile = nil
        self.queue = nil
        self.mockWindowManager = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testTabDidGainFocus_doesntSyncWithoutAccount() {
        let expectation = XCTestExpectation(description: "sync is not called without an account")
        expectation.isInverted = true
        profile.hasSyncableAccountMock = false
        let subject = AccountSyncHandler(with: profile, queue: queue, onSyncCompleted: {
        })
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(profile.storeAndSyncTabsCalled, 0)
    }

    func testTabDidGainFocus_syncWithAccount() {
        let expectation = XCTestExpectation(description: "storeAndSyncTabs called after listed time of tab gaining focus")
        let subject = AccountSyncHandler(with: profile, debounceTime: 0.1, queue: queue, queueDelay: 0.1, onSyncCompleted: {
            expectation.fulfill()
        })
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(profile.storeAndSyncTabsCalled, 1)
    }

    func testTabDidGainFocus_multipleActions_executedAtMostOnce() {
        let expectation = XCTestExpectation(
            description: "storeAndSyncTabs only called once from multiple tab actions")
        let subject = AccountSyncHandler(
            with: profile, debounceTime: 0.1, queue: DispatchQueue.global(), queueDelay: 0.1, onSyncCompleted: {
                expectation.fulfill()
            })
        let tab = createTab(profile: profile)

        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(profile.storeAndSyncTabsCalled, 1)
    }

    func testTabDidGainFocus_multipleDebounce_withWithMultipleSyncs() {
        let expectation = XCTestExpectation(
            description: "storeAndSyncTabs called multiple times if outside of debounce time")
        expectation.expectedFulfillmentCount = 2
        let subject = AccountSyncHandler(
            with: profile, debounceTime: 0.1, queue: DispatchQueue.global(), queueDelay: 0.1, onSyncCompleted: {
                expectation.fulfill()
            })
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)
        subject.tabDidLoseFocus(tab)
        wait(1.0)
        subject.tabDidGainFocus(tab)
        subject.tabDidLoseFocus(tab)
        subject.tabDidGainFocus(tab)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(profile.storeAndSyncTabsCalled, 2)
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
