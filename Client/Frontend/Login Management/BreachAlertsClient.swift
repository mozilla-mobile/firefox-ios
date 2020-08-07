/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

/// Errors related to BreachAlertsClient and BreachAlertsManager.
struct BreachAlertsError: MaybeErrorType {
    public let description: String
}
/// For mocking and testing BreachAlertsClient.
protocol BreachAlertsClientProtocol {
    func fetchEtag(endpoint: BreachAlertsClient.Endpoint, profile: Profile, completion: @escaping (_ etag: Maybe<String>) -> Void)
    func fetchData(endpoint: BreachAlertsClient.Endpoint, profile: Profile, completion: @escaping (_ result: Maybe<Data>) -> Void)
}

/// Handles all network requests for BreachAlertsManager.
public class BreachAlertsClient: BreachAlertsClientProtocol {
    private var dataTask: URLSessionDataTask?
    public enum Endpoint: String {
        case breachedAccounts = "https://monitor.firefox.com/hibp/breaches"
    }
    static let etagKey = "BreachAlertsDataEtag"
    static let dateKey = "BreachAlertsDataDate"

    /// Makes a header-only request to an endpoint and hands off the endpoint's etag to a completion handler.
    func fetchEtag(endpoint: Endpoint, profile: Profile, completion: @escaping (_ etag: Maybe<String>) -> Void) {
        guard let url = URL(string: endpoint.rawValue) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with: request) { _, response, _ in
            guard validatedHTTPResponse(response) != nil else {
            completion(Maybe(failure: BreachAlertsError(description: "invalid HTTP response")))
            return
        }
            let httpResponse = response as? HTTPURLResponse
            guard let etag = httpResponse?.allHeaderFields["Etag"] as Any as? String else { return }
            completion(Maybe(success: etag))
        }
        dataTask?.resume()
    }

    /// Makes a network request to an endpoint and hands off the result to a completion handler.
    func fetchData(endpoint: Endpoint, profile: Profile, completion: @escaping (_ result: Maybe<Data>) -> Void) {
        guard let url = URL(string: endpoint.rawValue) else {
            completion(Maybe(failure: BreachAlertsError(description: "bad endpoint URL")))
            return
        }

        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard validatedHTTPResponse(response) != nil else {
                completion(Maybe(failure: BreachAlertsError(description: "invalid HTTP response")))
                return
            }
            if let error = error {
                completion(Maybe(failure: BreachAlertsError(description: error.localizedDescription)))
                return
            }
            guard let data = data else {
                completion(Maybe(failure: BreachAlertsError(description: "invalid data")))
                return
            }

            let httpResponse = response as? HTTPURLResponse
            guard let etag = httpResponse?.allHeaderFields["Etag"] as Any as? String else { return }
            guard let date = httpResponse?.allHeaderFields["Date"] as Any as? String else { return }

            if profile.prefs.stringForKey(BreachAlertsClient.etagKey) != etag {
                profile.prefs.setString(etag, forKey: BreachAlertsClient.etagKey)
            }
            if profile.prefs.stringForKey(BreachAlertsClient.dateKey) != date {
                profile.prefs.setString(date, forKey: BreachAlertsClient.dateKey)
            }
            completion(Maybe(success: data))
        }
        dataTask?.resume()
    }
}
