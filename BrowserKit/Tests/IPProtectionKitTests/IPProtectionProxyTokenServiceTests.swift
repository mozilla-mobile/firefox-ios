// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import AppAttestKit
import Shared
import XCTest
import TestKit

@testable import IPProtectionKit

final class IPProtectionProxyTokenServiceTests: XCTestCase {
    func test_fetchProxyToken_sendsStoredDSJ_andDecodesToken() async throws {
        let auth = MockIPProtectionAuthenticating(session: session(jwt: "stored-dsj"))
        let urlSession = MockURLSession(with: tokenJSON(), response: httpResponse(statusCode: 200))
        let subject = IPProtectionProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        let result = try await subject.fetchProxyToken()

        XCTAssertEqual(result.token, "vpn-jwt")
        XCTAssertEqual(result.expiresIn, 600)

        let req = try XCTUnwrap(urlSession.lastURLRequest)
        XCTAssertEqual(req.url?.path, "/api/v1/ipn/token")
        XCTAssertEqual(req.httpMethod, "GET")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), "Bearer stored-dsj")
        XCTAssertEqual(auth.authenticateCallCount, 0, "Must never escalate to enrollment")
    }

    func test_fetchProxyToken_throws_whenNoStoredSession() async {
        let auth = MockIPProtectionAuthenticating(session: nil)
        let urlSession = MockURLSession(with: tokenJSON(), response: httpResponse(statusCode: 200))
        let subject = IPProtectionProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        do {
            _ = try await subject.fetchProxyToken()
            XCTFail("Expected fetchProxyToken to throw without a stored session.")
        } catch let error as IPProtectionError {
            XCTAssertEqual(error, .noStoredSession)
            XCTAssertEqual(auth.authenticateCallCount, 0, "Must never escalate to enrollment")
            XCTAssertNil(urlSession.lastURLRequest, "No request should be attempted")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_fetchProxyToken_refreshesAndRetries_on401() async throws {
        let auth = MockIPProtectionAuthenticating(session: session(jwt: "stale-dsj"))
        let urlSession = SequencedURLSession(responses: [
            (Data(#"{"reason":"dsj-superseded"}"#.utf8), httpResponse(statusCode: 401)),
            (tokenJSON(), httpResponse(statusCode: 200))
        ])
        let subject = IPProtectionProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        let result = try await subject.fetchProxyToken()

        XCTAssertEqual(result.token, "vpn-jwt")
        XCTAssertEqual(auth.refreshCallCount, 1, "Should refresh the session once before retrying")
        XCTAssertEqual(urlSession.callCount, 2)
    }

    func test_fetchProxyToken_throws_whenRetryAlsoFails() async {
        let auth = MockIPProtectionAuthenticating(session: session(jwt: "stale-dsj"))
        let urlSession = SequencedURLSession(responses: [
            (Data(), httpResponse(statusCode: 401)),
            (Data(), httpResponse(statusCode: 401))
        ])
        let subject = IPProtectionProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        do {
            _ = try await subject.fetchProxyToken()
            XCTFail("Expected fetchProxyToken to throw when the retry also fails.")
        } catch let error as IPProtectionError {
            XCTAssertEqual(error, .sessionRejected)
            XCTAssertEqual(auth.refreshCallCount, 1, "Should not retry more than once")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_fetchProxyToken_throwsOnServerError() async {
        let auth = MockIPProtectionAuthenticating(session: session(jwt: "stored-dsj"))
        let urlSession = MockURLSession(with: Data("boom".utf8), response: httpResponse(statusCode: 500))
        let subject = IPProtectionProxyTokenService(with: .dev, urlSession: urlSession, authService: auth)

        do {
            _ = try await subject.fetchProxyToken()
            XCTFail("Expected fetchProxyToken to throw on server error.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(description: "500: boom"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Helpers

    private func session(jwt: String) -> IPProtectionDeviceSession {
        IPProtectionDeviceSession(
            deviceSessionJwt: jwt,
            expiresAt: 32503680000000,
            renewAfter: 32503600000000
        )
    }

    private func tokenJSON() -> Data {
        Data(#"{"token":"vpn-jwt","expiresIn":600}"#.utf8)
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
private final class MockIPProtectionAuthenticating: IPProtectionAuthenticating, @unchecked Sendable {
    private var storedSession: IPProtectionDeviceSession?
    private(set) var refreshCallCount = 0
    private(set) var authenticateCallCount = 0

    init(session: IPProtectionDeviceSession?) {
        self.storedSession = session
    }

    func authenticate() async throws -> String {
        authenticateCallCount += 1
        guard let storedSession else { throw IPProtectionError.notEnrolled }
        return storedSession.deviceSessionJwt
    }

    func refresh() async throws -> String {
        refreshCallCount += 1
        let refreshed = IPProtectionDeviceSession(
            deviceSessionJwt: "refreshed-dsj",
            expiresAt: 32503680000000,
            renewAfter: 32503600000000
        )
        storedSession = refreshed
        return refreshed.deviceSessionJwt
    }

    func reset() throws { storedSession = nil }

    func currentSession() -> IPProtectionDeviceSession? { storedSession }
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
        guard !responses.isEmpty else { throw AppAttestServiceError.serverError(description: "no more responses") }
        return responses.removeFirst()
    }

    func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        throw AppAttestServiceError.serverError(description: "unused")
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
