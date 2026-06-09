// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest
import TestKit

@testable import Client

class GleanOhttpUploaderTests: XCTestCase {
    let mockRequest = MockGleanPingUploadRequest()

    func testUploadWithoutData_thenReturnsRecoverableFailure() {
        let session = MockURLSession()
        let subject = createSubject(session: session)
        let expectation = XCTestExpectation(description: "Wait for request completion")
        subject.uploadHttpRequest(request: mockRequest) { result in
            XCTAssertEqual(result, .recoverableFailure(unused: 0))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(session.uploadTask.countOfBytesClientExpectsToReceive, 512)
        XCTAssertEqual(session.uploadTask.countOfBytesClientExpectsToSend, 1024 * 1024)
        XCTAssertEqual(session.uploadTask.resumeCount, 1)
    }

    func testUploadWithError_thenReturnsRecoverableFailure() {
        let expectedError = URLError(.cannotConnectToHost)
        let session = MockURLSession(and: expectedError)
        let subject = createSubject(session: session)
        let expectation = XCTestExpectation(description: "Wait for request completion")
        subject.uploadHttpRequest(request: mockRequest) { result in
            XCTAssertEqual(result, .recoverableFailure(unused: 0))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUploadWithResponseAndData_thenReturnsSuccessWithStatusCode() {
        let expectedStatusCode = 200
        let expectedData = "Test data".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: expectedStatusCode,
                                               httpVersion: nil,
                                               headerFields: nil)!
        let session = MockURLSession(
            with: expectedData,
            response: expectedResponse
        )
        let subject = createSubject(session: session)
        let expectation = XCTestExpectation(description: "Wait for request completion")

        subject.uploadHttpRequest(request: mockRequest) { result in
            XCTAssertEqual(result, .httpStatus(code: Int32(expectedStatusCode)))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    private func createSubject(session: MockURLSession) -> GleanHttpUploader {
        return GleanHttpUploader(session: session)
    }
}
