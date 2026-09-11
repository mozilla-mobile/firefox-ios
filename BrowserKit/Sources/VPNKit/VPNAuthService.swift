// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation

public protocol VPNAuthenticating: Sendable {
    /// Returns a valid session credential, refreshing or establishing one as needed
    func authenticate() async throws -> String

    /// Forces a credential refresh, bypassing the cached-credential short-circuit
    /// Throws `VPNAuthError.notEnrolled` when there is nothing to refresh with.
    func refresh() async throws -> String

    /// Clears all stored credentials, forcing a full enrollment on the next call
    func reset() throws

    /// The currently stored session, if any
    func currentSession() -> VPNDeviceSession?
}

/// Manages the device's VPN session.
struct VPNAuthService: VPNAuthenticating {
    private let appAttestClient: AppAttestClient
    private let sessionRefresher: VPNSessionRefreshing
    private let tokenStore: VPNTokenStore

    init(
        appAttestClient: AppAttestClient,
        sessionRefresher: VPNSessionRefreshing,
        tokenStore: VPNTokenStore
    ) {
        self.appAttestClient = appAttestClient
        self.sessionRefresher = sessionRefresher
        self.tokenStore = tokenStore
    }

    func authenticate() async throws -> String {
        let cached = tokenStore.load()

        if let cached, cached.isValid(), !cached.needsRenewal() {
            return cached.deviceSessionJwt
        }

        do {
            // Refreshing with the existing key preserves the device identity, and its quota bucket
            return try await refresh()
        } catch {
            // A rejected key outranks the cache: the session is only meaningful to a backend that
            // still has our device record, so serving it would 401 until it expires 30 days later
            if VPNAuthError.indicatesLostEnrollment(error) {
                return try await enroll()
            }

            // Prefer a stale-but-valid session over re-attesting: a new attestation creates a new
            // device record and inflates the App Attest risk metric
            if let cached, cached.isValid() {
                return cached.deviceSessionJwt
            }

            throw error
        }
    }

    func refresh() async throws -> String {
        let assertion: AssertionResult
        do {
            assertion = try await appAttestClient.generateChallengeBoundAssertion()
        } catch AppAttestServiceError.missingKeyID {
            throw VPNAuthError.notEnrolled
        }
        try await sessionRefresher.refreshSession(assertion: assertion)

        guard let session = tokenStore.load() else {
            throw VPNAuthError.sessionNotPersisted
        }
        return session.deviceSessionJwt
    }

    func reset() throws {
        try appAttestClient.resetKey()
        try tokenStore.clear()
    }

    func currentSession() -> VPNDeviceSession? {
        return tokenStore.load()
    }

    /// Clears the key first because `performAttestation()` returns early if we have any stored `keyId`, which
    /// can outlive its Secure Enclave key. The session survives until enrollment replaces it.
    private func enroll() async throws -> String {
        let staleSession = tokenStore.load()
        try appAttestClient.resetKey()
        _ = try await appAttestClient.performAttestation()

        guard let session = tokenStore.load(), session != staleSession else {
            throw VPNAuthError.sessionNotPersisted
        }
        return session.deviceSessionJwt
    }
}
