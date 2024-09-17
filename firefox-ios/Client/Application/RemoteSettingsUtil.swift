// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Common
import Shared

enum RemoteCollection: String {
    case searchTelemetry = "search-telemetry-v2"
}

enum Remotebucket: String {
    case defaultBucket = "main"
}

enum RemoteSettingsUtilError: Error {
    case decodingError
    case fetchError(Error)
}

extension RemoteSettingsRecord: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(deleted, forKey: .deleted)
        try container.encode(attachment, forKey: .attachment)
        try container.encode(fields, forKey: .fields)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let lastModified = try container.decode(UInt64.self, forKey: .lastModified)
        let deleted = try container.decode(Bool.self, forKey: .deleted)
        let attachment = try container.decodeIfPresent(Attachment.self, forKey: .attachment)
        let fields = try container.decode(RsJsonObject.self, forKey: .fields)
        
        self.init(id: id, lastModified: lastModified, deleted: deleted, attachment: attachment, fields: fields)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case lastModified
        case deleted
        case attachment
        case fields
    }
}

extension Attachment: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filename, forKey: .filename)
        try container.encode(mimetype, forKey: .mimetype)
        try container.encode(location, forKey: .location)
        try container.encode(hash, forKey: .hash)
        try container.encode(size, forKey: .size)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let filename = try container.decode(String.self, forKey: .filename)
        let mimetype = try container.decode(String.self, forKey: .mimetype)
        let location = try container.decode(String.self, forKey: .location)
        let hash = try container.decode(String.self, forKey: .hash)
        let size = try container.decode(UInt64.self, forKey: .size)

        self.init(filename: filename, mimetype: mimetype, location: location, hash: hash, size: size)
    }
    
    private enum CodingKeys: String, CodingKey {
        case filename
        case mimetype
        case location
        case hash
        case size
    }
}

// Collections that are to be fetched from the server
struct ServerCollection: Codable {
    let id: String
    let last_modified: Int
    let displayFields: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case last_modified
        case displayFields
    }
}

struct ServerCollectionsResponse: Codable {
    let data: [ServerCollection]
}

class RemoteSettingsUtil {
    private var bucket: Remotebucket
    private var collection: RemoteCollection
    private let logger: Logger
    private let baseURL = "https://firefox.settings.services.mozilla.com/v1/"
    private var config: RemoteSettingsFetchConfig?
    
    init(bucket: Remotebucket,
         collection: RemoteCollection,
         logger: Logger = DefaultLogger.shared) {
        self.bucket = bucket
        self.collection = collection
        self.logger = logger
        
        // Load default config
        self.config = RemoteSettingsFetchConfig.load()
        
        // TODO: Replace with Application Service Implementation
        updateAndFetchRecords(for: collection) { result in
            switch result {
            case .success(let success):
                logger.log("Remote Settings Item Count",
                           level: .info,
                           category: .remoteSettings,
                           description: "\(success.count)")
                logger.log("Remote Settings Pretty Print",
                           level: .info,
                           category: .remoteSettings,
                           description: "\(self.prettyPrint(success) ?? "")")
            case .failure(let failure):
                logger.log("Remote failure",
                           level: .warning,
                           category: .remoteSettings,
                           description: "\(failure)")
            }
        }
    }

    func loadPasswordRules() -> [PasswordRuleRecord]? {
        guard let config else { return nil }
        guard let passwordRules = config.loadLocal(
            settingType: .passwordRules,
            as: [PasswordRuleRecord].self
        ) else {
            return nil
        }
        return passwordRules
    }
    
    // MARK: OLDER
    // TODO: Replace with updated Application Services version
    func saveRemoteSettingsRecord(_ records: [RemoteSettingsRecord], forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(records) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func fetchLocalRecords(forKey key: String) -> [RemoteSettingsRecord]? {
        if let savedData = UserDefaults.standard.data(forKey: key) {
            let decoder = JSONDecoder()
            if let loadedRecords = try? decoder.decode([RemoteSettingsRecord].self, from: savedData) {
                return loadedRecords
            }
        }
        return nil
    }
    
    func fetchRemoteRecords(collectionName: RemoteCollection,
                            completion: @escaping (Result<[RemoteSettingsRecord],
                                                   RemoteSettingsUtilError>) -> Void) {
        do {
            let config = RemoteSettingsConfig(collectionName: collectionName.rawValue)
            let settings = try RemoteSettings(remoteSettingsConfig: config)
            let response = try settings.getRecords()
            completion(.success(response.records))
        } catch {
            completion(.failure(.fetchError(error)))
        }
    }
    
    func areRecordsDifferent(localRecords: [RemoteSettingsRecord],
                             remoteRecords: [RemoteSettingsRecord]) -> Bool {
        guard localRecords.count == remoteRecords.count else {
            return true
        }
        for (local, remote) in zip(localRecords, remoteRecords) {
            if local.lastModified != remote.lastModified {
                return true
            }
        }
        return false
    }
    
    func updateAndFetchRecords(for collectionName: RemoteCollection,
                               completion: @escaping (Result<[RemoteSettingsRecord], Error>) -> Void) {
        let localRecords = fetchLocalRecords(forKey: PrefsKeys.remoteSettingsKey) ?? []
        
        fetchRemoteRecords(collectionName: collectionName) { [weak self] result in
            switch result {
            case .success(let remoteRecords):
                if self?.areRecordsDifferent(localRecords: localRecords,
                                             remoteRecords: remoteRecords) ?? false {
                    self?.saveRemoteSettingsRecord(remoteRecords, forKey: PrefsKeys.remoteSettingsKey)
                    completion(.success(remoteRecords))
                } else {
                    completion(.success(localRecords))
                }
            case .failure(let error):
                self?.logger.log("Failed to get any events from Remote Settings",
                                 level: .warning,
                                 category: .remoteSettings,
                                 description: error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    // MARK: Collections
    
    func fetchCollections(for bucketID: String, completion: @escaping ([ServerCollection]?) -> Void) {
        let collectionsURL = baseURL + "buckets/\(bucketID)/collections"
        guard let url = URL(string: collectionsURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            let collectionsResponse = try? JSONDecoder().decode(ServerCollectionsResponse.self, from: data)
            completion(collectionsResponse?.data)
        }.resume()
    }
    
    // Helper methods for printing
    func prettyPrint<T: Codable>(_ value: [T]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(value)
            
            if var jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                
                for (index, var item) in jsonArray.enumerated() {
                    // Check if "fields aka RsJsonObject" is a string and parse it as JSON if possible
                    if let fieldsString = item["fields"] as? String,
                       let fieldsData = fieldsString.data(using: .utf8),
                       let fieldsJSON = try? JSONSerialization.jsonObject(with: fieldsData, options: []) {
                        
                        item["fields"] = fieldsJSON
                    }
                    
                    jsonArray[index] = item
                }
                
                let cleanedData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
                return String(data: cleanedData, encoding: .utf8)
            }
        } catch {
            logger.log("Failed to encode JSON",
                       level: .warning,
                       category: .remoteSettings,
                       description: "\(error)")
            return nil
        }
        return nil
    }
}
