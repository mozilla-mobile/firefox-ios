// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum AppAttestTestData {
    public static let keyID = "test-key-id"
    public static let challenge = "test-challenge-123"
    public static let attestationChallenge = "attestation-challenge"
    public static let assertionChallenge = "assertion-challenge"
    public static let bundleID = "org.test.foo"
    public static let attestationBlob = Data("attestation-blob".utf8)
    public static let assertionBlob = Data("assertion-blob".utf8)
}
