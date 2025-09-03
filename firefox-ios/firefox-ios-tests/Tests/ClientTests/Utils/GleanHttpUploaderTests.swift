// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class GleanHttpUploaderTests: XCTestCase {
    var mockRequest = MockGleanPingUploadRequest()

    func testUploadWithoutURL_thenReturnsRecoverableFailure() {
        mockRequest.url = ""
        let manager = MockASOHttpManager()
        let subject = createSubject(manager: manager)
        let expectation = XCTestExpectation(description: "Wait for request completion")
        subject.uploadOhttpRequest(request: mockRequest) { result in
            XCTAssertEqual(result, .unrecoverableFailure(unused: 0))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testUploadWithURLAndError_thenReturnsRecoverableFailure() {
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

    func testUploadWithURLAndData_thenReturnsHttpStatusResponse() {
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

    private func createSubject(manager: MockASOHttpManager) -> GleanOhttpUploader {
        return GleanOhttpUploader(manager: manager)
    }
}
