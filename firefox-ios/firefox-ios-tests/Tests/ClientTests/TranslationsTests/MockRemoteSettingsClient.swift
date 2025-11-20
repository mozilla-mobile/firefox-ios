// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

final class MockRemoteSettingsClient: RemoteSettingsClientProtocol, @unchecked Sendable {
    private let collectionNameValue: String
    private let records: [RemoteSettingsRecord]
    private let attachmentsById: [String: Data]
    private(set) var fetchedAttachmentIds: [String] = []

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
        fetchedAttachmentIds.append(record.id)
        return attachmentsById[record.id] ?? Data()
    }

    func getRecords(syncIfEmpty: Bool) -> [RemoteSettingsRecord]? {
        return records
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
}
