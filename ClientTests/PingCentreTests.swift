/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import XCTest
import JSONSchema
import Alamofire
import Deferred
import Shared

private let mockTopic = PingCentreTopic(name: "ios-mock", schema: Schema([
    "type": "object",
    "properties": [
        "title": ["type": "string"]
    ],
    "required": [
        "title"
    ]
]))

private var receivedNetworkRequests = [NSURLRequest]()

// Used to mock the network so we don't need to rely on the interweb for our unit tests.
class MockingURLProtocol: NSURLProtocol {
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return request.URL?.scheme == "https" && request.HTTPMethod == "POST"
    }

    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }

    override func startLoading() {
        receivedNetworkRequests.append(request)

        let response = NSHTTPURLResponse(URL: request.URL!,
                                         statusCode: 200,
                                         HTTPVersion: "HTTP/1.1",
                                         headerFields: [:])

        self.client?.URLProtocol(self, didReceiveResponse: response!, cacheStoragePolicy: .NotAllowed)
        self.client?.URLProtocol(self, didLoadData: "".dataUsingEncoding(NSUTF8StringEncoding)!)
        self.client?.URLProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        //no-op
    }
}

class PingCentreTests: XCTestCase {
    var manager: Alamofire.Manager!
    var client: PingCentreClient!

    override func setUp() {
        super.setUp()
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.protocolClasses!.insert(MockingURLProtocol.self, atIndex: 0)

        self.manager = Manager(configuration: configuration)
        self.client = DefaultPingCentreImpl(topic: mockTopic, endpoint: .Staging, clientID: "fakeID", manager: self.manager)
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

// Borrowed from StorageTestUtils...
private protocol Succeedable {
    var isSuccess: Bool { get }
    var isFailure: Bool { get }
}

extension Maybe: Succeedable {
}

private extension Deferred where T: Succeedable {
    func succeeded() {
        XCTAssertTrue(self.value.isSuccess)
    }

    func failed() {
        XCTAssertTrue(self.value.isFailure)
    }
}
