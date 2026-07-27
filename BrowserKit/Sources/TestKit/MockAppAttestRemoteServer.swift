// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation

public final class MockAppAttestRemoteServer: AppAttestRemoteServerProtocol, @unchecked Sendable {
    public var challengeToReturn = "mock-challenge"
    public var sendAttestationError: Error?

    public private(set) var fetchChallengeCallCount = 0
    public private(set) var sendAttestationCallCount = 0
    public private(set) var lastAssertionKeyId: String?

    public init() {}

    public func fetchChallenge(for keyId: String) async throws -> String {
        fetchChallengeCallCount += 1
        return challengeToReturn
    }

    public func sendAttestation(keyId: String, attestationObject: Data, challenge: String) async throws {
        sendAttestationCallCount += 1
        if let error = sendAttestationError { throw error }
    }
}
