// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common

struct RemoteSettingsEngineIconRecordFields: Codable {
    let engineIdentifiers: [String]
    let imageSize: Int?

    static func empty() -> Self {
        return RemoteSettingsEngineIconRecordFields(engineIdentifiers: [], imageSize: nil)
    }
}

/// Convenience wrapper model for AS search engine icon records fetched from Remote Settings
struct RemoteSettingsEngineIconRecord {
    let id: String
    let engineIdentifiers: [String]
    let mimeType: String?
    let backingRecord: RemoteSettingsRecord

    init(record: RemoteSettingsRecord, logger: Logger = DefaultLogger.shared) {
        self.id = record.id

        let iconRecordFields: RemoteSettingsEngineIconRecordFields = {
            if let fieldData = record.fields.data(using: .utf8) {
                do {
                    return try JSONDecoder().decode(RemoteSettingsEngineIconRecordFields.self, from: fieldData)
                } catch {
                    logger.log("Decoding search icon record JSON failed: \(error)", level: .debug, category: .remoteSettings)
                }
            }
            return RemoteSettingsEngineIconRecordFields.empty()
        }()

        self.engineIdentifiers = iconRecordFields.engineIdentifiers
        self.mimeType = record.attachment?.mimetype
        self.backingRecord = record
    }
}
