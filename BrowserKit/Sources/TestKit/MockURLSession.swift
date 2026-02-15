// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

public final class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    private(set) var resumeWasCalled = false

    public func resume() {
        resumeWasCalled = true
    }
}

public final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    public var dataTask = MockURLSessionDataTask()
    public var uploadTask = MockURLSessionUploadTask()
    private let data: Data?
    private let response: URLResponse?
    private let error: Error?

    public init(
        with data: Data? = nil,
        response: URLResponse? = nil,
        and error: Error? = nil
    ) {
        self.data = data
        self.response = response
        self.error = error
    }

    public func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }

        return (data ?? Data(), response ?? URLResponse())
    }

    public func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await data(from: urlRequest.url!)
    }

    public func dataTaskWith(
        _ url: URL,
        completionHandler completion: @escaping DataTaskResult
    ) -> URLSessionDataTaskProtocol {
        completion(data, response, error)
        return dataTask
    }

    public func dataTaskWith(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        return MockURLSessionDataTask()
    }

    public func uploadTaskWith(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionUploadTaskProtocol {
        completionHandler(data, response, error)
        return uploadTask
    }
}

public class MockURLSessionUploadTask: URLSessionUploadTaskProtocol {
    public var resumeCount = 0
    public var countOfBytesClientExpectsToSend: Int64 = 0
    public var countOfBytesClientExpectsToReceive: Int64 = 0
    public func resume() {
        resumeCount += 1
    }
}
