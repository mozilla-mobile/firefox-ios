// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation

public final class MockAppAttestService: AppAttestServiceProtocol, @unchecked Sendable {
    public let isSupported: Bool
    public var keyToReturn = "mock-key-id"
    public var attestationToReturn = Data()
    public var assertionToReturn = Data()

    public init(isSupported: Bool) {
        self.isSupported = isSupported
    }

    public func generateKey() async throws -> String {
        return keyToReturn
    }

    public func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        return attestationToReturn
    }
    public func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        return assertionToReturn
    }
}
