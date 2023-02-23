// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

class PocketSponsoredStoriesProvider: PocketSponsoredStoriesProviding, FeatureFlaggable, URLCaching {
    private var logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    var endpoint: URL {
        if featureFlags.isCoreFeatureEnabled(.useStagingSponsoredPocketStoriesAPI) {
            return PocketSponsoredConstants.staging
        } else {
            return PocketSponsoredConstants.prod
        }
    }

    lazy var urlSession: URLSession = makeURLSession(userAgent: UserAgent.defaultClientUserAgent, configuration: URLSessionConfiguration.default)

    private lazy var pocketKey: String = {
        return Bundle.main.object(forInfoDictionaryKey: PocketSponsoredConstants.pocketEnvAPIKey) as? String ?? ""
    }()

    lazy var urlCache: URLCache = {
        return URLCache.shared
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
            .consumerKey: pocketKey,
            .pocketId: pocketId
        ]

        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        request?.httpBody = bodyData
        request?.httpMethod = .post

        return request
    }

    func fetchSponsoredStories(timestamp: Timestamp = Date.now(), completion: @escaping (SponsoredStoryResult) -> Void) {
        guard let request = sponsoredFeedRequest else {
            completion(.failure(Error.requestCreationFailure))
            return
        }

        if let cachedData = findCachedData(for: request, timestamp: timestamp) {
            decode(data: cachedData, completion: completion)
        } else {
            fetchSponsoredStories(request: request, completion: completion)
        }
    }

    func fetchSponsoredStories(request: URLRequest, completion: @escaping (SponsoredStoryResult) -> Void) {
        urlSession.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }
            if let error = error {
                self.logger.log("An error occurred while fetching data: \(error)",
                                level: .debug,
                                category: .homepage)
                completion(.failure(Error.failure))
                return
            }

            guard let response = validatedHTTPResponse(response, statusCode: 200..<300),
                       let data = data,
                       !data.isEmpty
            else {
                self.logger.log("Response isn't proper",
                                level: .debug,
                                category: .homepage)
                completion(.failure(Error.invalidHTTPResponse))
                return
            }

            self.cache(response: response, for: request, with: data)
            self.decode(data: data, completion: completion)
        }.resume()
    }

    private func decode(data: Data, completion: @escaping (SponsoredStoryResult) -> Void) {
        do {
            let decodedResponse = try JSONDecoder().decode(PocketSponsoredRequest.self, from: data)
            completion(.success(decodedResponse.spocs))
        } catch {
            logger.log("Unable to parse with error: \(error)",
                       level: .warning,
                       category: .homepage)
            completion(.failure(Error.decodingFailure))
        }
    }
}

extension PocketSponsoredStoriesProvider {
    enum Error: Swift.Error {
        case failure
        case decodingFailure
        case requestCreationFailure
        case invalidHTTPResponse
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
    static let consumerKey = "consumer_key"
    static let pocketId = "pocket_id"
    static let post = "POST"
}
