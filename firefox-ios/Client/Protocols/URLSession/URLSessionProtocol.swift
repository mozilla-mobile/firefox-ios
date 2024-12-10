// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol URLSessionProtocol {
    typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void

    func data(from url: URL) async throws -> (Data, URLResponse)

    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse)

    func dataTaskWith(_ url: URL,
                      completionHandler: @escaping DataTaskResult
    ) -> URLSessionDataTaskProtocol

    func dataTaskWith(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol
}

extension URLSession: URLSessionProtocol {
    public func data(from url: URL) async throws -> (Data, URLResponse) {
        try await data(from: url, delegate: nil)
    }
    
    public func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: urlRequest, delegate: nil)
    }

    func dataTaskWith(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler)
    }

    func dataTaskWith(_ url: URL,
                      completionHandler: @escaping DataTaskResult
    ) -> URLSessionDataTaskProtocol {
        dataTask(with: url, completionHandler: completionHandler) as URLSessionDataTaskProtocol
    }
}
