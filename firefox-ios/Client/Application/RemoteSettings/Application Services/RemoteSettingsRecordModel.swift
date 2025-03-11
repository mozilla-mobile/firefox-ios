// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

struct RemoteSettingsEngineIconRecordFields: Codable {
    let engineIdentifiers: [String]
    let imageSize: Int?
}

struct RemoteSettingsEngineIconRecord {
    let id: String
    let engineIdentifiers: [String]
    let mimeType: String?
    let backingRecord: RemoteSettingsRecord

    init(record: RemoteSettingsRecord) {
        self.id = record.id


        let iconRecordFields: RemoteSettingsEngineIconRecordFields = {
            if let fieldData = record.fields.data(using: .utf8) {
                do {
                    return try JSONDecoder().decode(RemoteSettingsEngineIconRecordFields.self, from: fieldData)
                } catch {
                    print("DBG: Failed to decode JSON: \(error)")
                    fatalError()
                }
            }
            fatalError()
        }()

        self.engineIdentifiers = iconRecordFields.engineIdentifiers
        self.mimeType = record.attachment?.mimetype
        self.backingRecord = record
    }
}
