// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Account
import Storage
import Shared
@testable import Sync
import MozillaAppServices

import Foundation
import XCTest

import Glean

class MockRustSyncManager: RustSyncManager { }

class GleanTelemetryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
        Glean.shared.enableTestingMode()

        RustFirefoxAccounts.startup(prefs: MockProfilePrefs()).uponQueue(.main) { _ in }
    }

    func testSyncPingIsSentOnSyncOperation() throws {
        let profile = MockBrowserProfile(localName: "GleanTelemetryTests")
        let syncManager = MockRustSyncManager(profile: profile)

        let syncPingWasSent = expectation(description: "The tempSync ping was sent")
        GleanMetrics.Pings.shared.tempSync.testBeforeNextSubmit { _ in
            XCTAssertNotNil(GleanMetrics.Sync.syncUuid.testGetValue())
            syncPingWasSent.fulfill()
        }

        _ = syncManager.syncNamedCollections(
            why: .enabledChange,
            names: ["tabs", "logins", "bookmarks", "history", "clients"]
        )

        waitForExpectations(timeout: 5.0)
    }
}
