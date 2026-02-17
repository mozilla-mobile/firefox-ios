// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol URLSessionProtocol: Sendable {
    typealias DataTaskResult = @Sendable (Data?, URLResponse?, Error?) -> Void

    func data(from url: URL) async throws -> (Data, URLResponse)

    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse)

    func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse)

    func dataTaskWith(_ url: URL,
                      completionHandler: @escaping DataTaskResult
    ) -> URLSessionDataTaskProtocol

    func dataTaskWith(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol

    func uploadTaskWith(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionUploadTaskProtocol
}

/// Default implementation for bytes(for:) (for backward compatibility)
/// Types should implement their own bytes(for:) method if used.
/// Otherwise, by default, types should not be using this method.
/// Attempting to use the default one here will yield a runtime assertion failure.
/// The throw is just to satisfy the async‑throws signature.
extension URLSessionProtocol {
    public func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        assertionFailure("Fallback bytes(for:) called! Conforming types provide their own implementation")
        throw URLError(.unsupportedURL)
    }
}

extension URLSession: URLSessionProtocol {
    public func data(from url: URL) async throws -> (Data, URLResponse) {
        try await data(from: url, delegate: nil)
    }

    public func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: urlRequest, delegate: nil)
    }

    public func bytes(for request: URLRequest) async throws -> (AsyncBytes, URLResponse) {
        return try await bytes(for: request, delegate: nil)
    }

    public func dataTaskWith(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler)
    }

    public func dataTaskWith(
        _ url: URL,
        completionHandler: @escaping DataTaskResult
    ) -> URLSessionDataTaskProtocol {
        dataTask(with: url, completionHandler: completionHandler) as URLSessionDataTaskProtocol
    }

    public func uploadTaskWith(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping  @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionUploadTaskProtocol {
        return uploadTask(with: request, from: bodyData, completionHandler: completionHandler)
    }
}
