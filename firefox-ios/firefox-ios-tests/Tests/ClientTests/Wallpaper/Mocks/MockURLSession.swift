// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

final class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    private(set) var resumeWasCalled = false

    func resume() {
        resumeWasCalled = true
    }
}

final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var dataTask = MockURLSessionDataTask()
    var uploadTask = MockURLSessionUploadTask()
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
        return MockURLSessionDataTask()
    }

    func uploadTaskWith(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionUploadTaskProtocol {
        completionHandler(data, response, error)
        return uploadTask
    }
}

class MockURLSessionUploadTask: URLSessionUploadTaskProtocol {
    var resumeCount = 0
    var countOfBytesClientExpectsToSend: Int64 = 0
    var countOfBytesClientExpectsToReceive: Int64 = 0
    func resume() {
        resumeCount += 1
    }
}
