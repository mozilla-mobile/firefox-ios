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
    public init(description: String) {
        self.description = description
    }
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

    public init() { }

    /// Makes a network request to an endpoint and hands off the result to a completion handler.
    public func fetchData(endpoint: Endpoint, completion: @escaping (_ result: Maybe<Data>) -> Void) {
        // endpoint.rawValue is the url
        guard let url = URL(string: endpoint.rawValue) else {
            return
        }

        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard self.validatedHTTPResponse(response) != nil else {
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


    /// From firefox-ios/Shared/NetworkUtils.swift, to validate the HTTP response.
    private func validatedHTTPResponse(_ response: URLResponse?, contentType: String? = nil, statusCode: Range<Int>?  = nil) -> HTTPURLResponse? {
        if let response = response as? HTTPURLResponse {
            if let range = statusCode {
                return range.contains(response.statusCode) ? response :  nil
            }
            if let type = contentType {
                if let responseType = response.allHeaderFields["Content-Type"] as? String {
                    return responseType.contains(type) ? response : nil
                }
                return nil
            }
            return response
        }
        return nil
    }
}
