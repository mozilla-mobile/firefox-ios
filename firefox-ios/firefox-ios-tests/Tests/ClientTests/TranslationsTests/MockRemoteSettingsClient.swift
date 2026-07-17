// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

final class MockRemoteSettingsClient: RemoteSettingsClientProtocol, @unchecked Sendable {
    var resetStorageWasCalled = false
    private let collectionNameValue: String
    private let records: [RemoteSettingsRecord]
    private let attachmentsById: [String: Data]
    private(set) var fetchedAttachmentIds: [String] = []

    /// When true, `getRecords` returns nil (models the "not synced / no records" case).
    var returnsNilRecords = false
    /// When set, `getAttachment` throws this instead of returning data.
    var attachmentError: Error?
    /// Captures whether the most recent `getRecords` call ran on the main thread.
    private(set) var getRecordsRanOnMainThread: Bool?
    /// Captures whether the most recent `getAttachment` call ran on the main thread.
    private(set) var getAttachmentRanOnMainThread: Bool?

    init(
        collectionName: String = "test-collection",
        records: [RemoteSettingsRecord] = [],
        attachmentsById: [String: Data] = [:]
    ) {
        self.collectionNameValue = collectionName
        self.records = records
        self.attachmentsById = attachmentsById
    }

    func collectionName() -> String {
        return collectionNameValue
    }

    func getAttachment(record: RemoteSettingsRecord) throws -> Data {
        getAttachmentRanOnMainThread = Thread.isMainThread
        fetchedAttachmentIds.append(record.id)
        if let attachmentError { throw attachmentError }
        return attachmentsById[record.id] ?? Data()
    }

    func getRecords(syncIfEmpty: Bool) -> [RemoteSettingsRecord]? {
        getRecordsRanOnMainThread = Thread.isMainThread
        return returnsNilRecords ? nil : records
    }

    func getRecordsMap(syncIfEmpty: Bool) -> [String: RemoteSettingsRecord]? {
        return Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
    }

    func shutdown() {
        // no-op for tests for now
    }

    func sync() throws {
        // no-op for tests for now
    }

    func getLastModifiedTimestamp() -> UInt64? {
        // This is currently not being used in tests
        return 0
    }

    func resetStorage() throws {
        resetStorageWasCalled = true
    }
}
