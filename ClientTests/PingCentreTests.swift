/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import XCTest
import JSONSchema
import Alamofire
import Deferred
import Shared
@testable import Telemetry

private let mockTopic = PingCentreTopic(name: "ios-mock", schema: Schema([
    "type": "object",
    "properties": [
        "title": ["type": "string"]
    ],
    "required": [
        "title"
    ]
]))

private var receivedNetworkRequests = [URLRequest]()

// Used to mock the network so we don't need to rely on the interweb for our unit tests.
class MockingURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme == "https" && request.httpMethod == "POST"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        receivedNetworkRequests.append(request)

        let response = HTTPURLResponse(url: request.url!,
                                         statusCode: 200,
                                         httpVersion: "HTTP/1.1",
                                         headerFields: [:])

        self.client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocol(self, didLoad: "".data(using: String.Encoding.utf8)!)
        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        //no-op
    }
}

class PingCentreTests: XCTestCase {
    var manager: SessionManager!
    var client: PingCentreClient!

    override func setUp() {
        super.setUp()
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses!.insert(MockingURLProtocol.self, at: 0)

        self.manager = SessionManager(configuration: configuration)
        self.client = DefaultPingCentreImpl(topic: mockTopic, endpoint: .staging, clientID: "fakeID", manager: self.manager)
    }

    override func tearDown() {
        receivedNetworkRequests = []
    }

    func testSendPing() {
        let validPing = [
            "title": "Test!"
        ]
        let invalidPing = [String: AnyObject]()

        client.sendPing(validPing, validate: true).succeeded()
        let validationError = client.sendPing(invalidPing, validate: true).value
        XCTAssertNotNil(validationError.failureValue)
        XCTAssertTrue(validationError.failureValue! is PingValidationError)

        // Double check that we actually sent the successful ping and not the invalid one
        XCTAssertTrue(receivedNetworkRequests.count == 1)
    }
}
