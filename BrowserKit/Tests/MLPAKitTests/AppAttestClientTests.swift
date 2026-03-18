// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SummarizeKit

final class AppAttestClientTests: XCTestCase {
    func test_init_throwsWhenAppAttestNotSupported() {
        let service = MockAppAttestService(isSupported: false)
        // NOTE: This shouldn't happen in real devices since they all have access to this API.
        XCTAssertThrowsError(
            try createSubject(appAttestService: service),
            "Expected init to throw when App Attest is not supported."
        ) { error in
            XCTAssertEqual(error as? AppAttestServiceError, .appAttestNotSupported)
        }
    }

    func test_init_succeedsWhenAppAttestIsSupported() {
        XCTAssertNoThrow(
            try createSubject(),
            "Expected init to succeed when App Attest is supported."
        )
    }

    func test_performAttestation_returnsExistingKeyID_whenAlreadyStored() async throws {
        let keyStore = try createKeyStore(with: AppAttestTestData.keyID)
        let server = MockAppAttestRemoteServer()
        let subject = try createSubject(remoteServer: server, keyStore: keyStore)

        let result = try await subject.performAttestation()

        XCTAssertEqual(result, AppAttestTestData.keyID, "Expected to return the stored keyId without re-attesting.")
        XCTAssertEqual(server.fetchChallengeCallCount, 0, "Expected no server calls when key already exists.")
    }

    func test_performAttestation_generatesKeyAndAttests_whenNoStoredKey() async throws {
        let keyStore = MockAppAttestKeyIDStore()
        let server = makeServer(challenge: AppAttestTestData.attestationChallenge)
        let service = makeService(
            keyToReturn: AppAttestTestData.keyID,
            attestationToReturn: AppAttestTestData.attestationBlob
        )
        let subject = try createSubject(appAttestService: service, remoteServer: server, keyStore: keyStore)
        let result = try await subject.performAttestation()

        XCTAssertEqual(result, AppAttestTestData.keyID)
        XCTAssertEqual(keyStore.loadKeyID(), AppAttestTestData.keyID, "Expected keyId to be persisted after attestation.")
        XCTAssertEqual(server.fetchChallengeCallCount, 1)
        XCTAssertEqual(server.sendAttestationCallCount, 1)
    }

    func test_performAttestation_doesNotPersistKey_whenServerRejectsAttestation() async throws {
        let keyStore = MockAppAttestKeyIDStore()
        let server = makeServer(challenge: AppAttestTestData.attestationChallenge, sendAttestationError: .invalidPayload)
        let service = makeService(
            keyToReturn: AppAttestTestData.keyID,
            attestationToReturn: AppAttestTestData.attestationBlob
        )
        let subject = try createSubject(appAttestService: service, remoteServer: server, keyStore: keyStore)

        do {
            _ = try await subject.performAttestation()
            XCTFail("Expected performAttestation to throw when server rejects attestation.")
        } catch {
            XCTAssertNil(keyStore.loadKeyID(), "Expected keyId to NOT be persisted when attestation fails.")
        }
    }

    func test_generateAssertion_throwsMissingKeyID_whenNoStoredKey() async throws {
        let subject = try createSubject()

        do {
            _ = try await subject.generateAssertion(payload: ["prompt": "hello"])
            XCTFail("Expected generateAssertion to throw when no keyId is stored.")
        } catch {
            XCTAssertEqual(error as? AppAttestServiceError, .missingKeyID)
        }
    }

    func test_generateAssertion_returnsSignedResult() async throws {
        let keyStore = try createKeyStore(with: AppAttestTestData.keyID)
        let server = makeServer(challenge: AppAttestTestData.assertionChallenge)
        let service = makeService(assertionToReturn: AppAttestTestData.assertionBlob)
        let subject = try createSubject(appAttestService: service, remoteServer: server, keyStore: keyStore)

        let result = try await subject.generateAssertion(payload: ["prompt": "summarize this"])

        XCTAssertEqual(result.keyId, AppAttestTestData.keyID)
        XCTAssertEqual(result.assertion, AppAttestTestData.assertionBlob)
        XCTAssertEqual(result.challenge, AppAttestTestData.assertionChallenge)
        XCTAssertEqual(server.fetchChallengeCallCount, 1)
    }

    func test_resetKey_clearsStoredKeyID() throws {
        let keyStore = try createKeyStore(with: AppAttestTestData.keyID)
        let subject = try createSubject(keyStore: keyStore)
        try subject.resetKey()
        XCTAssertNil(keyStore.loadKeyID(), "Expected keyId to be cleared after resetKey().")
    }

    private func createSubject(
        appAttestService: AppAttestServiceProtocol = MockAppAttestService(isSupported: true),
        remoteServer: AppAttestRemoteServerProtocol = MockAppAttestRemoteServer(),
        keyStore: AppAttestKeyIDStore = MockAppAttestKeyIDStore()
    ) throws -> AppAttestClient {
        try AppAttestClient(
            appAttestService: appAttestService,
            remoteServer: remoteServer,
            keyStore: keyStore
        )
    }

    private func createKeyStore(with keyID: String) throws -> MockAppAttestKeyIDStore {
        let store = MockAppAttestKeyIDStore()
        try store.saveKeyID(keyID)
        return store
    }

    private func makeServer(
        challenge: String,
        sendAttestationError: AppAttestServiceError? = nil
    ) -> MockAppAttestRemoteServer {
        let server = MockAppAttestRemoteServer()
        server.challengeToReturn = challenge
        server.sendAttestationError = sendAttestationError
        return server
    }

    private func makeService(
        keyToReturn: String = "",
        attestationToReturn: Data = Data(),
        assertionToReturn: Data = Data()
    ) -> MockAppAttestService {
        let service = MockAppAttestService(isSupported: true)
        service.keyToReturn = keyToReturn
        service.attestationToReturn = attestationToReturn
        service.assertionToReturn = assertionToReturn
        return service
    }
}
