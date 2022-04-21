// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Protocol to provide a caching functionnality for network calls
protocol URLCaching {
    func findCachedData(for request: URLRequest, timestamp: Timestamp) -> Data?
    func findCachedResponse(for request: URLRequest) -> [String: Any]?
    func cache(response: HTTPURLResponse?, for request: URLRequest, with data: Data?)
}

extension URLCaching {
    // The default maximum cache age, 1 hour in milliseconds, can be overriden
    var maxCacheAge: Timestamp { OneMinuteInMilliseconds * 60 }
    private var cacheAgeKey: String { "cache-time" }

    func findCachedData(for request: URLRequest, timestamp: Timestamp) -> Data? {
        let cachedResponse = URLCache.shared.cachedResponse(for: request)
        guard let cachedAtTime = cachedResponse?.userInfo?[cacheAgeKey] as? Timestamp,
              (timestamp - cachedAtTime) < maxCacheAge,
              let data = cachedResponse?.data else {
            return nil
        }

        return data
    }

    func findCachedResponse(for request: URLRequest) -> [String: Any]? {
        guard (findCachedData(for: request, timestamp: Date.now()) != nil) else { return nil }

        let cachedResponse = URLCache.shared.cachedResponse(for: request)
        guard let data = cachedResponse?.data, let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }

        return json as? [String: Any]
    }

    func cache(response: HTTPURLResponse?, for request: URLRequest, with data: Data?) {
        guard let response = response, let data  = data else {
            return
        }

        let metadata = [cacheAgeKey: Date.now()]
        let cachedResp = CachedURLResponse(response: response, data: data, userInfo: metadata, storagePolicy: .allowed)
        URLCache.shared.removeCachedResponse(for: request)
        URLCache.shared.storeCachedResponse(cachedResp, for: request)
    }
}
