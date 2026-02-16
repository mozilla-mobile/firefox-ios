// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SummarizeKit

final class MockAppAttestService: AppAttestServiceProtocol {
    let isSupported: Bool
    var keyToReturn = "mock-key-id"
    var attestationToReturn = Data()
    var assertionToReturn = Data()

    init(isSupported: Bool) {
        self.isSupported = isSupported
    }

    func generateKey() async throws -> String {
        return keyToReturn
    }

    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        return attestationToReturn
    }
    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        return assertionToReturn
    }
}
