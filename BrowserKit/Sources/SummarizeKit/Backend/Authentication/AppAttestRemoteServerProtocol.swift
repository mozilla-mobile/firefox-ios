// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Defines the server-side contract for the App Attest flow.
///
/// The flow has three server interactions/endpoints:
/// 1. An endpoint to fetch a random challenge, meaning a one-time nonce to prevent replay attacks.
/// 2. An endpoint to send attestation. This is a one-time trust setup. The server verifies Apple's certificate chain
///    and stores the public key keyed by a `keyId`.
/// 3. An endpoint to send an assertion. This is a per-request authentication; server verifies the signature
///    against the previously stored public key from step 2.
///
/// For full details on how these steps fit together, See:
/// - Secure API Access using App Attest: https://docs.google.com/document/d/1uI5pl2h60_9tjiAqEdKBZD9JANQdcHP7lXSe5uxCPrg/edit?usp=sharing
/// - Apple Docs: https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity
public protocol AppAttestRemoteServerProtocol {
    /// Fetches a server-generated challenge (nonce) for the given `keyId`.
    /// The challenge is used exactly once to prevent replay attacks.
    func fetchChallenge(for keyId: String) async throws -> String
    /// Sends the attestation object to the server for one-time trust establishment.
    /// The server validates Apple's certificate chain and persists the public key.
    func sendAttestation(keyId: String, attestationObject: Data, challenge: String) async throws
    /// Sends an assertion-signed request to the server.
    /// The server verifies the signature against the stored public key.
    func sendAssertion(keyId: String, assertionObject: Data, payload: Data, challenge: String) async throws
}
