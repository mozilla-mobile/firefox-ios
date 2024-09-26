// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Common
import Shared

public protocol RemoteSettingsUtilProvider: AnyObject {
    func saveRemoteSettingsRecord(_ records: [RemoteSettingsRecord], forKey key: String)
    func fetchLocalRecords(forKey key: String) -> [RemoteSettingsRecord]?
    func updateAndFetchRecords(for collectionName: RemoteCollection,
                               with key: String,
                               and records: [RemoteSettingsRecord]?,
                               completion: @escaping (Result<[RemoteSettingsRecord], Error>) -> Void)
    func fetchCollections(for bucketID: String, completion: @escaping ([ServerCollection]?) -> Void)
    func updateCollectionName(to newCollection: RemoteCollection)
}

class RemoteSettingsUtil: RemoteSettingsUtilProvider {    
    private var bucket: Remotebucket
    private var collection: RemoteCollection
    private let logger: Logger
    private let baseURL = "https://firefox.settings.services.mozilla.com/v1/"
    var remoteSettings: RemoteSettingsProtocol?

    init(bucket: Remotebucket,
         collection: RemoteCollection,
         logger: Logger = DefaultLogger.shared,
         remoteSettings: RemoteSettingsProtocol? = nil) {

        
        self.bucket = bucket
        self.collection = collection
        self.logger = logger
        
        // Default implementation if remoteSettings is not provided
        if let remoteSettings = remoteSettings {
            self.remoteSettings = remoteSettings
        } else {
            let config = RemoteSettingsConfig(collectionName: collection.rawValue)

            do {
                self.remoteSettings = try RemoteSettings(remoteSettingsConfig: config)
            } catch {
                self.logger.log("Failed to load remote settings",
                                 level: .warning,
                                 category: .remoteSettings,
                                 description: error.localizedDescription)
            }
        }
    }
    
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
    
    func clearLocalRecords(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func fetchRemoteRecords(completion: @escaping (Result<[RemoteSettingsRecord],
                                                           RemoteSettingsUtilError>) -> Void) {
        do {
            if let response = try remoteSettings?.getRecords() {
                completion(.success(response.records))
            }
        } catch {
            completion(.failure(.fetchError(error)))
        }
    }

    private func areRecordsDifferent(localRecords: [RemoteSettingsRecord],
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

    func updateCollectionName(to newCollection: RemoteCollection) {
        self.collection = newCollection
        let config = RemoteSettingsConfig(collectionName: newCollection.rawValue)
        
        do {
            self.remoteSettings = try RemoteSettings(remoteSettingsConfig: config)
        } catch {
            self.logger.log("Failed to load remote settings",
                             level: .warning,
                             category: .remoteSettings,
                             description: error.localizedDescription)
        }
    }

    // MARK: Collections

    func updateAndFetchRecords(for collectionName: RemoteCollection,
                               with key: String = PrefsKeys.remoteSettingsKey,
                               and records: [RemoteSettingsRecord]? = nil,
                               completion: @escaping (Result<[RemoteSettingsRecord], Error>) -> Void) {
    
        // Update the collection name when fetching new version
        updateCollectionName(to: collectionName)
        
        let localRecords = fetchLocalRecords(forKey: key) ?? []
        
        // If records are provided, bypass fetchRemoteRecords
        if let providedRecords = records {
            updateRecords(localRecords: localRecords, remoteRecords: providedRecords, key: key)
            completion(.success(providedRecords))
        } else {
            fetchRemoteRecords { [weak self] result in
                switch result {
                case .success(let remoteRecords):
                    self?.updateRecords(localRecords: localRecords, remoteRecords: remoteRecords, key: key)
                    completion(.success(remoteRecords))
                case .failure(let error):
                    self?.logger.log("Failed to get any events from Remote Settings",
                                     level: .warning,
                                     category: .remoteSettings,
                                     description: error.localizedDescription)
                    completion(.failure(error))
                }
            }
        }
    }

    private func updateRecords(localRecords: [RemoteSettingsRecord],
                               remoteRecords: [RemoteSettingsRecord],
                               key: String = PrefsKeys.remoteSettingsKey) {
        if areRecordsDifferent(localRecords: localRecords, remoteRecords: remoteRecords) {
            saveRemoteSettingsRecord(remoteRecords, forKey: key)
        }
    }

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
}
