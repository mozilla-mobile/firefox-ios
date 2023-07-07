// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit

@testable import Client

class AccountSyncHandlerTests: XCTestCase {
    private var profile: MockProfile!
    private var syncManager: ClientSyncManagerSpy!
    private var queue: MockDispatchQueue!

    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        self.syncManager = profile.syncManager as? ClientSyncManagerSpy
        self.queue = MockDispatchQueue()
    }

    override func tearDown() {
        super.tearDown()
        self.syncManager = nil
        self.profile = nil
        self.queue = nil
    }

    func testTabDidGainFocus_doesntSyncWithoutAccount() {
        profile.hasSyncableAccountMock = false
        let subject = AccountSyncHandler(with: profile, queue: queue)
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)

        XCTAssertEqual(syncManager.syncNamedCollectionsCalled, 0)
    }

    func testTabDidGainFocus_syncWithAccount() {
        let subject = AccountSyncHandler(with: profile, queue: queue)
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)

        XCTAssertEqual(syncManager.syncNamedCollectionsCalled, 1)
    }

    func testTabDidGainFocus_highThrottleTime_doesntSync() {
        let subject = AccountSyncHandler(with: profile, throttleTime: 1000, queue: DispatchQueue.global())
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)

        XCTAssertEqual(syncManager.syncNamedCollectionsCalled, 0)
    }

    func testTabDidGainFocus_multipleThrottle_withoutWaitdoesntSync() {
        let subject = AccountSyncHandler(with: profile, throttleTime: 0.2, queue: DispatchQueue.global())
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)

        XCTAssertEqual(syncManager.syncNamedCollectionsCalled, 0)
    }

    func testTabDidGainFocus_multipleThrottle_withWaitSyncOnce() {
        let subject = AccountSyncHandler(with: profile, throttleTime: 0.2, queue: DispatchQueue.global())
        let tab = createTab(profile: profile)
        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)
        subject.tabDidGainFocus(tab)
        wait(0.5)

        XCTAssertEqual(syncManager.syncNamedCollectionsCalled, 1)
    }
}

// MARK: - Helper methods
private extension AccountSyncHandlerTests {
    func createTab(profile: MockProfile,
                   configuration: WKWebViewConfiguration = WKWebViewConfiguration(),
                   urlString: String? = "www.website.com") -> Tab {
        let tab = Tab(profile: profile, configuration: configuration)

        if let urlString = urlString {
            tab.url = URL(string: urlString)!
        }
        return tab
    }
}
