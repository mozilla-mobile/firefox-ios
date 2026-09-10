// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import AppAttestKit

final class HTTPResponseValidationTests: XCTestCase {
    func test_validate_doesNotThrow_onSuccessStatus() throws {
        for statusCode in [200, 201, 204, 299] {
            XCTAssertNoThrow(
                try AppAttestServiceError.validate(response: response(statusCode: statusCode), data: Data()),
                "\(statusCode) should be accepted"
            )
        }
    }

    func test_validate_throwsWithStatusAndBody_onFailureStatus() {
        do {
            try AppAttestServiceError.validate(
                response: response(statusCode: 401),
                data: Data(#"{"reason":"unknown-key-id"}"#.utf8)
            )
            XCTFail("Expected validate to throw on a 401.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(statusCode: 401, description: #"{"reason":"unknown-key-id"}"#))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_validate_usesPlaceholder_whenBodyIsNotUTF8() {
        do {
            try AppAttestServiceError.validate(
                response: response(statusCode: 500),
                data: Data([0xFF, 0xFE])
            )
            XCTFail("Expected validate to throw on a 500.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(statusCode: 500, description: "Unknown server error"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// A non-HTTP response carries no status to judge, so validation has to pass it through.
    func test_validate_doesNotThrow_onNonHTTPResponse() {
        let nonHTTP = URLResponse(
            url: URL(string: "https://example.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )

        XCTAssertNoThrow(try AppAttestServiceError.validate(response: nonHTTP, data: Data()))
    }

    private func response(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}
