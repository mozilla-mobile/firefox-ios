/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import FxA
import Shared

import XCTest

class MockFxALoginClient: FxALoginClient {
    // Fixed per mock client, for testing.
    let kA = NSData.randomOfLength(UInt(KeyLength))!
    let wrapkB = NSData.randomOfLength(UInt(KeyLength))!

    func keyPair() -> Deferred<Maybe<KeyPair>> {
        let keyPair: KeyPair = RSAKeyPair.generateKeyPairWithModulusSize(512)
        return Deferred(value: Maybe(success: keyPair))
    }

    func keys(keyFetchToken: NSData) -> Deferred<Maybe<FxAKeysResponse>> {
        let response = FxAKeysResponse(kA: kA, wrapkB: wrapkB)
        return Deferred(value: Maybe(success: response))
    }

    func sign(sessionToken: NSData, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let response = FxASignResponse(certificate: "certificate")
        return Deferred(value: Maybe(success: response))
    }
}

// A mock client that fails locally (i.e., cannot connect to the network).
class MockFxALoginClientWithoutNetwork: MockFxALoginClient {
    override func keys(keyFetchToken: NSData) -> Deferred<Maybe<FxAKeysResponse>> {
        // Fail!
        return Deferred(value: Maybe(failure: FxAClientError.Local(NSError(domain: NSURLErrorDomain, code: -1000, userInfo: nil))))
    }

    override func sign(sessionToken: NSData, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        // Fail!
        return Deferred(value: Maybe(failure: FxAClientError.Local(NSError(domain: NSURLErrorDomain, code: -1000, userInfo: nil))))
    }
}

// A mock client that responds to keys and sign with 401 errors.
class MockFxALoginClientAfterPasswordChange: MockFxALoginClient {
    override func keys(keyFetchToken: NSData) -> Deferred<Maybe<FxAKeysResponse>> {
        let response = FxAClientError.Remote(RemoteError(code: 401, errno: 103, error: "Bad auth", message: "Bad auth message", info: "Bad auth info"))
        return Deferred(value: Maybe(failure: response))
    }

    override func sign(sessionToken: NSData, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let response = FxAClientError.Remote(RemoteError(code: 401, errno: 103, error: "Bad auth", message: "Bad auth message", info: "Bad auth info"))
        return Deferred(value: Maybe(failure: response))
    }
}

// A mock client that responds to keys with 400/104 (needs verification responses).
class MockFxALoginClientBeforeVerification: MockFxALoginClient {
    override func keys(keyFetchToken: NSData) -> Deferred<Maybe<FxAKeysResponse>> {
        let response = FxAClientError.Remote(RemoteError(code: 400, errno: 104,
            error: "Unverified", message: "Unverified message", info: "Unverified info"))
        return Deferred(value: Maybe(failure: response))
    }
}

// A mock client that responds to sign with 503/999 (unknown server error).
class MockFxALoginClientDuringOutage: MockFxALoginClient {
    override func sign(sessionToken: NSData, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let response = FxAClientError.Remote(RemoteError(code: 503, errno: 999,
            error: "Unknown", message: "Unknown error", info: "Unknown err info"))
        return Deferred(value: Maybe(failure: response))
    }
}

class FxALoginStateMachineTests: XCTestCase {
    let marriedState = FxAStateTests.stateForLabel(FxAStateLabel.Married) as! MarriedState

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func withMachine(client: FxALoginClient, callback: (FxALoginStateMachine) -> Void) {
        let stateMachine = FxALoginStateMachine(client: client)
        callback(stateMachine)
    }

    func withMachineAndClient(callback: (FxALoginStateMachine, MockFxALoginClient) -> Void) {
        let client = MockFxALoginClient()
        withMachine(client) { stateMachine in
            callback(stateMachine, client)
        }
    }

