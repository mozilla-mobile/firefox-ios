// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CryptoKit
import DeviceCheck

/// Manages the App Attest attestation and assertion flows.
///
/// This client ties together three concerns:
/// - `AppAttestServiceProtocol`:  Apple's on-device key generation, attestation, and assertion APIs.
/// - `AppAttestRemoteServer`: the server that validates attestations and assertions.
/// - `AppAttestKeyIDStore`: local persistence for the `keyId` across app launches.
///
/// For details on the attestation/assertion flow, See:
/// - Secure API Access using App Attest: https://docs.google.com/document/d/1uI5pl2h60_9tjiAqEdKBZD9JANQdcHP7lXSe5uxCPrg/edit?usp=sharing
/// - Apple Docs: https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity
/// For concrete usage for MLPA (Mozilla LLM Proxy Auth), See:
/// - https://docs.google.com/document/d/1xnCHRxNolNS25sKiAZPxtrovKahkYHZ3aVqc_FMyJv0/edit?usp=sharing
public struct AppAttestClient {
    private let appAttestService: AppAttestServiceProtocol
    private let remoteServer: AppAttestRemoteServerProtocol
    private let keyStore: AppAttestKeyIDStore

    public init(appAttestService: AppAttestServiceProtocol = DCAppAttestService.shared,
                remoteServer: AppAttestRemoteServerProtocol,
                keyStore: AppAttestKeyIDStore = KeychainAppAttestKeyIDStore()) throws {
        guard appAttestService.isSupported else {
            throw AppAttestServiceError.appAttestNotSupported
        }
        self.appAttestService = appAttestService
        self.remoteServer = remoteServer
        self.keyStore = keyStore
    }

    /// Performs the one-time attestation flow to establish device trust with the server.
    ///
    /// If a `keyId` already exists in the store (i.e. attestation was done previously),
    /// this returns immediately without re-attesting.
    ///
    /// Steps:
    /// 1. Generate a hardware-backed keypair via `appAttestService.generateKey()`.
    /// 2. Fetch a challenge from the server (prevents replay attacks).
    /// 3. Attest the key using `appAttestService` to produce an attestation object that bundles the public key
    ///    and a statement signed by Apple's certificate chain.
    /// 4. Send the attestation to the server for validation and public key storage.
    /// 5. Persist the `keyId` locally so subsequent calls skip re-attestation.
    public func performAttestation() async throws -> String {
        if let existingKey = keyStore.loadKeyID() {
            return existingKey
        }

        let keyID = try await appAttestService.generateKey()
        let challenge = try await remoteServer.fetchChallenge(for: keyID)

        guard let challengeData = challenge.data(using: .utf8) else {
            throw AppAttestServiceError.invalidChallenge
        }

        // Apple requires a SHA-256 hash of the client data, not the raw bytes.
        let clientDataHash = Data(SHA256.hash(data: challengeData))
        let attestation = try await appAttestService.attestKey(keyID, clientDataHash: clientDataHash)

        try await remoteServer.sendAttestation(
            keyId: keyID,
            attestationObject: attestation,
            challenge: challenge
        )

        try keyStore.saveKeyID(keyID)
        return keyID
    }

    /// Performs a per-request assertion, meaning it signs the payload and sends it to the server.
    ///
    /// Steps:
    /// 1. Load the previously attested `keyId` from the store.
    /// 2. Fetch a fresh challenge from the server (prevents replay attacks).
    /// 3. Serialize the payload as sorted-key JSON and hash it with SHA-256.
    /// 4. Ask the Secure Enclave to sign the hash via `appAttestService.generateAssertion()`.
    /// 5. Send the assertion + payload to the server for verification.
    public func performAssertion(payload: [String: Any]) async throws {
        guard let keyId = keyStore.loadKeyID() else {
            throw AppAttestServiceError.missingKeyID
        }

        let challenge = try await remoteServer.fetchChallenge(for: keyId)

        // Sorted keys ensures both client and server hash identical bytes the same way. 
        // Otherwise the same JSON with different key orders would produce different hashes and fail verification.
        let clientData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])

        let clientDataHash = Data(SHA256.hash(data: clientData))
        let assertion = try await appAttestService.generateAssertion(keyId, clientDataHash: clientDataHash)

        let payloadData = try JSONSerialization.data(withJSONObject: payload)

        try await remoteServer.sendAssertion(
            keyId: keyId,
            assertionObject: assertion,
            payload: payloadData,
            challenge: challenge
        )
    }

    /// Clears the locally stored `keyId`, forcing re-attestation on the next call.
    /// This will be called for QA purposes to allow testers to reset the attestation state.
    public func resetKey() throws {
        try keyStore.clearKeyID()
    }
}
