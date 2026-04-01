// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import DeviceCheck
import Foundation

/// Protocol defining the requirements for an App Attest service.
public protocol AppAttestServiceProtocol: Sendable {
    var isSupported: Bool { get }
    func generateKey() async throws -> String
    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data
    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data
}

/// Extension to conform DCAppAttestService to AppAttestServiceProtocol so it's easier to mock in tests.
extension DCAppAttestService: AppAttestServiceProtocol {}
