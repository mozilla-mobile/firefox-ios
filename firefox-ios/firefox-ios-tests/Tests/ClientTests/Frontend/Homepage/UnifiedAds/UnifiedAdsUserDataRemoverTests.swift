// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import TestKit

@testable import Client

final class UnifiedAdsUserDataRemoverTests: XCTestCase {
    func testDeleteUserData_GivenNoResponse_ThenThrowsError() async {
        let expectedData = "Test data".data(using: .utf8)!
        let subject = createSubject(with: expectedData)

        do {
            try await subject.deleteUserData(contextID: "12345")
            XCTFail("We should throw an error")
        } catch let error as UserDataDeletionError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDeleteUserData_GivenUnsuccessfulStatusCode_ThenThrowsError() async {
        let expectedData = "Test data".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 403,
                                               httpVersion: nil,
                                               headerFields: nil)!
        let subject = createSubject(with: expectedData, response: expectedResponse)

        do {
            try await subject.deleteUserData(contextID: "12345")
            XCTFail("We should throw an error")
        } catch let error as UserDataDeletionError {
            XCTAssertEqual(error, .serverError(statusCode: 403))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDeleteUserData_GivenSuccessfulResponse_ThenSucceeds() async {
        let expectedData = "Test data".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)!
        let subject = createSubject(with: expectedData, response: expectedResponse)

        do {
            try await subject.deleteUserData(contextID: "12345")
        } catch {
            XCTFail("This should be a success")
        }
    }

    func createSubject(with data: Data? = nil,
                       response: URLResponse? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line) -> UnifiedAdsUserDataRemover {
        let session = MockURLSession(
            with: data,
            response: response,
            and: nil
        )
        let subject = UnifiedAdsUserDataRemover(session: session)

        return subject
    }
}
