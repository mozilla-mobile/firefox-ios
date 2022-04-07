//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Account
import Storage
import Shared
@testable import Sync
import MozillaAppServices

import Foundation
import SwiftyJSON
import XCTest

import Glean

class MockSyncDelegate: SyncDelegate {
    func displaySentTab(for url: URL, title: String, from deviceName: String?) {
    }
}

class MockBrowserSyncManager: BrowserProfile.BrowserSyncManager {
    override func getProfileAndDeviceId() -> (MozillaAppServices.Profile, String) {
        return (MozillaAppServices.Profile(
            uid: "test",
            email: "test@test.test",
            displayName: nil,
            avatar: "",
            isDefaultAvatar: true
        ), "test")
    }
}

class GleanTelemetryTests: XCTestCase {
    override func setUpWithError() throws {
        Glean.shared.resetGlean(clearStores: true)
    }

    let profile = MockBrowserProfile(localName: "GleanTelemetryTests")

    func testSyncPingIsSentOnSyncOperation() throws {
        let syncManager = MockBrowserSyncManager(profile: profile)

        let syncPingWasSent = expectation(description: "The tempSync ping was sent")
        GleanMetrics.Pings.shared.tempSync.testBeforeNextSubmit { _ in
            XCTAssert(GleanMetrics.Sync.syncUuid.testHasValue())
            syncPingWasSent.fulfill()
        }

        _ = syncManager.syncNamedCollections(
            why: SyncReason.didLogin,
            names: ["tabs", "logins", "bookmarks", "history"]
        )

        waitForExpectations(timeout: 5.0)
    }
}

