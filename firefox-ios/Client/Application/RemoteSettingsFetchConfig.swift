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
    
    // MARK: Helpers

    func listAllRemoteSettings() -> [RemoteDataType] {
        var availableSettings: [RemoteDataType] = []
        
        for rule in rules {
            if rule.name == RemoteDataType.passwordRules.name {
                availableSettings.append(.passwordRules)
            }
            // NOTE: add mappings between rule.name and RemoteDataType cases
            // Ex. Search config v2 for search engine consolidation
        }

        return availableSettings
    }

    // Load the appropriate local data based on the enum case selected
    func loadLocal<T: Codable>(settingType: RemoteDataType, as type: T.Type) -> T? {
        guard let rule = rules.first(where: { $0.name == settingType.name }) else {
            return nil
        }

        return RemoteDataType.loadRecord(for: rule, type: type)
    }

    static func load() -> RemoteSettingsFetchConfig? {
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
}
