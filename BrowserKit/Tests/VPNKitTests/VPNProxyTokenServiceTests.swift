// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import AppAttestKit
import Shared
import XCTest
import TestKit

@testable import VPNKit

final class VPNProxyTokenServiceTests: XCTestCase {
    func test_fetchProxyPass_sendsStoredDSJ_andDecodesToken() async throws {
        let auth = MockVPNAuthenticating(session: session(jwt: "stored-dsj"))
        let urlSession = MockURLSession(with: tokenJSON(), response: httpResponse(statusCode: 200))
        let subject = VPNProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        let result = try await subject.fetchProxyPass()

        XCTAssertEqual(result.bearerToken, validJWT)
        XCTAssertEqual(result.notBefore, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(result.expiresAt, Date(timeIntervalSince1970: 1_700_003_600))
        XCTAssertNil(result.usage)

        let req = try XCTUnwrap(urlSession.lastURLRequest)
        XCTAssertEqual(req.url?.path, "/api/v1/ipn/token")
        XCTAssertEqual(req.httpMethod, "GET")
        XCTAssertEqual(req.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), "Bearer stored-dsj")
        XCTAssertEqual(auth.authenticateCallCount, 0, "Must never escalate to enrollment")
    }

    func test_fetchProxyPass_throws_whenNoStoredSession() async {
        let auth = MockVPNAuthenticating(session: nil)
        let urlSession = MockURLSession(with: tokenJSON(), response: httpResponse(statusCode: 200))
        let subject = VPNProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        do {
            _ = try await subject.fetchProxyPass()
            XCTFail("Expected fetchProxyPass to throw without a stored session.")
        } catch let error as VPNAuthError {
            XCTAssertEqual(error, .noStoredSession)
            XCTAssertEqual(auth.authenticateCallCount, 0, "Must never escalate to enrollment")
            XCTAssertNil(urlSession.lastURLRequest, "No request should be attempted")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_fetchProxyPass_refreshesAndRetries_on401() async throws {
        let auth = MockVPNAuthenticating(session: session(jwt: "stale-dsj"))
        let urlSession = SequencedURLSession(responses: [
            (Data(#"{"reason":"dsj-superseded"}"#.utf8), httpResponse(statusCode: 401)),
            (tokenJSON(), httpResponse(statusCode: 200))
        ])
        let subject = VPNProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        let result = try await subject.fetchProxyPass()

        XCTAssertEqual(result.bearerToken, validJWT)
        XCTAssertEqual(auth.refreshCallCount, 1, "Should refresh the session once before retrying")
        XCTAssertEqual(urlSession.callCount, 2)
    }

    func test_fetchProxyPass_throws_whenRetryAlsoFails() async {
        let auth = MockVPNAuthenticating(session: session(jwt: "stale-dsj"))
        let urlSession = SequencedURLSession(responses: [
            (Data(), httpResponse(statusCode: 401)),
            (Data(), httpResponse(statusCode: 401))
        ])
        let subject = VPNProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        do {
            _ = try await subject.fetchProxyPass()
            XCTFail("Expected fetchProxyPass to throw when the retry also fails.")
        } catch let error as VPNAuthError {
            XCTAssertEqual(error, .sessionRejected)
            XCTAssertEqual(auth.refreshCallCount, 1, "Should not retry more than once")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_fetchProxyPass_throwsOnServerError() async {
        let auth = MockVPNAuthenticating(session: session(jwt: "stored-dsj"))
        let urlSession = MockURLSession(with: Data("boom".utf8), response: httpResponse(statusCode: 500))
        let subject = VPNProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        do {
            _ = try await subject.fetchProxyPass()
            XCTFail("Expected fetchProxyPass to throw on server error.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(statusCode: 500, description: "boom"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - JWT decoding

    func test_fetchProxyPass_withTokenMissingNbf_usesCurrentDateForNotBefore() async throws {
        let jwt = makeJWT(payload: #"{"exp":1700003600}"#)
        let subject = createSubject(responseToken: jwt)
        let before = Date()

        let result = try await subject.fetchProxyPass()

        XCTAssertGreaterThanOrEqual(result.notBefore, before)
        XCTAssertEqual(result.expiresAt, Date(timeIntervalSince1970: 1_700_003_600))
    }

    func test_fetchProxyPass_withTokenMissingSegments_throwsInvalidToken() async {
        await assertThrowsInvalidToken(responseToken: "header.payload")
    }

    func test_fetchProxyPass_withPayloadMissingExp_throwsInvalidToken() async {
        await assertThrowsInvalidToken(responseToken: makeJWT(payload: #"{"sub":"user"}"#))
    }

    func test_fetchProxyPass_withPayloadNotBase64_throwsInvalidToken() async {
        await assertThrowsInvalidToken(responseToken: "header.!!!.signature")
    }

    // MARK: - Helpers

    private var validJWT: String {
        makeJWT(payload: #"{"nbf":1700000000,"exp":1700003600}"#)
    }

    private func createSubject(responseToken: String) -> VPNProxyTokenService {
        let auth = MockVPNAuthenticating(session: session(jwt: "stored-dsj"))
        let urlSession = MockURLSession(with: tokenJSON(token: responseToken), response: httpResponse(statusCode: 200))
        return VPNProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)
    }

    private func assertThrowsInvalidToken(
        responseToken: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let subject = createSubject(responseToken: responseToken)
        do {
            _ = try await subject.fetchProxyPass()
            XCTFail("Expected fetchProxyPass to throw", file: file, line: line)
        } catch let error as VPNAuthError {
            XCTAssertEqual(error, .invalidToken, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }

    /// Builds an unsigned JWT whose payload is base64url-encoded without padding, as Guardian returns it.
    private func makeJWT(payload: String) -> String {
        let encoded = Data(payload.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "header.\(encoded).signature"
    }

    private func session(jwt: String) -> VPNDeviceSession {
        VPNDeviceSession(
            deviceSessionJwt: jwt,
            expiresAtMilliseconds: 32503680000000,
            renewAfterMilliseconds: 32503600000000
        )
    }

    private func tokenJSON(token: String? = nil) -> Data {
        Data(#"{"token":"\#(token ?? validJWT)"}"#.utf8)
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

// MARK: - Test doubles

/// Mirrors the real service: `refresh()` replaces the stored session, so a retry reads the new one.
private final class MockVPNAuthenticating: VPNAuthenticating, @unchecked Sendable {
    private var storedSession: VPNDeviceSession?
    private(set) var refreshCallCount = 0
    private(set) var authenticateCallCount = 0

    init(session: VPNDeviceSession?) {
        self.storedSession = session
    }

    func authenticate() async throws -> String {
        authenticateCallCount += 1
        guard let storedSession else { throw VPNAuthError.notEnrolled }
        return storedSession.deviceSessionJwt
    }

    func refresh() async throws -> String {
        refreshCallCount += 1
        let refreshed = VPNDeviceSession(
            deviceSessionJwt: "refreshed-dsj",
            expiresAtMilliseconds: 32503680000000,
            renewAfterMilliseconds: 32503600000000
        )
        storedSession = refreshed
        return refreshed.deviceSessionJwt
    }

    func reset() throws { storedSession = nil }

    func currentSession() -> VPNDeviceSession? { storedSession }
}

/// Returns queued responses in order, so a retry can observe a different outcome.
private final class SequencedURLSession: URLSessionProtocol, @unchecked Sendable {
    private var responses: [(Data, URLResponse)]
    private(set) var callCount = 0

    init(responses: [(Data, URLResponse)]) { self.responses = responses }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        try next()
    }

    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try next()
    }

    private func next() throws -> (Data, URLResponse) {
        callCount += 1
        guard !responses.isEmpty else {
            throw AppAttestServiceError.serverError(statusCode: 500, description: "no more responses")
        }
        return responses.removeFirst()
    }

    func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        throw AppAttestServiceError.serverError(statusCode: 500, description: "unused")
    }

    func dataTaskWith(_ url: URL, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        fatalError("unused")
    }

    func dataTaskWith(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        fatalError("unused")
    }

    func uploadTaskWith(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionUploadTaskProtocol {
        fatalError("unused")
    }
}
