// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class GleanOhttpUploaderTests: XCTestCase {
    var mockRequest = MockGleanPingUploadRequest()

    func testUploadWithoutURL_thenReturnsUnrecoverableFailure() {
        mockRequest.url = ""
        let manager = MockASOHttpManager()
        let subject = createSubject(manager: manager)
        let expectation = XCTestExpectation(description: "Wait for request completion")
        subject.uploadOhttpRequest(request: mockRequest) { result in
            XCTAssertEqual(result, .unrecoverableFailure(unused: 0))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(manager.capturedRequests.isEmpty)
    }

    func testUploadWithResponse_thenReturnsHttpStatus() {
        let expectedStatusCode = 200
        let expectedData = "Test data".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: expectedStatusCode,
                                               httpVersion: nil,
                                               headerFields: nil)!
        let manager = MockASOHttpManager(with: expectedData, response: expectedResponse)
        let subject = createSubject(manager: manager)
        let expectation = XCTestExpectation(description: "Wait for request completion")

        subject.uploadOhttpRequest(request: mockRequest) { result in
            XCTAssertEqual(result, .httpStatus(code: Int32(expectedStatusCode)))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testUploadWithError_thenReturnsRecoverableFailure() {
        let expectedError = URLError(.cannotConnectToHost)
        let manager = MockASOHttpManager(and: expectedError)
        let subject = createSubject(manager: manager)
        let expectation = XCTestExpectation(description: "Wait for request completion")
        subject.uploadOhttpRequest(request: mockRequest) { result in
            XCTAssertEqual(result, .recoverableFailure(unused: 0))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    /// `OhttpManager` encapsulates `URLRequest.httpBody`, so a request without one
    /// is uploaded as a well-formed but empty ping that the ingestion endpoint
    /// rejects. This is the only place the OHTTP payload is observable.
    func testUpload_thenAttachesPingPayloadAsHttpBody() {
        let manager = MockASOHttpManager()
        let subject = createSubject(manager: manager)
        let expectation = XCTestExpectation(description: "Wait for request completion")

        subject.uploadOhttpRequest(request: mockRequest) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(manager.capturedRequests.count, 1)
        XCTAssertEqual(manager.capturedRequests.first?.httpBody, Data(mockRequest.data))
    }

    func testUpload_thenSendsPostRequestWithGleanHeaders() {
        let manager = MockASOHttpManager()
        let subject = createSubject(manager: manager)
        let expectation = XCTestExpectation(description: "Wait for request completion")

        subject.uploadOhttpRequest(request: mockRequest) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        let capturedRequest = manager.capturedRequests.first
        XCTAssertEqual(capturedRequest?.url?.absoluteString, mockRequest.url)
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "ContentType"), "application/json")
        XCTAssertEqual(capturedRequest?.httpShouldHandleCookies, false)
    }

    private func createSubject(manager: MockASOHttpManager) -> GleanOhttpUploader {
        return GleanOhttpUploader(manager: manager)
    }
}
