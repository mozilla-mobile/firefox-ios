/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared
import Deferred
import Storage

private let PocketEnvAPIKey = "PocketEnvironmentAPIKey"
private let PocketGlobalFeed = "https://getpocket.com/v3/firefox/global-recs"
private let MaxCacheAge = OneMinuteInMilliseconds * 60 // 1 hour in seconds

/*s
 The Pocket class is used to fetch stories from the Pocked API.
 Right now this only supports the global feed

 For a sample feed item check ClientTests/pocketglobalfeed.json
 */
struct PocketStory {
    let url: URL
    let title: String
    let storyDescription: String
    let imageURL: URL
    let domain: String

    static func parseJSON(list: Array<[String: Any]>) -> [PocketStory] {
        return list.flatMap({ (storyDict) -> PocketStory? in
            guard let urlS = storyDict["url"] as? String, let domain = storyDict["domain"] as? String,
                let imageURLS = storyDict["image_src"] as? String,
                let title = storyDict["title"] as? String,
                let description = storyDict["excerpt"] as? String else {
                    return nil
            }
            guard let url = URL(string: urlS), let imageURL = URL(string: imageURLS) else {
                return nil
            }
            return PocketStory(url: url, title: title, storyDescription: description, imageURL: imageURL, domain: domain)
        })
    }
}

private class PocketError: MaybeErrorType {
    var description = "Failed to load from API"
}

class Pocket {

    let pocketGlobalFeed: String
    // Allow endPoint to be overriden for testing
    init(endPoint: String? = nil) {
        pocketGlobalFeed = endPoint ?? PocketGlobalFeed
    }

    lazy fileprivate var alamofire: SessionManager = {
        let ua = UserAgent.fxaUserAgent //TODO: use a different UA
        let configuration = URLSessionConfiguration.default
        return SessionManager.managerWithUserAgent(ua, configuration: configuration)
    }()

    func findCachedResposneFor(request: URLRequest) -> [String: Any]? {
        let cachedResponse = URLCache.shared.cachedResponse(for: request)
        guard let cachedAtTime = cachedResponse?.userInfo?["cache-time"] as? Timestamp, (Date.now() - cachedAtTime) < MaxCacheAge else  {
            return nil
        }

        guard let data = cachedResponse?.data, let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }

        return json as? [String: Any]
    }

    func cacheResponseFor(response: HTTPURLResponse?, request: URLRequest, data: Data?) {
        guard let resp = response, let data  = data else {
            return
        }
        let metadata = ["cache-time": Date.now()]
        let cachedResp = CachedURLResponse(response: resp, data: data, userInfo: metadata, storagePolicy: .allowed)
        URLCache.shared.removeCachedResponse(for: request)
        URLCache.shared.storeCachedResponse(cachedResp, for: request)
    }

    // Fetch items from the global pocket feed
    func globalFeed(items: Int = 2) -> Deferred<Maybe<Array<PocketStory>>> {
        let deferred = Deferred<Maybe<Array<PocketStory>>>()

        guard let request = createGlobalFeedRequest(items: items) else {
            return deferMaybe(PocketError())
        }

        if let cachedResponse = findCachedResposneFor(request: request), let items = cachedResponse["list"] as? Array<[String: Any]> {
            deferred.fill(Maybe(success: PocketStory.parseJSON(list: items)))
            return deferred
        }

        alamofire.request(request).validate(contentType: ["application/json"]).responseJSON { response in
            guard response.error == nil, let result = response.result.value as? [String: Any] else {
                return deferred.fill(Maybe(failure: PocketError()))
            }

            self.cacheResponseFor(response: response.response, request: request, data: response.data)
            guard let items = result["list"] as? Array<[String: Any]> else {
                return deferred.fill(Maybe(failure: PocketError()))
            }
            return deferred.fill(Maybe(success: PocketStory.parseJSON(list: items)))
        }

        return deferred
    }

    // Create the URL request to query the Pocket API. The max items that the query can return is 20
    private func createGlobalFeedRequest(items: Int = 2) -> URLRequest? {
        guard items > 0 && items <= 20 else {
            return nil
        }

        guard let feedURL = URL(string: pocketGlobalFeed)?.withQueryParam("count", value: "\(items)") else {
            return nil
        }
        let apiURL = addAPIKey(url: feedURL)
        return URLRequest(url: apiURL, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 5)
    }

    private func addAPIKey(url: URL) -> URL {
        let bundle = Bundle.main
        guard let api_key = bundle.object(forInfoDictionaryKey: PocketEnvAPIKey) as? String else {
            return url
        }
        return url.withQueryParam("consumer_key", value: api_key)
    }

}
