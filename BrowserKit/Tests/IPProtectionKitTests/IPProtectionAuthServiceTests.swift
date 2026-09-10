// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import AppAttestKit
import XCTest
import TestKit

@testable import IPProtectionKit

final class IPProtectionAuthServiceTests: XCTestCase {
    // MARK: - Cached session

    func test_authenticate_returnsCachedDSJ_whenFresh_withoutNetwork() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: freshSession)
        let remoteServer = MockAppAttestRemoteServer()
        let refresher = MockIPProtectionSessionRefresher(tokenStore: tokenStore)
        let subject = try makeSubject(remoteServer: remoteServer, refresher: refresher, tokenStore: tokenStore)

        let result = try await subject.authenticate()

        XCTAssertEqual(result, "cached-dsj")
        XCTAssertEqual(remoteServer.fetchChallengeCallCount, 0)
        XCTAssertEqual(remoteServer.sendAttestationCallCount, 0)
        XCTAssertEqual(refresher.refreshCallCount, 0)
    }

    // MARK: - Assertion refresh

    func test_authenticate_refreshesViaAssertion_whenPastRenewAfter() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: renewableSession)
        let keyStore = MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID)
        let remoteServer = MockAppAttestRemoteServer()
        let refresher = MockIPProtectionSessionRefresher(
            tokenStore: tokenStore,
            sessionToReturn: refreshedSession
        )
        let subject = try makeSubject(
            remoteServer: remoteServer,
            keyStore: keyStore,
            refresher: refresher,
            tokenStore: tokenStore
        )

        let result = try await subject.authenticate()

        XCTAssertEqual(result, "refreshed-dsj")
        XCTAssertEqual(refresher.refreshCallCount, 1)
        XCTAssertEqual(remoteServer.sendAttestationCallCount, 0, "Should not re-attest on refresh")
        XCTAssertEqual(keyStore.loadKeyID(), AppAttestTestData.keyID, "Key must be preserved")
    }

    func test_authenticate_refreshesViaAssertion_whenExpired() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: expiredSession)
        let refresher = MockIPProtectionSessionRefresher(
            tokenStore: tokenStore,
            sessionToReturn: refreshedSession
        )
        let subject = try makeSubject(
            remoteServer: MockAppAttestRemoteServer(),
            keyStore: MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID),
            refresher: refresher,
            tokenStore: tokenStore
        )

        let result = try await subject.authenticate()

        XCTAssertEqual(result, "refreshed-dsj")
        XCTAssertEqual(refresher.refreshCallCount, 1)
    }

    func test_refresh_signsChallengeBoundPayload() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: expiredSession)
        let remoteServer = MockAppAttestRemoteServer()
        remoteServer.challengeToReturn = AppAttestTestData.assertionChallenge
        let refresher = MockIPProtectionSessionRefresher(
            tokenStore: tokenStore,
            sessionToReturn: refreshedSession
        )
        let subject = try makeSubject(
            remoteServer: remoteServer,
            keyStore: MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID),
            refresher: refresher,
            tokenStore: tokenStore
        )

        _ = try await subject.refresh()

        let assertion = try XCTUnwrap(refresher.lastAssertion)
        XCTAssertEqual(assertion.challenge, AppAttestTestData.assertionChallenge)
        // The signed payload must contain the challenge, so the server can rebuild identical bytes.
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: assertion.payload) as? [String: Any])
        XCTAssertEqual(payload["challenge"] as? String, AppAttestTestData.assertionChallenge)
    }

    func test_refresh_throws_whenNoKeyEnrolled() async throws {
        let tokenStore = MockIPProtectionTokenStore()
        let subject = try makeSubject(
            remoteServer: MockAppAttestRemoteServer(),
            keyStore: MockAppAttestKeyIDStore(),        // no keyId
            refresher: MockIPProtectionSessionRefresher(tokenStore: tokenStore),
            tokenStore: tokenStore
        )

        do {
            _ = try await subject.refresh()
            XCTFail("Expected refresh to throw without an enrolled key.")
        } catch let error as IPProtectionError {
            XCTAssertEqual(error, .notEnrolled)
        }
    }

    // MARK: - Fallbacks

    func test_authenticate_keepsValidCachedDSJ_whenRefreshFails() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: renewableSession)
        let refresher = MockIPProtectionSessionRefresher(tokenStore: tokenStore)
        refresher.refreshError = AppAttestServiceError.serverError(statusCode: 500, description: "down")
        let remoteServer = MockAppAttestRemoteServer()
        let subject = try makeSubject(
            remoteServer: remoteServer,
            keyStore: MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID),
            refresher: refresher,
            tokenStore: tokenStore
        )

        let result = try await subject.authenticate()

        XCTAssertEqual(result, "renewable-dsj", "Should fall back to the still-valid cached session")
        XCTAssertEqual(
            remoteServer.sendAttestationCallCount,
            0,
            "Must not re-attest while a valid session exists"
        )
    }

    func test_authenticate_rethrowsTransportError_andKeepsKey_whenSessionExpired() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: expiredSession)
        let keyStore = MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID)
        let refresher = MockIPProtectionSessionRefresher(tokenStore: tokenStore)
        refresher.refreshError = URLError(.notConnectedToInternet)
        let remoteServer = MockAppAttestRemoteServer()
        let subject = try makeSubject(
            remoteServer: remoteServer,
            keyStore: keyStore,
            refresher: refresher,
            tokenStore: tokenStore
        )

        do {
            _ = try await subject.authenticate()
            XCTFail("Expected authenticate to surface the transport error.")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        }

        XCTAssertEqual(
            keyStore.loadKeyID(),
            AppAttestTestData.keyID,
            "A transient network failure must not discard the attested key"
        )
        XCTAssertEqual(remoteServer.sendAttestationCallCount, 0, "Must not re-attest on a transport failure")
        XCTAssertEqual(tokenStore.clearCallCount, 0, "Must not clear the session on a transport failure")
    }

    func test_authenticate_rethrowsTransportError_andKeepsKey_whenNoSession() async throws {
        let tokenStore = MockIPProtectionTokenStore()
        let keyStore = MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID)
        let refresher = MockIPProtectionSessionRefresher(tokenStore: tokenStore)
        refresher.refreshError = URLError(.timedOut)
        let remoteServer = MockAppAttestRemoteServer()
        let subject = try makeSubject(
            remoteServer: remoteServer,
            keyStore: keyStore,
            refresher: refresher,
            tokenStore: tokenStore
        )

        do {
            _ = try await subject.authenticate()
            XCTFail("Expected authenticate to surface the transport error.")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        }

        XCTAssertEqual(
            keyStore.loadKeyID(),
            AppAttestTestData.keyID,
            "Having no cached session is not a reason to abandon the device identity"
        )
        XCTAssertEqual(remoteServer.sendAttestationCallCount, 0, "Must not re-attest on a transport failure")
    }

    func test_authenticate_reEnrolls_whenRefreshIsRejected_evenWithValidCache() async throws {
        // Past renewAfter but still 28 days from expiry, which is the window the ordering decides.
        let tokenStore = MockIPProtectionTokenStore(initial: renewableSession)
        let keyStore = MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID)
        let refresher = MockIPProtectionSessionRefresher(tokenStore: tokenStore)
        refresher.refreshError = AppAttestServiceError.serverError(statusCode: 401, description: "unknown-key-id")
        let subject = try makeSubject(
            remoteServer: enrollingServer(tokenStore: tokenStore),
            keyStore: keyStore,
            refresher: refresher,
            tokenStore: tokenStore
        )

        let result = try await subject.authenticate()

        XCTAssertEqual(
            result,
            "new-dsj",
            "A session the backend no longer recognizes must not be served just because it is unexpired"
        )
        XCTAssertEqual(keyStore.loadKeyID(), "mock-key-id", "Should attest a fresh key")
    }

    func test_authenticate_reEnrolls_whenRefreshIsRejected() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: expiredSession)
        let keyStore = MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID)
        let refresher = MockIPProtectionSessionRefresher(tokenStore: tokenStore)
        // The backend answers 401 with reason `dsj-device-not-found` once its device record is gone.
        refresher.refreshError = AppAttestServiceError.serverError(statusCode: 401, description: "dsj-device-not-found")
        let subject = try makeSubject(
            remoteServer: enrollingServer(tokenStore: tokenStore),
            keyStore: keyStore,
            refresher: refresher,
            tokenStore: tokenStore
        )

        let result = try await subject.authenticate()

        XCTAssertEqual(result, "new-dsj", "A rejected credential is only recoverable by re-enrolling")
        XCTAssertEqual(keyStore.loadKeyID(), "mock-key-id", "Should attest a fresh key")
    }

    func test_authenticate_rethrows_whenRefreshHitsServerOutage() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: expiredSession)
        let keyStore = MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID)
        let refresher = MockIPProtectionSessionRefresher(tokenStore: tokenStore)
        refresher.refreshError = AppAttestServiceError.serverError(statusCode: 503, description: "unavailable")
        let remoteServer = MockAppAttestRemoteServer()
        let subject = try makeSubject(
            remoteServer: remoteServer,
            keyStore: keyStore,
            refresher: refresher,
            tokenStore: tokenStore
        )

        do {
            _ = try await subject.authenticate()
            XCTFail("Expected authenticate to surface the outage.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(statusCode: 503, description: "unavailable"))
        }

        XCTAssertEqual(
            keyStore.loadKeyID(),
            AppAttestTestData.keyID,
            "An outage is retryable, so the attested key must survive"
        )
        XCTAssertEqual(remoteServer.sendAttestationCallCount, 0, "Must not re-attest on an outage")
    }

    func test_authenticate_keepsStaleSession_whenEnrollmentFails() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: expiredSession)
        let failingSession = MockURLSession(with: Data("boom".utf8), response: httpResponse(statusCode: 500))
        let server = IPProtectionAppAttestServer(with: .dev, urlSession: failingSession, tokenStore: tokenStore)
        let subject = try makeSubject(
            remoteServer: server,
            keyStore: MockAppAttestKeyIDStore(),   // no keyId, so refresh reports notEnrolled
            refresher: server,
            tokenStore: tokenStore
        )

        do {
            _ = try await subject.authenticate()
            XCTFail("Expected authenticate to throw when enrollment fails.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(statusCode: 500, description: "boom"))
        }

        XCTAssertEqual(
            tokenStore.load(),
            expiredSession,
            "A failed enrollment must not leave the device with neither a key nor a session"
        )
    }

    func test_authenticate_enrolls_whenNoSessionAndNoKey() async throws {
        let tokenStore = MockIPProtectionTokenStore()
        let keyStore = MockAppAttestKeyIDStore()
        let refresher = MockIPProtectionSessionRefresher(tokenStore: tokenStore)
        let subject = try makeSubject(
            remoteServer: enrollingServer(tokenStore: tokenStore),
            keyStore: keyStore,
            refresher: refresher,
            tokenStore: tokenStore
        )

        let result = try await subject.authenticate()

        XCTAssertEqual(result, "new-dsj")
        XCTAssertEqual(keyStore.loadKeyID(), "mock-key-id")
    }

    func test_authenticate_throws_whenEnrollmentFails() async throws {
        let tokenStore = MockIPProtectionTokenStore()
        let failingSession = MockURLSession(with: Data("boom".utf8), response: httpResponse(statusCode: 500))
        let server = IPProtectionAppAttestServer(with: .dev, urlSession: failingSession, tokenStore: tokenStore)
        let subject = try makeSubject(remoteServer: server, refresher: server, tokenStore: tokenStore)

        do {
            _ = try await subject.authenticate()
            XCTFail("Expected authenticate to throw when enrollment fails.")
        } catch let error as AppAttestServiceError {
            XCTAssertEqual(error, .serverError(statusCode: 500, description: "boom"))
        }
    }

    func test_reset_clearsKeyAndSession() async throws {
        let tokenStore = MockIPProtectionTokenStore(initial: freshSession)
        let keyStore = MockAppAttestKeyIDStore(initial: AppAttestTestData.keyID)
        let subject = try makeSubject(
            remoteServer: MockAppAttestRemoteServer(),
            keyStore: keyStore,
            refresher: MockIPProtectionSessionRefresher(tokenStore: tokenStore),
            tokenStore: tokenStore
        )

        try subject.reset()

        XCTAssertNil(tokenStore.load())
        XCTAssertNil(keyStore.loadKeyID())
    }

    // MARK: - Fixtures

    /// Valid and well inside its renewal window: no network expected.
    private var freshSession: IPProtectionDeviceSession {
        IPProtectionDeviceSession(
            deviceSessionJwt: "cached-dsj",
            expiresAtMilliseconds: 32503680000000,
            renewAfterMilliseconds: 32503600000000
        )
    }

    /// Still valid, but past its renewal timestamp, so a proactive refresh is due.
    private var renewableSession: IPProtectionDeviceSession {
        IPProtectionDeviceSession(
            deviceSessionJwt: "renewable-dsj",
            expiresAtMilliseconds: 32503680000000,
            renewAfterMilliseconds: 1000
        )
    }

    private var expiredSession: IPProtectionDeviceSession {
        IPProtectionDeviceSession(deviceSessionJwt: "old-dsj", expiresAtMilliseconds: 1000, renewAfterMilliseconds: 1000)
    }

    private var refreshedSession: IPProtectionDeviceSession {
        IPProtectionDeviceSession(
            deviceSessionJwt: "refreshed-dsj",
            expiresAtMilliseconds: 32503680000000,
            renewAfterMilliseconds: 32503600000000
        )
    }

    /// A real server fed combined challenge + enrollment JSON so both calls decode and a session
    /// is persisted.
    private func enrollingServer(tokenStore: IPProtectionTokenStore) -> IPProtectionAppAttestServer {
        let json = #"{"challenge":"c","deviceSessionJwt":"new-dsj","expiresAt":32503680000000,"renewAfter":32503600000000}"#
        let urlSession = MockURLSession(with: Data(json.utf8), response: httpResponse(statusCode: 200))
        return IPProtectionAppAttestServer(with: .dev, urlSession: urlSession, tokenStore: tokenStore)
    }

    private func makeSubject(
        remoteServer: AppAttestRemoteServerProtocol,
        keyStore: AppAttestKeyIDStore = MockAppAttestKeyIDStore(),
        refresher: IPProtectionSessionRefreshing,
        tokenStore: IPProtectionTokenStore
    ) throws -> IPProtectionAuthService {
        let client = try AppAttestClient(
            appAttestService: MockAppAttestService(isSupported: true),
            remoteServer: remoteServer,
            keyStore: keyStore
        )
        return IPProtectionAuthService(
            appAttestClient: client,
            sessionRefresher: refresher,
            tokenStore: tokenStore
        )
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
