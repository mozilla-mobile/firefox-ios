// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

protocol FaviconURLCache {
    func getURLFromCache(domain: String) async throws -> URL
    func cacheURL(domain: String, faviconURL: URL) async
}

actor DefaultFaviconURLCache: FaviconURLCache {
    private enum CacheConstants {
        static let cacheKey = "favicon-url-cache"
    }

    static let shared = DefaultFaviconURLCache()
    private let fileManager: URLCacheFileManager
    private var urlCache = [String: FaviconURL]()
    private var preserveTask: Task<Void, Never>?
    private let preserveDebounceTime: UInt64 = 5_000_000_000 // 5 seconds

    init(fileManager: URLCacheFileManager = DefaultURLCacheFileManager()) {
        self.fileManager = fileManager

        Task {
            await retrieveCache()
        }
    }

    func getURLFromCache(domain: String) async throws -> URL {
        guard let favicon = urlCache[domain],
              let url = URL(string: favicon.faviconURL)
        else { throw SiteImageError.noURLInCache }
        return url
    }

    func cacheURL(domain: String, faviconURL: URL) async {
        let favicon = FaviconURL(domain: domain,
                                 faviconURL: faviconURL.absoluteString,
                                 createdAt: Date())
        urlCache[domain] = favicon
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
        urlCache = cacheList.reduce(into: [String: FaviconURL]()) {
            $0[$1.domain] = $1
        }
    }
}
