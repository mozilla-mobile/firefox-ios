// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation

public protocol IPProtectionAuthenticating: Sendable {
    /// Returns a valid session credential, refreshing or establishing one as needed
    func authenticate() async throws -> String

    /// Forces a credential refresh, bypassing the cached-credential short-circuit
    /// Throws `IPProtectionError.notEnrolled` when there is nothing to refresh with.
    func refresh() async throws -> String

    /// Clears all stored credentials, forcing a full enrollment on the next call
    func reset() throws

    /// The currently stored session, if any
    func currentSession() -> IPProtectionDeviceSession?
}

/// Manages the device's IP Protection session.
public struct IPProtectionAuthService: IPProtectionAuthenticating {
    private let appAttestClient: AppAttestClient
    private let sessionRefresher: IPProtectionSessionRefreshing
    private let tokenStore: IPProtectionTokenStore

    public init(
        appAttestClient: AppAttestClient,
        sessionRefresher: IPProtectionSessionRefreshing,
        tokenStore: IPProtectionTokenStore
    ) {
        self.appAttestClient = appAttestClient
        self.sessionRefresher = sessionRefresher
        self.tokenStore = tokenStore
    }

    public func authenticate() async throws -> String {
        let cached = tokenStore.load()

        if let cached, cached.isValid(), !cached.needsRenewal() {
            return cached.deviceSessionJwt
        }

        // Refreshing with the existing key preserves the device identity, and its quota bucket
        if let refreshed = try? await refresh() {
            return refreshed
        }

        // Prefer a stale-but-valid session over re-attesting: a new attestation creates a new device
        // record and inflates the App Attest risk metric
        if let cached, cached.isValid() {
            return cached.deviceSessionJwt
        }

        return try await enroll()
    }

    public func refresh() async throws -> String {
        let assertion: AssertionResult
        do {
            assertion = try await appAttestClient.generateChallengeBoundAssertion()
        } catch AppAttestServiceError.missingKeyID {
            throw IPProtectionError.notEnrolled
        }
        try await sessionRefresher.refreshSession(assertion: assertion)

        guard let session = tokenStore.load() else {
            throw IPProtectionError.sessionNotPersisted
        }
        return session.deviceSessionJwt
    }

    public func reset() throws {
        try appAttestClient.resetKey()
        try tokenStore.clear()
    }

    public func currentSession() -> IPProtectionDeviceSession? {
        return tokenStore.load()
    }

    /// Resets first because a stored `keyId` can outlive the Secure Enclave key it names, and
    /// `performAttestation()` short-circuits on any stored `keyId`.
    private func enroll() async throws -> String {
        try reset()
        _ = try await appAttestClient.performAttestation()

        guard let session = tokenStore.load() else {
            throw IPProtectionError.sessionNotPersisted
        }
        return session.deviceSessionJwt
    }
}
