// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

class PocketSponsoredStoriesProvider: PocketSponsoredStoriesProviderInterface, FeatureFlaggable {

    enum Error: Swift.Error {
        case failure
    }

    func fetchSponsoredStories(completion: @escaping (SponsoredStoryResult) -> Void) {
        guard let request = sponsoredFeedRequest else {
            completion(.failure(Error.failure))
            return
        }

        // TODO: Get from cache
        // if let cachedResponse = findCachedResponse(for: request), let items = cachedResponse["recommendations"] as? Array<[String: Any]> {
        //     deferred.fill(PocketFeedStory.parseJSON(list: items))
        //     return deferred
        // }

        urlSession.dataTask(with: request) { (data, response, error) in
            guard let _ = validatedHTTPResponse(response, contentType: "application/json"), let data = data else {
                completion(.failure(Error.failure))
                return
            }

            // TODO: store in cache
            // self.cache(response: response, for: request, with: data)

            let decodedResponse = try? JSONDecoder().decode(PocketSponsoredRequest.self, from: data)
            completion(.success(decodedResponse?.spocs ?? []))
        }.resume()
    }

    var endpoint: URL {
        if featureFlags.isCoreFeatureEnabled(.useStagingSponsoredPocketStoriesAPI) {
            return PocketSponsoredConstants.staging
        } else {
            return PocketSponsoredConstants.prod
        }
    }

    lazy private var urlSession = makeURLSession(userAgent: UserAgent.defaultClientUserAgent, configuration: URLSessionConfiguration.default)

    private lazy var pocketKey: String = {
        return Bundle.main.object(forInfoDictionaryKey: PocketSponsoredConstants.pocketEnvAPIKey) as? String ?? ""
    }()

    private lazy var pocketId: String = {
        if let pocketId = UserDefaults.standard.object(forKey: PocketSponsoredConstants.pocketId) as? String {
            return pocketId
        } else {
            let uuid = UUID()
            UserDefaults.standard.setValue(uuid.uuidString, forKey: PocketSponsoredConstants.pocketId)
            return uuid.uuidString
        }
    }()

    private var sponsoredFeedRequest: URLRequest? {
        var request = Locale
            .current
            .regionCode?
            .map { URLQueryItem(name: .country, value: $0) }
            .map { endpoint.withQueryParams([$0]) }
            .map {
                URLRequest(
                    url: $0,
                    cachePolicy: .reloadIgnoringCacheData,
                    timeoutInterval: 5
                )
            }

        let body: [String: Any] = [
            .version: 2,
            .consumer_key: pocketKey,
            .pocket_id: pocketId
        ]

        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        request?.httpBody = bodyData
        request?.httpMethod = .post
        return request
    }
}

enum PocketSponsoredConstants {
    static let pocketEnvAPIKey = "PocketEnvironmentAPIKey"
    static let pocketId = "PocketID"
    static let staging = URL(string: "https://spocs.getpocket.dev/spocs")!
    static let prod = URL(string: "https://spocs.getpocket.com/spocs")!
}

fileprivate extension String {
    static let country = "country"
    static let version = "version"
    static let consumer_key = "consumer_key"
    static let pocket_id = "pocket_id"
    static let post = "POST"
}
