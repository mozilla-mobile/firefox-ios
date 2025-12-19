// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol BaseRequest: Requestable {}

enum RequestError: Error {
    case invalidBaseURL
    case invalidURLComponents
}

public extension BaseRequest {

    var baseURL: URL {
        environment.urlProvider.apiRoot
    }

    var environment: Environment {
        .current
    }

    func makeURLRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw RequestError.invalidBaseURL
        }
        urlComponents.path = path
        if let queryParameters {
            urlComponents.queryItems = queryParameters.map({ .init(name: $0.key, value: $0.value ) })
        }
        guard let url = urlComponents.url else {
            throw RequestError.invalidURLComponents
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = body

        if let additionalHeaders {
            additionalHeaders.forEach({ request.setValue($0.value, forHTTPHeaderField: $0.key) })
        }

        return request.withCloudFlareAuthParameters()
    }
}
