// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import XCTest

@testable import Client

class ContileProviderTests: XCTestCase {
    // TODO: Test getting error
    // TODO: Test getting a 403
    // TODO: Test getting no data
    // TODO: Test getting wrong JSON
    // TODO: Test ordering position
    // TODO: Test ordering position with partly nil
    // TODO: Test success

    override func setUp() {
        super.setUp()
        URLCache.shared.removeAllCachedResponses()
    }

    override func tearDown() {
        super.tearDown()
        URLCache.shared.removeAllCachedResponses()
    }

    func testEmptyArrayResponse() {
        stubResponse(response: emptyArrayResponse, statusCode: 200, error: nil)
        testProvider() { result in
            if case .success(let contiles) = result {
                XCTAssertEqual(contiles, [])
            } else {
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }
}

// MARK: - Helpers

private extension ContileProviderTests {
    func getProvider(file: StaticString = #filePath, line: UInt = #line) -> ContileProviderInterface {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let provider = ContileProvider()
        provider.urlSession = session
        trackForMemoryLeaks(provider, file: file, line: line)
        return provider
    }

    func testProvider(completion: @escaping (ContileResult) -> Void) {
        let provider = getProvider()
        let expectation = expectation(description: "Wait for completion")
        provider.fetchContiles { result in
            completion(result)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func stubResponse(response: String?, statusCode: Int, error: Error?) {
        let mockJSONData = response?.data(using: .utf8)
        let response = HTTPURLResponse(url: URL(string: ContileProvider.contileResourceEndpoint)!,
                                       statusCode: statusCode,
                                       httpVersion: nil,
                                       headerFields: nil)!
        URLProtocolStub.stub(data: mockJSONData, response: response, error: error)
    }

    var emptyArrayResponse: String {
        return "{\"tiles\":[]}"
    }

    var emptyResponse: String {
        return "{}"
    }

    var anError: NSError {
        return NSError(domain: "test error", code: 0)
    }
}

// MARK: URLProtocolStub
class URLProtocolStub: URLProtocol {
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    private static var _stub: Stub?
    private static var stub: Stub? {
        get { return queue.sync { _stub } }
        set { queue.sync { _stub = newValue } }
    }

    private static let queue = DispatchQueue(label: "URLProtocolStub.test.queue")

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error)
    }

    static func removeStub() {
        stub = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let stub = URLProtocolStub.stub else { return }

        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }

        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}
