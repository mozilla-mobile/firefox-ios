// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

protocol MerinoStoriesProviding: Sendable {
    func fetchContent() async throws -> CuratedRecommendationsResponse
}

final class MerinoProvider: MerinoStoriesProviding, FeatureFlaggable, @unchecked Sendable {
    private struct Constants {
        static let merinoServicesBaseURL = "https://merino.services.mozilla.com"
        static let numberOfStoriesToFetchForCaching = 100
    }

    private let thresholdInHours: Double
    private let cache: CuratedRecommendationsCacheProtocol
    private let prefs: Prefs
    private var logger: Logger
    private let fetcher: MerinoFeedFetching
    private let lock = NSLock()
    private var inFlightTask: Task<CuratedRecommendationsResponse?, Never>?

    enum Error: Swift.Error {
        case failure
    }

    init(
        withThresholdInHours threshold: Double = 1,
        prefs: Prefs,
        cache: CuratedRecommendationsCacheProtocol = CuratedRecommendationCacheUtility(),
        logger: Logger = DefaultLogger.shared,
        fetcher: MerinoFeedFetching? = nil
    ) {
        self.thresholdInHours = threshold
        self.cache = cache
        self.prefs = prefs
        self.logger = logger
        self.fetcher = fetcher ?? MerinoFeedFetcher(
            baseURL: Constants.merinoServicesBaseURL,
            logger: logger
        )
    }

    func fetchContent() async throws -> CuratedRecommendationsResponse {
        let requestID = String(UUID().uuidString.prefix(8))
        let start = Date()
        logger.log(
            "\(FreezeDiag.prefix)[Merino] provider fetchContent start id=\(requestID) appState=\(FreezeDiag.applicationState)",
            level: .info,
            category: .homepage
        )
        if !AppConstants.isRunningTest && shouldUseMockData {
            let response = MerinoTestData().getMockDataFeed(
                Constants.numberOfStoriesToFetchForCaching,
                categoriesEnabled: isHomepageStoryCategoriesEnabled
            )
            logger.log(
                "\(FreezeDiag.prefix)[Merino] provider fetchContent end id=\(requestID) durationMs=\(FreezeDiag.durationMs(since: start)) result=mockData storyCount=\(response.data.count) appState=\(FreezeDiag.applicationState)",
                level: .info,
                category: .homepage
            )
            return response
        }

        guard prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true,
              MerinoProvider.isLocaleSupported(Locale.current.identifier)
        else {
            logger.log(
                "\(FreezeDiag.prefix)[Merino] provider fetchContent end id=\(requestID) durationMs=\(FreezeDiag.durationMs(since: start)) result=disabledOrUnsupported appState=\(FreezeDiag.applicationState)",
                level: .warning,
                category: .homepage
            )
            throw Error.failure
        }

        if let cachedResponse = cache.loadResponse(),
           responseHasDisplayableContent(cachedResponse) {
            let cacheIsFresh = cacheUpdateThresholdHasNotPassed()
            logger.log(
                "\(FreezeDiag.prefix)[Merino] provider cacheHit id=\(requestID) fresh=\(cacheIsFresh) storyCount=\(cachedResponse.data.count) hasFeeds=\(cachedResponse.feeds?.isEmpty == false) appState=\(FreezeDiag.applicationState)",
                level: .info,
                category: .homepage
            )
            if !cacheIsFresh {
                logger.log(
                    "\(FreezeDiag.prefix)[Merino] provider staleReturn id=\(requestID) appState=\(FreezeDiag.applicationState)",
                    level: .info,
                    category: .homepage
                )
                refreshCacheInBackground(parentRequestID: requestID)
            }
            logger.log(
                "\(FreezeDiag.prefix)[Merino] provider fetchContent end id=\(requestID) durationMs=\(FreezeDiag.durationMs(since: start)) result=cache storyCount=\(cachedResponse.data.count) appState=\(FreezeDiag.applicationState)",
                level: .info,
                category: .homepage
            )
            return cachedResponse
        }

        guard let response = await createTask(parentRequestID: requestID, reason: "foregroundFetch").value else {
            logger.log(
                "\(FreezeDiag.prefix)[Merino] provider fetchContent end id=\(requestID) durationMs=\(FreezeDiag.durationMs(since: start)) result=failure appState=\(FreezeDiag.applicationState)",
                level: .warning,
                category: .homepage
            )
            throw Error.failure
        }
        logger.log(
            "\(FreezeDiag.prefix)[Merino] provider fetchContent end id=\(requestID) durationMs=\(FreezeDiag.durationMs(since: start)) result=network storyCount=\(response.data.count) appState=\(FreezeDiag.applicationState)",
            level: FreezeDiag.durationMs(since: start) > 3000 ? .warning : .info,
            category: .homepage
        )
        return response
    }

    private func refreshCacheInBackground(parentRequestID: String) {
        logger.log(
            "\(FreezeDiag.prefix)[Merino] provider backgroundRefresh start parentID=\(parentRequestID) appState=\(FreezeDiag.applicationState)",
            level: .info,
            category: .homepage
        )
        _ = createTask(parentRequestID: parentRequestID, reason: "backgroundRefresh")
    }

    static func isLocaleSupported(_ locale: String) -> Bool {
        return allCuratedRecommendationLocales().contains(
            locale.replacingOccurrences(of: "_", with: "-")
        )
    }

