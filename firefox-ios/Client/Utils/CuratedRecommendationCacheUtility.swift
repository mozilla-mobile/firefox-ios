// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices

private struct CachedResponse: Codable {
    let response: CuratedRecommendationsResponse
    let lastUpdated: Date
}

protocol CuratedRecommendationsCacheProtocol {
    func save(_ response: CuratedRecommendationsResponse)
    func loadResponse() -> CuratedRecommendationsResponse?
    func lastUpdatedDate() -> Date?
    func clearCache()
}

final class CuratedRecommendationCacheUtility: CuratedRecommendationsCacheProtocol {
    private let logger: Logger
    private let fileManager: FileManagerProtocol
    private let cacheFileName = "curated_recommendations_cache.json"
    private let injectedURL: URL?

    private var cacheURL: URL? {
        if let injectedURL = injectedURL { return injectedURL }
        guard let documentDirectory = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else { return nil }
        return documentDirectory.appendingPathComponent(cacheFileName)
    }

    init(
        fileManager: FileManagerProtocol = FileManager.default,
        logger: Logger = DefaultLogger.shared,
        withCustomCacheURL injectedURL: URL? = nil
    ) {
        self.logger = logger
        self.fileManager = fileManager
        self.injectedURL = injectedURL
    }

    func save(_ response: CuratedRecommendationsResponse) {
        guard let cacheURL = cacheURL else {
            logger.log(
                "The cache URL for Merino could not be constructed",
                level: .debug,
                category: .merino
            )
            return
        }

        do {
            let data = try JSONEncoder().encode(
                CachedResponse(
                    response: response,
                    lastUpdated: Date()
                )
            )
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            logger.log(
                "Failed to save recommendations to cache: \(error)",
                level: .debug,
                category: .merino
            )
        }
    }

    func loadResponse() -> CuratedRecommendationsResponse? {
        return load()?.response
    }

    func lastUpdatedDate() -> Date? {
        return load()?.lastUpdated
    }

    private func load() -> CachedResponse? {
        guard let cacheURL = cacheURL else {
            logger.log(
                "The cache URL for Merino could not be constructed",
                level: .debug,
                category: .merino
            )
            return nil
        }

        do {
            let data = try Data(contentsOf: cacheURL)
            return try JSONDecoder().decode(CachedResponse.self, from: data)
        } catch {
            logger.log(
                "Failed to load recommendations from cache: \(error)",
                level: .debug,
                category: .merino
            )
            return nil
        }
    }

    func clearCache() {
        guard let cacheURL = cacheURL else {
            logger.log(
                "The cache URL for Merino could not be constructed",
                level: .debug,
                category: .merino
            )
            return
        }

        do {
            if fileManager.fileExists(atPath: cacheURL.path) {
                try fileManager.removeItem(at: cacheURL)
            }
        } catch {
            logger.log(
                "Failed to remove cache file: \(error)",
                level: .debug,
                category: .merino
            )
        }
    }
}
