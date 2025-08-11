// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices

/// This exists because `RecommendationDataItem` is an Application-Services object and
/// UNIFFI cannot mark things as Codable. So this exists merely as a placeholder until
/// that functionality is added in.
private struct CachableRecommendationItem: Codable {
    let corpusItemId: String
    let scheduledCorpusItemId: String
    let url: String
    let title: String
    let excerpt: String
    let topic: String?
    let publisher: String
    let isTimeSensitive: Bool
    let imageUrl: String
    let iconUrl: String?
    let tileId: Int64
    let receivedRank: Int64

    init(from model: RecommendationDataItem) {
        self.corpusItemId = model.corpusItemId
        self.scheduledCorpusItemId = model.scheduledCorpusItemId
        self.url = model.url
        self.title = model.title
        self.excerpt = model.excerpt
        self.topic = model.topic
        self.publisher = model.publisher
        self.isTimeSensitive = model.isTimeSensitive
        self.imageUrl = model.imageUrl
        self.iconUrl = model.iconUrl
        self.tileId = model.tileId
        self.receivedRank = model.receivedRank
    }

    func toModel() -> RecommendationDataItem {
        return RecommendationDataItem(
            corpusItemId: corpusItemId,
            scheduledCorpusItemId: scheduledCorpusItemId,
            url: url,
            title: title,
            excerpt: excerpt,
            topic: topic,
            publisher: publisher,
            isTimeSensitive: isTimeSensitive,
            imageUrl: imageUrl,
            iconUrl: iconUrl,
            tileId: tileId,
            receivedRank: receivedRank
        )
    }
}

private struct CachedRecommendations: Codable {
    let recommendations: [CachableRecommendationItem]
    let lastUpdated: Date
}

protocol CuratedRecommendationsCacheProtocol {
    func save(_ recommendations: [RecommendationDataItem])
    func loadRecommendations() -> [RecommendationDataItem]?
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

    func save(_ recommendations: [RecommendationDataItem]) {
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
                CachedRecommendations(
                    recommendations: recommendations.map { CachableRecommendationItem(from: $0) },
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

    func loadRecommendations() -> [RecommendationDataItem]? {
        return load()?.recommendations.map { $0.toModel() }
    }

    func lastUpdatedDate() -> Date? {
        return load()?.lastUpdated
    }

    private func load() -> CachedRecommendations? {
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
            return try JSONDecoder().decode(CachedRecommendations.self, from: data)
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
