// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import MozillaAppServices

final class ASAdBlockerListFetcherTests: XCTestCase {
    private let adBlockerListJSON = """
    [{"trigger":{"url-filter":".*ads.*"},"action":{"type":"block"}}]
    """

    func testFetchAdBlockerListJSON_returnsAttachmentJSON_whenRecordExists() async {
        let record = makeRecord(id: ASAdBlockerListFetcher.adBlockerRecordID)
        let client = MockRemoteSettingsClient(
            records: [record],
            attachmentsById: [record.id: Data(adBlockerListJSON.utf8)]
        )
        let subject = ASAdBlockerListFetcher(clientProvider: { client })

        let json = await subject.fetchAdBlockerListJSON()

        XCTAssertEqual(json, adBlockerListJSON)
        XCTAssertEqual(client.fetchedAttachmentIds, [ASAdBlockerListFetcher.adBlockerRecordID])
    }

    func testFetchAdBlockerListJSON_returnsNil_whenRecordMissing() async {
        let otherRecord = makeRecord(id: "some-other-list")
        let client = MockRemoteSettingsClient(
            records: [otherRecord],
            attachmentsById: [otherRecord.id: Data(adBlockerListJSON.utf8)]
        )
        let subject = ASAdBlockerListFetcher(clientProvider: { client })

        let json = await subject.fetchAdBlockerListJSON()

        XCTAssertNil(json)
        XCTAssertTrue(client.fetchedAttachmentIds.isEmpty)
    }

    func testFetchAdBlockerListJSON_returnsNil_whenClientIsNil() async {
        let subject = ASAdBlockerListFetcher(clientProvider: { nil })

        let json = await subject.fetchAdBlockerListJSON()

        XCTAssertNil(json)
    }

    private func makeRecord(id: String) -> RemoteSettingsRecord {
        return RemoteSettingsRecord(
            id: id,
            lastModified: 0,
            deleted: false,
            attachment: nil,
            fields: "{}"
        )
    }
}
