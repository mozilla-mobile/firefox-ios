// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import TestKit
@testable import SummarizeKit

final class MLPAAppAttestServerTests: XCTestCase {
    private enum TestData {
        static let keyID = "test-key-id"
        static let challenge = "test-challenge-123"
        static let attestationBlob = Data("attestation-blob".utf8)
    }

    func test_fetchChallenge_returnsChallenge_onSuccess() async throws {
        let json = #"{"challenge":"\#(TestData.challenge)"}"#
        let response = httpResponse(statusCode: 200)
        let session = MockURLSession(with: json.data(using: .utf8)!, response: response)
        let server = MLPAAppAttestServer(urlSession: session)

        let result = try await server.fetchChallenge(for: TestData.keyID)

        XCTAssertEqual(result, TestData.challenge)
    }

    func test_fetchChallenge_throwsOnServerError() async {
        let response = httpResponse(statusCode: 500)
        let session = MockURLSession(with: "error".data(using: .utf8)!, response: response)
        let server = MLPAAppAttestServer(urlSession: session)

        do {
            _ = try await server.fetchChallenge(for: TestData.keyID)
            XCTFail("Expected fetchChallenge to throw on server error.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(description: "500: error"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_sendAttestation_succeeds_on200() async throws {
        let response = httpResponse(statusCode: 200)
        let session = MockURLSession(with: Data(), response: response)
        let server = MLPAAppAttestServer(urlSession: session)

        try await server.sendAttestation(
            keyId: TestData.keyID,
            attestationObject: TestData.attestationBlob,
            challenge: TestData.challenge
        )
    }

    func test_sendAttestation_throwsOnServerError() async {
        let response = httpResponse(statusCode: 403)
        let session = MockURLSession(with: "Forbidden".data(using: .utf8)!, response: response)
        let server = MLPAAppAttestServer(urlSession: session)

        do {
            try await server.sendAttestation(
                keyId: TestData.keyID,
                attestationObject: TestData.attestationBlob,
                challenge: TestData.challenge
            )
            XCTFail("Expected sendAttestation to throw on server error.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(description: "403: Forbidden"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    private func httpResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}
