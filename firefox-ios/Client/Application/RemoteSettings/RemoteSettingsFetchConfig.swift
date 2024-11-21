// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct RemoteSettingsFetchConfig: Codable, Equatable {
    let collections: [Collection]

    struct Collection: Codable, Equatable {
        let name: String
        let url: String
        var file: String?
        let bucketID: String
        let collectionID: String
        var fetchAttachments: Bool?
        var saveRecords: Bool?

        enum CodingKeys: String, CodingKey {
            case name, url, file
            case bucketID = "bucket_id"
            case collectionID = "collection_id"
            case fetchAttachments = "fetch_attachments"
            case saveRecords = "save_records"
        }
    }

    /// Use this method to load all available rules from local fetch config JSON.
    /// These rules can be used to know the corresponding bucket, collection and file
    /// for the local remote settings object.
    static func loadSettingsFetchConfig() -> RemoteSettingsFetchConfig? {
        guard let path = Bundle.main.path(forResource: "RemoteSettingsFetchConfig", ofType: "json") else { return nil }
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(RemoteSettingsFetchConfig.self, from: data)
            return config
        } catch {
            return nil
        }
    }
}
