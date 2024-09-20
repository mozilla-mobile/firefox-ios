// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct RemoteSettingsFetchConfig: Codable {
    let rules: [Rule]

    struct Rule: Codable {
        let name: String
        let url: String
        let file: String
        let bucketID: String
        let collectionsID: String

        enum CodingKeys: String, CodingKey {
            case name, url, file
            case bucketID = "bucket_id"
            case collectionsID = "collections_id"
        }
    }

    /// Use this method to initially load all available rules from local fetch config JSON.
    /// These rules are important to know the corresponding bucket,
    /// collection and file name for the local remote settings.
    static func loadSettingsFetchConfig() -> RemoteSettingsFetchConfig? {
        guard let path = Bundle.main.path(forResource: "RemoteSettingsFetchConfig",
                                          ofType: "json") else { return nil }
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(RemoteSettingsFetchConfig.self, from: data)
            return config
        } catch {
            return nil
        }
    }

    // MARK: Helpers

    /// Helper to list the names of all available local remote data types we have for loading
//    func listAllLocalRemoteSettingsType() -> [RemoteDataType] {
//        var availableSettings: [RemoteDataType] = []
//
//        for rule in rules {
//            if rule.name == RemoteDataType.passwordRules.name {
//                availableSettings.append(.passwordRules)
//            }
//            // NOTE: add mappings between rule.name and RemoteDataType cases
//            // Ex. Search config v2 for search engine consolidation
//        }
//
//        return availableSettings
//    }
}
