// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common

/// Convenience wrapper model for AS search engine icon records fetched from Remote Settings
struct ASSearchEngineIconRecord {
    let id: String
    let engineIdentifiers: [String]
    let mimeType: String?
    let backingRecord: RemoteSettingsRecord

    init(record: RemoteSettingsRecord, logger: Logger = DefaultLogger.shared) {
        self.id = record.id

        let iconRecordFields: ASSearchEngineIconRecordFields = {
            guard let fieldData = record.fields.data(using: .utf8) else { return ASSearchEngineIconRecordFields.empty() }
            do {
                return try JSONDecoder().decode(ASSearchEngineIconRecordFields.self, from: fieldData)
            } catch {
                logger.log("Decoding search icon record JSON failed: \(error)", level: .debug, category: .remoteSettings)
            }
            return ASSearchEngineIconRecordFields.empty()
        }()

        self.engineIdentifiers = iconRecordFields.engineIdentifiers
        self.mimeType = record.attachment?.mimetype
        self.backingRecord = record
    }
}

/// Convenience model for capturing JSON search engine identifiers from `search-config-icons` RS collection
struct ASSearchEngineIconRecordFields: Codable {
    let engineIdentifiers: [String]
    let imageSize: Int?

    static func empty() -> Self {
        return ASSearchEngineIconRecordFields(engineIdentifiers: [], imageSize: nil)
    }
}
