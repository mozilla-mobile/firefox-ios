// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SummarizeKit

final class MockAppAttestRemoteServer: AppAttestRemoteServerProtocol, @unchecked Sendable {
    var challengeToReturn = "mock-challenge"
    var sendAttestationError: Error?

    private(set) var fetchChallengeCallCount = 0
    private(set) var sendAttestationCallCount = 0
    private(set) var lastAssertionKeyId: String?

    func fetchChallenge(for keyId: String) async throws -> String {
        fetchChallengeCallCount += 1
        return challengeToReturn
    }

    func sendAttestation(keyId: String, attestationObject: Data, challenge: String) async throws {
        sendAttestationCallCount += 1
        if let error = sendAttestationError { throw error }
    }
}
