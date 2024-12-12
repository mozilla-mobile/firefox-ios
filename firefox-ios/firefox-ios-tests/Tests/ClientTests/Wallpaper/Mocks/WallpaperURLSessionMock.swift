// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class WallpaperURLSessionDataTaskMock: URLSessionDataTaskProtocol {
    private(set) var resumeWasCalled = false

    func resume() {
        resumeWasCalled = true
    }
}

class WallpaperURLSessionMock: URLSessionProtocol {
    var dataTask = WallpaperURLSessionDataTaskMock()
    private let data: Data?
    private let response: URLResponse?
    private let error: Error?

    init(
        with data: Data? = nil,
        response: URLResponse? = nil,
        and error: Error? = nil
    ) {
        self.data = data
        self.response = response
        self.error = error
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }

        return (data ?? Data(), response ?? URLResponse())
    }

    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await data(from: urlRequest.url!)
    }

    func dataTaskWith(_ url: URL,
                      completionHandler completion: @escaping DataTaskResult
    ) -> URLSessionDataTaskProtocol {
        completion(data, response, error)
        return dataTask
    }

    func dataTaskWith(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        return MockURLSessionDataTaskProtocol()
    }
}

class MockURLSessionDataTaskProtocol: URLSessionDataTaskProtocol {
    func resume() {}
}
