// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TestKit
import XCTest
import Common
@testable import Client

final class CertificatesFetcherTests: XCTestCase {
    override func tearDown() {
        MockCertificateURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testGetCertificates_whenRequestFailsWithError_callsCompletionWithNil() async throws {
        MockCertificateURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockCertificateURLProtocol.self]

        let logger = MockLogger()
        let fetcher = CertificatesFetcher(configuration: configuration, logger: logger)

        let expectation = expectation(description: "completion called with nil")
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        fetcher.getCertificates(for: url) { certificates in
            XCTAssertNil(certificates)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5)
        XCTAssertEqual(logger.savedLevel, .warning)
        XCTAssertEqual(logger.savedCategory, .certificate)
    }
}

/// URL protocol stub that hands each request to `requestHandler`, letting tests drive the
/// data-task outcome without hitting the network.
final class MockCertificateURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> Void)?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            try handler(request)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
