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

    func testFetchAdBlockerListJSON_selectsMatchingRecord_amongSeveral() async {
        let target = makeRecord(id: ASAdBlockerListFetcher.adBlockerRecordID)
        let client = MockRemoteSettingsClient(
            records: [makeRecord(id: "before"), target, makeRecord(id: "after")],
            attachmentsById: [target.id: Data(adBlockerListJSON.utf8)]
        )
        let subject = ASAdBlockerListFetcher(clientProvider: { client })

        let json = await subject.fetchAdBlockerListJSON()

        XCTAssertEqual(json, adBlockerListJSON)
        XCTAssertEqual(client.fetchedAttachmentIds, [ASAdBlockerListFetcher.adBlockerRecordID])
    }

    func testFetchAdBlockerListJSON_returnsNil_whenRecordsEmpty() async {
        let client = MockRemoteSettingsClient(records: [])
        let subject = ASAdBlockerListFetcher(clientProvider: { client })

        let json = await subject.fetchAdBlockerListJSON()

        XCTAssertNil(json)
        XCTAssertTrue(client.fetchedAttachmentIds.isEmpty)
    }

    func testFetchAdBlockerListJSON_returnsNil_whenGetRecordsReturnsNil() async {
        let client = MockRemoteSettingsClient(records: [makeRecord(id: ASAdBlockerListFetcher.adBlockerRecordID)])
        client.returnsNilRecords = true
        let subject = ASAdBlockerListFetcher(clientProvider: { client })

        let json = await subject.fetchAdBlockerListJSON()

        XCTAssertNil(json)
        XCTAssertTrue(client.fetchedAttachmentIds.isEmpty)
    }

    func testFetchAdBlockerListJSON_returnsNil_whenGetAttachmentThrows() async {
        let record = makeRecord(id: ASAdBlockerListFetcher.adBlockerRecordID)
        let client = MockRemoteSettingsClient(records: [record])
        client.attachmentError = TestError.boom
        let subject = ASAdBlockerListFetcher(clientProvider: { client })

        let json = await subject.fetchAdBlockerListJSON()

        XCTAssertNil(json)
    }

    func testFetchAdBlockerListJSON_returnsNil_whenAttachmentIsNotValidUTF8() async {
        let record = makeRecord(id: ASAdBlockerListFetcher.adBlockerRecordID)
        let client = MockRemoteSettingsClient(
            records: [record],
            attachmentsById: [record.id: Data([0xFF, 0xFE, 0xFF])]
        )
        let subject = ASAdBlockerListFetcher(clientProvider: { client })

        let json = await subject.fetchAdBlockerListJSON()

        XCTAssertNil(json)
    }

    func testFetchAdBlockerListJSON_returnsNil_whenMatchedRecordHasEmptyAttachment() async {
        // Record matches but has no attachment mapping: the mock returns empty `Data`, which
        // decodes to "" — the fetcher must treat that as a failure rather than an empty list.
        let record = makeRecord(id: ASAdBlockerListFetcher.adBlockerRecordID)
        let client = MockRemoteSettingsClient(records: [record], attachmentsById: [:])
        let subject = ASAdBlockerListFetcher(clientProvider: { client })

        let json = await subject.fetchAdBlockerListJSON()

        XCTAssertNil(json)
    }

    @MainActor
    func testFetchAdBlockerListJSON_runsBlockingCallsOffTheMainThread() async {
        let record = makeRecord(id: ASAdBlockerListFetcher.adBlockerRecordID)
        let client = MockRemoteSettingsClient(
            records: [record],
            attachmentsById: [record.id: Data(adBlockerListJSON.utf8)]
        )
        let subject = ASAdBlockerListFetcher(clientProvider: { client })

        _ = await subject.fetchAdBlockerListJSON()

        XCTAssertEqual(client.getRecordsRanOnMainThread, false)
        XCTAssertEqual(client.getAttachmentRanOnMainThread, false)
    }

    private enum TestError: Error { case boom }

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
