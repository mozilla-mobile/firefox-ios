// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import TestKit
import Common

@testable import SummarizeKit

final class MLPAAppAttestServerTests: XCTestCase {
    func test_fetchChallenge_returnsChallenge_onSuccess() async throws {
        let json = #"{"challenge":"\#(AppAttestTestData.challenge)"}"#
        let response = httpResponse(statusCode: 200)
        let session = MockURLSession(with: json.data(using: .utf8)!, response: response)
        let subject = createSubject(urlSession: session)

        let result = try await subject.fetchChallenge(for: AppAttestTestData.keyID)

        XCTAssertEqual(result, AppAttestTestData.challenge)
    }

    func test_fetchChallenge_buildsCorrectURL() async throws {
        let json = #"{"challenge":"\#(AppAttestTestData.challenge)"}"#
        let response = httpResponse(statusCode: 200)
        let session = MockURLSession(with: json.data(using: .utf8)!, response: response)
        let subject = createSubject(urlSession: session)

        _ = try await subject.fetchChallenge(for: AppAttestTestData.keyID)

        let req = try XCTUnwrap(session.lastURLRequest, "Expected a request to be made")
        let url = try XCTUnwrap(req.url)

        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = components.queryItems ?? []
        XCTAssertEqual(url.path, "/verify/challenge")
        XCTAssertEqual(items.first(where: { $0.name == "key_id_b64" })?.value, AppAttestTestData.keyID)
    }

    func test_fetchChallenge_throwsOnServerError() async {
        let response = httpResponse(statusCode: 500)
        let session = MockURLSession(with: "error".data(using: .utf8)!, response: response)
        let subject = createSubject(urlSession: session)

        do {
            _ = try await subject.fetchChallenge(for: AppAttestTestData.keyID)
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
        let subject = createSubject(urlSession: session)

        try await subject.sendAttestation(
            keyId: AppAttestTestData.keyID,
            attestationObject: AppAttestTestData.attestationBlob,
            challenge: AppAttestTestData.challenge
        )
    }

    func test_sendAttestation_buildsCorrectRequest() async throws {
        let response = httpResponse(statusCode: 200)
        let session = MockURLSession(with: Data(), response: response)
        let subject = createSubject(urlSession: session)

        try await subject.sendAttestation(
            keyId: AppAttestTestData.keyID,
            attestationObject: AppAttestTestData.attestationBlob,
            challenge: AppAttestTestData.challenge
        )

        let req = try XCTUnwrap(session.lastURLRequest, "Expected a request to be made")
        let url = try XCTUnwrap(req.url)
        let auth = req.value(forHTTPHeaderField: "Authorization")

        XCTAssertEqual(url.path, "/verify/attest")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNotNil(auth)
        XCTAssertTrue(auth?.hasPrefix("Bearer ") == true)
    }

    func test_sendAttestation_throwsOnServerError() async {
        let response = httpResponse(statusCode: 403)
        let session = MockURLSession(with: "Forbidden".data(using: .utf8)!, response: response)
        let subject = createSubject(urlSession: session)

        do {
            try await subject.sendAttestation(
                keyId: AppAttestTestData.keyID,
                attestationObject: AppAttestTestData.attestationBlob,
                challenge: AppAttestTestData.challenge
            )
            XCTFail("Expected sendAttestation to throw on server error.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(description: "403: Forbidden"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    private func createSubject(
        urlSession: MockURLSession = MockURLSession(),
        bundleIdentifier: String = AppAttestTestData.bundleID
    ) -> MLPAAppAttestServer {
        return MLPAAppAttestServer(urlSession: urlSession, bundleIdentifier: bundleIdentifier)
    }

    private func httpResponse(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}
