// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import MozillaAppServices

// TODO: Replace direct remote settings with the mock
class RemoteSettingsUtilTests: XCTestCase {
    var remoteSettingsUtil: RemoteSettingsUtil!
    var defaultCollection: RemoteCollection = .searchTelemetry

    override func setUp() {
        super.setUp()
        remoteSettingsUtil = RemoteSettingsUtil(bucket: .defaultBucket, collection: self.defaultCollection)
    }

    override func tearDown() {
        remoteSettingsUtil = nil
        super.tearDown()
    }

    func testFetchLocalRecords() {
        let testRecord = RemoteSettingsRecord(id: "1", lastModified: 123456, deleted: false, attachment: nil, fields: "{}")
        remoteSettingsUtil.saveRemoteSettingsRecord([testRecord], forKey: "testKey")

        let records = remoteSettingsUtil.fetchLocalRecords(forKey: "testKey")

        XCTAssertNotNil(records)
        XCTAssertEqual(records?.count, 1)
        XCTAssertEqual(records?.first?.id, "1")
    }
}
