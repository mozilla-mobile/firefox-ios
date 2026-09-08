// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import AppAttestKit
import XCTest
import TestKit

@testable import IPProtectionKit

final class IPProtectionAppAttestServerTests: XCTestCase {
    func test_fetchChallenge_returnsChallenge_onSuccess() async throws {
        let json = #"{"challenge":"\#(AppAttestTestData.challenge)"}"#
        let session = MockURLSession(with: Data(json.utf8), response: httpResponse(statusCode: 200))
        let subject = createSubject(urlSession: session)

        let result = try await subject.fetchChallenge(for: AppAttestTestData.keyID)

        XCTAssertEqual(result, AppAttestTestData.challenge)
    }

    func test_fetchChallenge_buildsCorrectRequest() async throws {
        let json = #"{"challenge":"\#(AppAttestTestData.challenge)"}"#
        let session = MockURLSession(with: Data(json.utf8), response: httpResponse(statusCode: 200))
        let subject = createSubject(urlSession: session)

        _ = try await subject.fetchChallenge(for: AppAttestTestData.keyID)

        let req = try XCTUnwrap(session.lastURLRequest, "Expected a request to be made")
        XCTAssertEqual(req.url?.path, "/api/v1/ipn/attest/challenge")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try decodeBody(req)
        XCTAssertEqual(body["keyId"] as? String, AppAttestTestData.keyID)
    }

    func test_fetchChallenge_throwsOnServerError() async {
        let session = MockURLSession(with: Data("error".utf8), response: httpResponse(statusCode: 500))
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

    func test_sendAttestation_savesSession_on200() async throws {
        let tokenStore = MockIPProtectionTokenStore()
        let session = MockURLSession(with: enrollmentJSON(), response: httpResponse(statusCode: 200))
        let subject = createSubject(urlSession: session, tokenStore: tokenStore)

        try await subject.sendAttestation(
            keyId: AppAttestTestData.keyID,
            attestationObject: AppAttestTestData.attestationBlob,
            challenge: AppAttestTestData.challenge
        )

        XCTAssertEqual(tokenStore.saveCallCount, 1)
        XCTAssertEqual(tokenStore.load()?.deviceSessionJwt, "test-dsj")
        XCTAssertEqual(tokenStore.load()?.expiresAt, 32503680000000)
    }

    func test_sendAttestation_buildsCorrectRequest() async throws {
        let session = MockURLSession(with: enrollmentJSON(), response: httpResponse(statusCode: 200))
        let subject = createSubject(urlSession: session)

        try await subject.sendAttestation(
            keyId: AppAttestTestData.keyID,
            attestationObject: AppAttestTestData.attestationBlob,
            challenge: AppAttestTestData.challenge
        )

        let req = try XCTUnwrap(session.lastURLRequest, "Expected a request to be made")
        XCTAssertEqual(req.url?.path, "/api/v1/ipn/enrollment")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try decodeBody(req)
        XCTAssertEqual(body["keyId"] as? String, AppAttestTestData.keyID)
        XCTAssertEqual(body["challenge"] as? String, AppAttestTestData.challenge)
        XCTAssertEqual(body["attestationObject"] as? String, AppAttestTestData.attestationBlob.base64EncodedString())
    }

    func test_sendAttestation_throwsOnServerError_andDoesNotSave() async {
        let tokenStore = MockIPProtectionTokenStore()
        let session = MockURLSession(with: Data("Forbidden".utf8), response: httpResponse(statusCode: 403))
        let subject = createSubject(urlSession: session, tokenStore: tokenStore)

        do {
            try await subject.sendAttestation(
                keyId: AppAttestTestData.keyID,
                attestationObject: AppAttestTestData.attestationBlob,
                challenge: AppAttestTestData.challenge
            )
            XCTFail("Expected sendAttestation to throw on server error.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(description: "403: Forbidden"))
            XCTAssertEqual(tokenStore.saveCallCount, 0)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - refreshSession

    func test_refreshSession_buildsCorrectRequest_andSavesSession() async throws {
        let tokenStore = MockIPProtectionTokenStore()
        let session = MockURLSession(with: enrollmentJSON(), response: httpResponse(statusCode: 200))
        let subject = createSubject(urlSession: session, tokenStore: tokenStore)

        try await subject.refreshSession(assertion: AssertionResult(
            keyId: AppAttestTestData.keyID,
            assertion: AppAttestTestData.assertionBlob,
            challenge: AppAttestTestData.assertionChallenge,
            payload: Data(#"{"challenge":"\#(AppAttestTestData.assertionChallenge)"}"#.utf8)
        ))

        let req = try XCTUnwrap(session.lastURLRequest, "Expected a request to be made")
        XCTAssertEqual(req.url?.path, "/api/v1/ipn/refresh")
        XCTAssertEqual(req.httpMethod, "POST")

        let body = try decodeBody(req)
        XCTAssertEqual(body["keyId"] as? String, AppAttestTestData.keyID)
        XCTAssertEqual(body["challenge"] as? String, AppAttestTestData.assertionChallenge)
        XCTAssertEqual(body["assertion"] as? String, AppAttestTestData.assertionBlob.base64EncodedString())

        XCTAssertEqual(tokenStore.load()?.deviceSessionJwt, "test-dsj")
    }

    func test_refreshSession_throwsOnServerError_andDoesNotSave() async {
        let tokenStore = MockIPProtectionTokenStore()
        let session = MockURLSession(with: Data("nope".utf8), response: httpResponse(statusCode: 401))
        let subject = createSubject(urlSession: session, tokenStore: tokenStore)

        do {
            try await subject.refreshSession(assertion: AssertionResult(
                keyId: AppAttestTestData.keyID,
                assertion: AppAttestTestData.assertionBlob,
                challenge: AppAttestTestData.assertionChallenge,
                payload: Data()
            ))
            XCTFail("Expected refreshSession to throw on server error.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(description: "401: nope"))
            XCTAssertEqual(tokenStore.saveCallCount, 0)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Helpers

    private func createSubject(
        urlSession: MockURLSession = MockURLSession(),
        tokenStore: IPProtectionTokenStore = MockIPProtectionTokenStore()
    ) -> IPProtectionAppAttestServer {
        return IPProtectionAppAttestServer(with: .dev, urlSession: urlSession, tokenStore: tokenStore)
    }

    private func enrollmentJSON() -> Data {
        return Data(#"{"deviceSessionJwt":"test-dsj","expiresAt":32503680000000,"renewAfter":0}"#.utf8)
    }

    private func decodeBody(_ request: URLRequest) throws -> [String: Any] {
        let body = try XCTUnwrap(request.httpBody, "Expected a request body")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
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