    func testAdvanceWhenInteractionRequired() {
        // The simple cases are when we get to Separated and Doghouse.  There's nothing to do!
        // We just have to wait for user interaction.
        for stateLabel in [FxAStateLabel.Separated, FxAStateLabel.Doghouse] {
            let e = expectationWithDescription("Wait for login state machine.")
            let state = FxAStateTests.stateForLabel(stateLabel)
            withMachineAndClient { stateMachine, _ in
                stateMachine.advanceFromState(state, now: 0).upon { newState in
                    XCTAssertEqual(newState.label, stateLabel)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAdvanceFromEngagedBeforeVerified() {
        // Advancing from engaged before verified stays put.
        let e = self.expectationWithDescription("Wait for login state machine.")
        let engagedState = (FxAStateTests.stateForLabel(.EngagedBeforeVerified) as! EngagedBeforeVerifiedState)
        withMachine(MockFxALoginClientBeforeVerification()) { stateMachine in
            stateMachine.advanceFromState(engagedState, now: engagedState.knownUnverifiedAt).upon { newState in
                XCTAssertEqual(newState.label.rawValue, engagedState.label.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAdvanceFromEngagedAfterVerified() {
        // Advancing from an Engaged state correctly XORs the keys.
        withMachineAndClient { stateMachine, client in
            // let unwrapkB = Bytes.generateRandomBytes(UInt(KeyLength))
            let unwrapkB = client.wrapkB // This way we get all 0s, which is easy to test.
            let engagedState = (FxAStateTests.stateForLabel(.EngagedAfterVerified) as! EngagedAfterVerifiedState).withUnwrapKey(unwrapkB)

            let e = self.expectationWithDescription("Wait for login state machine.")
            stateMachine.advanceFromState(engagedState, now: 0).upon { newState in
                XCTAssertEqual(newState.label.rawValue, FxAStateLabel.Married.rawValue)
                if let newState = newState as? MarriedState {
                    // We get kA from the client directly.
                    XCTAssertEqual(newState.kA.hexEncodedString, client.kA.hexEncodedString)
                    // We unwrap kB by XORing.  The result is KeyLength (32) 0s.
                    XCTAssertEqual(newState.kB.hexEncodedString, "0000000000000000000000000000000000000000000000000000000000000000")
                }
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAdvanceFromEngagedAfterVerifiedWithoutNetwork() {
        // Advancing from engaged after verified, but during outage, stays put.
        withMachine(MockFxALoginClientWithoutNetwork()) { stateMachine in
            let engagedState = FxAStateTests.stateForLabel(.EngagedAfterVerified)

            let e = self.expectationWithDescription("Wait for login state machine.")
            stateMachine.advanceFromState(engagedState, now: 0).upon { newState in
                XCTAssertEqual(newState.label.rawValue, engagedState.label.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAdvanceFromCohabitingAfterVerifiedDuringOutage() {
        // Advancing from engaged after verified, but during outage, stays put.
        let e = self.expectationWithDescription("Wait for login state machine.")
        let state = (FxAStateTests.stateForLabel(.CohabitingAfterKeyPair) as! CohabitingAfterKeyPairState)
        withMachine(MockFxALoginClientDuringOutage()) { stateMachine in
            stateMachine.advanceFromState(state, now: 0).upon { newState in
                XCTAssertEqual(newState.label.rawValue, state.label.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAdvanceFromCohabitingAfterVerifiedWithoutNetwork() {
        // Advancing from cohabiting after verified, but when the network is not available, stays put.
        let e = self.expectationWithDescription("Wait for login state machine.")
        let state = (FxAStateTests.stateForLabel(.CohabitingAfterKeyPair) as! CohabitingAfterKeyPairState)
        withMachine(MockFxALoginClientWithoutNetwork()) { stateMachine in
            stateMachine.advanceFromState(state, now: 0).upon { newState in
                XCTAssertEqual(newState.label.rawValue, state.label.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAdvanceFromMarried() {
        // Advancing from a healthy Married state is easy.
        let e = self.expectationWithDescription("Wait for login state machine.")
        withMachineAndClient { stateMachine, _ in
            stateMachine.advanceFromState(self.marriedState, now: 0).upon { newState in
                XCTAssertEqual(newState.label, FxAStateLabel.Married)
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAdvanceFromMarriedWithExpiredCertificate() {
        // Advancing from a Married state with an expired certificate gets back to Married.
        let e = self.expectationWithDescription("Wait for login state machine.")
        let now = self.marriedState.certificateExpiresAt + OneWeekInMilliseconds + 1
        withMachineAndClient { stateMachine, _ in
            stateMachine.advanceFromState(self.marriedState, now: now).upon { newState in
                XCTAssertEqual(newState.label.rawValue, FxAStateLabel.Married.rawValue)
                if let newState = newState as? MarriedState {
                    // We should have a fresh certificate.
                    XCTAssertLessThan(self.marriedState.certificateExpiresAt, now)
                    XCTAssertGreaterThan(newState.certificateExpiresAt, now)
                }
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAdvanceFromMarriedWithExpiredKeyPair() {
        // Advancing from a Married state with an expired keypair gets back to Married too.
        let e = self.expectationWithDescription("Wait for login state machine.")
        let now = self.marriedState.certificateExpiresAt + OneMonthInMilliseconds + 1
        withMachineAndClient { stateMachine, _ in
            stateMachine.advanceFromState(self.marriedState, now: now).upon { newState in
                XCTAssertEqual(newState.label.rawValue, FxAStateLabel.Married.rawValue)
                if let newState = newState as? MarriedState {
                    // We should have a fresh key pair (and certificate, but we don't verify that).
                    XCTAssertLessThan(self.marriedState.keyPairExpiresAt, now)
                    XCTAssertGreaterThan(newState.keyPairExpiresAt, now)
                }
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAdvanceFromMarriedAfterPasswordChange() {
        // Advancing from a Married state with a 401 goes to Separated if it needs a new certificate.
        let e = self.expectationWithDescription("Wait for login state machine.")
        let now = self.marriedState.certificateExpiresAt + OneDayInMilliseconds + 1
        withMachine(MockFxALoginClientAfterPasswordChange()) { stateMachine in
            stateMachine.advanceFromState(self.marriedState, now: now).upon { newState in
                XCTAssertEqual(newState.label.rawValue, FxAStateLabel.Separated.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
