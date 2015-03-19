/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import FxA
import Shared
import XCTest

class FxAStateTests: XCTestCase {
    class func stateForLabel(label: FxAStateLabel) -> FxAState {
        let keyLength = UInt(KeyLength) // Ah, Swift.
        let now = Int64(NSDate().timeIntervalSince1970 * 1000)

        switch label {
        case .EngagedBeforeVerified:
            return EngagedBeforeVerifiedState(
                knownUnverifiedAt: now + 1, lastNotifiedUserAt: now + 2,
                sessionToken: NSData.randomOfLength(keyLength)!,
                keyFetchToken: NSData.randomOfLength(keyLength)!,
                unwrapkB: NSData.randomOfLength(keyLength)!)

        case .EngagedAfterVerified:
            return EngagedAfterVerifiedState(
                sessionToken: NSData.randomOfLength(keyLength)!,
                keyFetchToken: NSData.randomOfLength(keyLength)!,
                unwrapkB: NSData.randomOfLength(keyLength)!)

        case .CohabitingBeforeKeyPair:
            return CohabitingBeforeKeyPairState(sessionToken: NSData.randomOfLength(keyLength)!,
                kA: NSData.randomOfLength(keyLength)!, kB: NSData.randomOfLength(keyLength)!)

        case .CohabitingAfterKeyPair:
            let keyPair = RSAKeyPair.generateKeyPairWithModulusSize(512)
            return CohabitingAfterKeyPairState(sessionToken: NSData.randomOfLength(keyLength)!,
                kA: NSData.randomOfLength(keyLength)!, kB: NSData.randomOfLength(keyLength)!,
                keyPair: keyPair, keyPairExpiresAt: now + 1)

        case .Married:
            let keyPair = RSAKeyPair.generateKeyPairWithModulusSize(512)
            return MarriedState(sessionToken: NSData.randomOfLength(keyLength)!,
                kA: NSData.randomOfLength(keyLength)!, kB: NSData.randomOfLength(keyLength)!,
                keyPair: keyPair, keyPairExpiresAt: now + 1,
                certificate: "certificate", certificateExpiresAt: now + 2)

        case .Separated:
            return SeparatedState()

        case .Doghouse:
            return DoghouseState()
        }
    }

    func testSerialization() {
        for stateLabel in FxAStateLabel.allValues {
            let state = FxAStateTests.stateForLabel(stateLabel)
            let d = state.asDictionary()
            if let e = stateFromDictionary(d)?.asDictionary() {
                // We can't compare arbitrary Swift Dictionary instances directly, but the following appears to work.
                XCTAssertEqual(NSDictionary(dictionary: d), NSDictionary(dictionary: e))
            } else {
                XCTFail("Expected to create state.")
            }
        }
    }
}
