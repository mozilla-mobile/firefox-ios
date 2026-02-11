// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Persists the App Attest key identifier (`keyId`) locally.
///
/// A `keyId` is the opaque handle returned by `DCAppAttestService.generateKey()`.
/// It refers to a hardware-backed keypair generated in a Secure Enclave inside Apple Devices.
/// The `keyId` is used to establish per-device trust and usage tracking on the server side. 
/// The `keyId` must survive app launches. Losing it means re-attestation and resetting any server-side counters.
///
/// This store persists only the identifier, not the private key material.
///
/// There are two implementations of this protocol:
/// - `KeychainAppAttestKeyIDStore`: Production (Keychain-backed) used for MLPA ( Mozilla LLM Proxy Auth).
/// - `MockAppAttestKeyIDStore`: Unit tests (lightweight, deterministic).
///
/// For details on the attestation/assertion flow, see:
/// - Establishing Your App's Integrity: https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity
/// - DCAppAttestService: https://developer.apple.com/documentation/devicecheck/dcappattestservice
/// - Secure API Access using App Attest: https://docs.google.com/document/d/1uI5pl2h60_9tjiAqEdKBZD9JANQdcHP7lXSe5uxCPrg/edit?tab=t.0
/// - MLPA: https://docs.google.com/document/d/1xnCHRxNolNS25sKiAZPxtrovKahkYHZ3aVqc_FMyJv0/edit?tab=t.7yctgzn2nekp#heading=h.ihbllvivx85y
public protocol AppAttestKeyIDStore {
    func loadKeyID() -> String?
    func saveKeyID(_ keyID: String) throws
    func clearKeyID() throws
}
