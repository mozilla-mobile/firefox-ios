// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol BaseRequest: Requestable, Sendable {}

enum RequestError: Error {
    case invalidBaseURL
    case invalidURLComponents
}

public extension BaseRequest {

    var baseURL: BaseURL {
        .api
    }

    var environment: Environment {
        .current
    }

    /// Resolves `baseURL` to an actual host. Only `.api`/`.web` are guaranteed Ecosia
    /// domains — see `makeURLRequest()`, which uses that guarantee to decide which
    /// Ecosia-internal headers are safe to attach.
    var resolvedBaseURL: URL {
        switch baseURL {
        case .api:
            return environment.urlProvider.apiRoot
        case .web:
            return environment.urlProvider.root
        case .custom(let url):
            return url
        }
    }

    func makeURLRequest() throws -> URLRequest {
        let url: URL
        switch baseURL {
        case .custom:
            // Ecosia: a caller-supplied URL (e.g. a presigned upload URL) already carries its
            // own path/query, often signed — used exactly as given, not merged with `path`.
            url = resolvedBaseURL
        case .api, .web:
            guard var urlComponents = URLComponents(url: resolvedBaseURL, resolvingAgainstBaseURL: false) else {
                throw RequestError.invalidBaseURL
            }
            urlComponents.path = path
            if let queryParameters {
                urlComponents.queryItems = queryParameters.map({ .init(name: $0.key, value: $0.value ) })
            }
            guard let resolvedURL = urlComponents.url else {
                throw RequestError.invalidURLComponents
            }
            url = resolvedURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = body

        if let additionalHeaders {
            additionalHeaders.forEach({ request.setValue($0.value, forHTTPHeaderField: $0.key) })
        }

        // Ecosia: only attach app-identifying/Cloudflare Access headers when the host is
        // guaranteed to be ours — a `.custom` URL (CDN, presigned upload URL, ...) isn't.
        guard case .custom = baseURL else {
            request.setValue("ios", forHTTPHeaderField: "X-Ecosia-App")
            return request.withCloudFlareAuthParameters()
        }
        return request
    }
}
