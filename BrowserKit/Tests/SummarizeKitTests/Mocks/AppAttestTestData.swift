// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import SummarizeKit

enum AppAttestTestData {
    static let keyID = "test-key-id"
    static let challenge = "test-challenge-123"
    static let attestationChallenge = "attestation-challenge"
    static let assertionChallenge = "assertion-challenge"
    static let bundleID = "org.test.foo"
    static let attestationBlob = Data("attestation-blob".utf8)
    static let attestationKey = MLPAConstants.attestationObjParam
    static let assertionKey = MLPAConstants.assertionObjParam
    static let assertionBlob = Data("assertion-blob".utf8)
    static let requestURL = URL(string: "https://example.com/api/summarize")!
    static var requestBody: [String: Any] { ["prompt": "summarize this"] }
}