    private func createTask(parentRequestID: String, reason: String) -> Task<CuratedRecommendationsResponse?, Never> {
        lock.withLock {
            if let existing = inFlightTask {
                logger.log(
                    "\(FreezeDiag.prefix)[Merino] provider fetch coalesced parentID=\(parentRequestID) reason=\(reason) appState=\(FreezeDiag.applicationState)",
                    level: .debug,
                    category: .homepage
                )
                return existing
            }

            let newTask = makeNetworkFetchTask(parentRequestID: parentRequestID, reason: reason)
            inFlightTask = newTask
            return newTask
        }
    }

    private func makeNetworkFetchTask(
        parentRequestID: String,
        reason: String
    ) -> Task<CuratedRecommendationsResponse?, Never> {
        return Task<CuratedRecommendationsResponse?, Never> { [self] in
            defer { self.lock.withLock { self.inFlightTask = nil } }
            return await fetchNetworkContent(parentRequestID: parentRequestID, reason: reason)
        }
    }

    private func fetchNetworkContent(
        parentRequestID: String,
        reason: String
    ) async -> CuratedRecommendationsResponse? {
        let taskID = String(UUID().uuidString.prefix(8))
        let start = Date()
        logger.log(
            "\(FreezeDiag.prefix)[Merino] provider networkFetch start id=\(taskID) parentID=\(parentRequestID) reason=\(reason) appState=\(FreezeDiag.applicationState)",
            level: .info,
            category: .homepage
        )
        guard let currentLocale = iOSToMerinoLocale(from: Locale.current.identifier) else {
            logger.log(
                "\(FreezeDiag.prefix)[Merino] provider networkFetch end id=\(taskID) parentID=\(parentRequestID) durationMs=\(FreezeDiag.durationMs(since: start)) result=invalidLocale appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                level: .warning,
                category: .homepage
            )
            return nil
        }

        let response = await fetchMerinoResponse(locale: currentLocale)
        let durationMs = FreezeDiag.durationMs(since: start)
        saveResponseToCacheIfNeeded(response)
        logNetworkFetchEnd(
            taskID: taskID,
            parentRequestID: parentRequestID,
            reason: reason,
            durationMs: durationMs,
            response: response
        )
        return response
    }

    private func fetchMerinoResponse(locale: CuratedRecommendationLocale) async -> CuratedRecommendationsResponse? {
        let region = SystemLocaleProvider().regionCode()
        let regionCode: String? = region == "und" ? nil : region

        return await fetcher.fetch(
            itemCount: Constants.numberOfStoriesToFetchForCaching,
            locale: locale,
            region: regionCode,
            userAgent: UserAgent.getUserAgent()
        )
    }

    private func saveResponseToCacheIfNeeded(_ response: CuratedRecommendationsResponse?) {
        // Only cache items if we have a response, and it has some sort
        // of data we'd like to actually save
        if let response,
           responseHasDisplayableContent(response) {
            cache.clearCache()
            cache.save(response)
        }
    }

    private func logNetworkFetchEnd(
        taskID: String,
        parentRequestID: String,
        reason: String,
        durationMs: Int,
        response: CuratedRecommendationsResponse?
    ) {
        logger.log(
            "\(FreezeDiag.prefix)[Merino] provider networkFetch end id=\(taskID) parentID=\(parentRequestID) durationMs=\(durationMs) reason=\(reason) result=\(response == nil ? "failure" : "success") storyCount=\(response?.data.count ?? 0) hasFeeds=\(response?.feeds?.isEmpty == false) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
            level: durationMs > 3000 || Task.isCancelled ? .warning : .info,
            category: .homepage
        )
        guard reason == "backgroundRefresh" else { return }
        logger.log(
            "\(FreezeDiag.prefix)[Merino] provider backgroundRefresh end parentID=\(parentRequestID) durationMs=\(durationMs) result=\(response == nil ? "failure" : "success") appState=\(FreezeDiag.applicationState)",
            level: durationMs > 3000 ? .warning : .info,
            category: .homepage
        )
    }

    private var shouldUseMockData: Bool {
        return CoreBuildFlags.isUsingMockData || prefs.boolForKey(PrefsKeys.useMerinoTestData) ?? false
    }

    private var isHomepageStoryCategoriesEnabled: Bool {
        return featureFlagsProvider.isEnabled(.homepageStoryCategories)
    }

    private func iOSToMerinoLocale(from locale: String) -> CuratedRecommendationLocale? {
        return curatedRecommendationLocaleFromString(
            locale: locale.replacingOccurrences(of: "_", with: "-")
        )
    }

    private func cacheUpdateThresholdHasNotPassed() -> Bool {
        let thresholdInSeconds: TimeInterval = thresholdInHours * 60 * 60
        guard let lastUpdate = cache.lastUpdatedDate() else { return false }
        return Date() < lastUpdate.addingTimeInterval(thresholdInSeconds)
    }

    private func responseHasDisplayableContent(_ response: CuratedRecommendationsResponse) -> Bool {
        let hasCategoryRecommendations = response.feeds?.contains { !$0.recommendations.isEmpty } == true
        return hasCategoryRecommendations || !response.data.isEmpty
    }
}
