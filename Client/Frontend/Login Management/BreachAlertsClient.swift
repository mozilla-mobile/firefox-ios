// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

/// Errors related to BreachAlertsClient and BreachAlertsManager.
struct BreachAlertsError: MaybeErrorType {
    public let description: String
}
/// For mocking and testing BreachAlertsClient.
protocol BreachAlertsClientProtocol {
    func fetchEtag(endpoint: BreachAlertsClient.Endpoint, profile: Profile, completion: @escaping (_ etag: String?) -> Void)
    func fetchData(endpoint: BreachAlertsClient.Endpoint, profile: Profile, completion: @escaping (_ result: Maybe<Data>) -> Void)
}

/// Handles all network requests for BreachAlertsManager.
public class BreachAlertsClient: BreachAlertsClientProtocol {
    private var dataTask: URLSessionDataTask?
    public enum Endpoint: String {
        case breachedAccounts = "https://monitor.firefox.com/hibp/breaches"
    }
    static let etagKey = "BreachAlertsDataEtag"
    static let etagDateKey = "BreachAlertsDataDate"

    /// Makes a header-only request to an endpoint and hands off the endpoint's etag to a completion handler.
    func fetchEtag(endpoint: Endpoint, profile: Profile, completion: @escaping (_ etag: String?) -> Void) {
        guard let url = URL(string: endpoint.rawValue) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with: request) { _, response, _ in
            guard let response = response as? HTTPURLResponse else { return }
            guard response.statusCode < 400 else {
                SentryIntegration.shared.send(message: "BreachAlerts: fetchEtag: HTTP status code: \(response.statusCode)")
                completion(nil)
                return
            }
            guard let etag = response.allHeaderFields["Etag"] as Any as? String else {
                completion(nil)
                assert(false)
                return
            }
            DispatchQueue.main.async {
                completion(etag)
            }
        }
        dataTask?.resume()
    }

    /// Makes a network request to an endpoint and hands off the result to a completion handler.
    func fetchData(endpoint: Endpoint, profile: Profile, completion: @escaping (_ result: Maybe<Data>) -> Void) {
        guard let url = URL(string: endpoint.rawValue) else { return }

        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let response = response as? HTTPURLResponse else { return }
            guard response.statusCode < 400 else {
                SentryIntegration.shared.send(message: "BreachAlerts: fetchData: HTTP status code: \(response.statusCode)")
                return
            }
            if let error = error {
                completion(Maybe(failure: BreachAlertsError(description: error.localizedDescription)))
                SentryIntegration.shared.send(message: "BreachAlerts: fetchData: \(error)")
                return
            }
            guard let data = data else {
                completion(Maybe(failure: BreachAlertsError(description: "invalid data")))
                SentryIntegration.shared.send(message: "BreachAlerts: fetchData: invalid data")
                assert(false)
                return
            }

            guard let etag = response.allHeaderFields["Etag"] as Any as? String else { return }
            let date = Date.now()

            if profile.prefs.stringForKey(BreachAlertsClient.etagKey) != etag {
                profile.prefs.setString(etag, forKey: BreachAlertsClient.etagKey)
            }
            if profile.prefs.timestampForKey(BreachAlertsClient.etagDateKey) != date {
                profile.prefs.setTimestamp(date, forKey: BreachAlertsClient.etagDateKey)
            }
            DispatchQueue.main.async {
                completion(Maybe(success: data))
            }
        }
        dataTask?.resume()
    }
}
