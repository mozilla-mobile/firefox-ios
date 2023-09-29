// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol FaviconURLCache {
    func getURLFromCache(cacheKey: String) async throws -> URL
    func cacheURL(cacheKey: String, faviconURL: URL) async
    func clearCache() async
}

actor DefaultFaviconURLCache: FaviconURLCache {
    private enum CacheConstants {
        static let cacheKey = "favicon-url-cache"
        static let daysToExpiration = 30
    }

    static let shared = DefaultFaviconURLCache()
    private let fileManager: URLCacheFileManager
    private var urlCache = [String: FaviconURL]()
    private var preserveTask: Task<Void, Never>?
    private let preserveDebounceTime: UInt64 = 10_000_000_000 // 10 seconds

    init(fileManager: URLCacheFileManager = DefaultURLCacheFileManager()) {
        self.fileManager = fileManager

        Task {
            await retrieveCache()
        }
    }

    func getURLFromCache(cacheKey: String) async throws -> URL {
        guard let favicon = urlCache[cacheKey],
              let url = URL(string: favicon.faviconURL, invalidCharacters: false)
        else { throw SiteImageError.noURLInCache }

        // Update the element in the cache so it's time to expire is reset
        // We don't need to wait for this to finish
        Task {
            await cacheURL(cacheKey: cacheKey, faviconURL: url)
        }

        return url
    }

    func cacheURL(cacheKey: String, faviconURL: URL) async {
        let favicon = FaviconURL(cacheKey: cacheKey,
                                 faviconURL: faviconURL.absoluteString,
                                 createdAt: Date())
        urlCache[cacheKey] = favicon
        preserveCache()
    }

    func clearCache() async {
        urlCache = [String: FaviconURL]()
        preserveCache()
    }

    private func preserveCache() {
        preserveTask?.cancel()
        preserveTask = Task {
            try? await Task.sleep(nanoseconds: preserveDebounceTime)
            guard !Task.isCancelled,
                  let data = archiveCacheData()
            else { return }
            await fileManager.saveURLCache(data: data)
        }
    }

    private func archiveCacheData() -> Data? {
        let cacheArray = urlCache.map { _, value in return value }
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        do {
            try archiver.encodeEncodable(cacheArray, forKey: CacheConstants.cacheKey)
        } catch {
            // Intentionally ignoring failure, a fail to save
            // is not catastrophic and the cache can always be rebuilt
        }
        return archiver.encodedData
    }

    private func retrieveCache() async {
        guard let data = await fileManager.getURLCache(),
              let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data),
              let cacheList = unarchiver.decodeDecodable([FaviconURL].self, forKey: CacheConstants.cacheKey)
        else {
            // Intentionally ignoring failure, a fail to retrieve
            // is not catastrophic and the cache can always be rebuilt
            return
        }

        // Ignore elements that are past the expiration time
        let today = Date()
        urlCache = cacheList.reduce(into: [String: FaviconURL]()) {
            if numberOfDaysBetween(start: $1.createdAt, end: today) >= CacheConstants.daysToExpiration {
                return
            }
            $0[$1.cacheKey] = $1
        }
    }

    private func numberOfDaysBetween(start: Date, end: Date) -> Int {
        let calendar = NSCalendar.current
        let startDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: end)
        let numberOfDays = calendar.dateComponents([.day], from: startDate, to: endDate)
        return numberOfDays.day ?? 0
    }
}
