// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Sync

class RustSyncManagerAPITests: XCTestCase {
    var rustSyncManagerApi: RustSyncManagerAPI!

    func testReportSyncTelemetry() {
        self.rustSyncManagerApi = RustSyncManagerAPI()
        let expectation = expectation(description: "Completed telemetry reporting")
        var actual = ""
        let expected = "The operation couldn’t be completed. (MozillaAppServices.TelemetryJSONError error 0.)"
        let invalidSyncResult = SyncResult(status: ServiceStatus.ok,
                                           successful: [],
                                           failures: [:],
                                           persistedState: "",
                                           declined: nil,
                                           nextSyncAllowedAt: nil,
                                           telemetryJson: "{\"version\": \"invalidVersion\"}")
        self.rustSyncManagerApi
            .reportSyncTelemetry(syncResult: invalidSyncResult) { description in
                actual = description
                expectation.fulfill()
            }

        waitForExpectations(timeout: 5)
        XCTAssertEqual(actual, expected)
    }
}
