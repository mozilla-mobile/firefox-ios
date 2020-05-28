//
//  BreachAlertsClient.swift
//  Client
//
//  Created by Vanna Phong on 5/27/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation
import Shared

/// Errors related to BreachAlertsClient and BreachAlertsManager.
struct BreachAlertsError: MaybeErrorType {
    public let description: String
}
/// For mocking and testing BreachAlertsClient.
protocol BreachAlertsClientProtocol {
    func fetchData(endpoint: BreachAlertsClient.Endpoint, completion: @escaping (_ result: Maybe<Data>) -> Void)
}

/// Handles all network requests for BreachAlertsManager.
public class BreachAlertsClient: BreachAlertsClientProtocol {
    private var dataTask: URLSessionDataTask?
    public enum Endpoint: String {
        case breachedAccounts = "https://monitor.firefox.com/hibp/breaches"
    }

    /// Makes a network request to an endpoint and hands off the result to a completion handler.
    public func fetchData(endpoint: Endpoint, completion: @escaping (_ result: Maybe<Data>) -> Void) {
        // endpoint.rawValue is the url
        guard let url = URL(string: endpoint.rawValue) else {
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
            guard let data = data, !data.isEmpty else {
                completion(Maybe(failure: BreachAlertsError(description: "empty data")))
                return
            }
            completion(Maybe(success: data))
        }
        dataTask?.resume()
    }
}
