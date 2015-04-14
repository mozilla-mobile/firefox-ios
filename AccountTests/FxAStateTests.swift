/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import FxA
import Shared
import XCTest

class FxAStateTests: XCTestCase {
    class func stateForLabel(label: FxAStateLabel) -> FxAState {
        let keyLength = UInt(KeyLength) // Ah, Swift.
        let now = NSDate.now()

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
        // Journal of Negative Results: make sure we aren't *always* succeeding.
        // This Married state will have an earlier timestamp than the one generated after the loop.
        let state1 = FxAStateTests.stateForLabel(.Married) as! MarriedState

        for stateLabel in FxAStateLabel.allValues {
            let state = FxAStateTests.stateForLabel(stateLabel)
            let d = state.asJSON()
            if let e = stateFromJSON(d)?.asJSON() {
                // We can't compare arbitrary Swift Dictionary instances directly, but the following appears to work.
                XCTAssertEqual(
                    NSDictionary(dictionary: JSON.unwrap(d) as! [String: AnyObject]),
                    NSDictionary(dictionary: JSON.unwrap(e) as! [String: AnyObject]))
            } else {
                XCTFail("Expected to create state.")
            }
        }

        // This Married state will have a later timestamp than the one generated before the loop.
        let state2 = FxAStateTests.stateForLabel(.Married) as! MarriedState
        // We can't compare arbitrary Swift Dictionary instances directly, but the following appears to work.
        XCTAssertNotEqual(
            NSDictionary(dictionary: JSON.unwrap(state1.asJSON()) as! [String: AnyObject]),
            NSDictionary(dictionary: JSON.unwrap(state2.asJSON()) as! [String: AnyObject]))
    }
}
