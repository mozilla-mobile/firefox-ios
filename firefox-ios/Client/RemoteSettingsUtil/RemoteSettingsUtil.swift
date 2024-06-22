// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Common
import Shared

class RemoteSettingsUtil {
    private var bucket: Remotebucket
    private var collection: RemoteCollection
    private let logger: Logger
    private let baseURL = "https://firefox.settings.services.mozilla.com/v1/"

    init(bucket: Remotebucket,
         collection: RemoteCollection,
         logger: Logger = DefaultLogger.shared) {
        self.bucket = bucket
        self.collection = collection
        self.logger = logger
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

    private func fetchRemoteRecords(collectionName: RemoteCollection,
                                    completion: @escaping (Result<[RemoteSettingsRecord], RemoteSettingsUtilError>) -> Void) {
        do {
            let config = RemoteSettingsConfig(collectionName: collectionName.rawValue)
            let settings = try RemoteSettings(remoteSettingsConfig: config)
            let response = try settings.getRecords()
            completion(.success(response.records))
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

    // MARK: Collections

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
