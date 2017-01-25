/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA
import Shared
import XCGLogger
import Deferred

// TODO: log to an FxA-only, persistent log file.
private let log = Logger.syncLogger

// TODO: fill this in!
private let KeyUnwrappingError = NSError(domain: "org.mozilla", code: 1, userInfo: nil)

protocol FxALoginClient {
    func keyPair() -> Deferred<Maybe<KeyPair>>
    func keys(_ keyFetchToken: Data) -> Deferred<Maybe<FxAKeysResponse>>
    func sign(_ sessionToken: Data, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>>
}

class FxALoginStateMachine {
    let client: FxALoginClient

    // The keys are used as a set, to prevent cycles in the state machine.
    var stateLabelsSeen = [FxAStateLabel: Bool]()

    init(client: FxALoginClient) {
        self.client = client
    }

    func advance(fromState state: FxAState, now: Timestamp) -> Deferred<FxAState> {
        stateLabelsSeen.updateValue(true, forKey: state.label)
        return self.advanceOne(fromState: state, now: now).bind { (newState: FxAState) in
            let labelAlreadySeen = self.stateLabelsSeen.updateValue(true, forKey: newState.label) != nil
            if labelAlreadySeen {
                // Last stop!
                return Deferred(value: newState)
            }
            return self.advance(fromState: newState, now: now)
        }
    }

    fileprivate func advanceOne(fromState state: FxAState, now: Timestamp) -> Deferred<FxAState> {
        // For convenience.  Without type annotation, Swift complains about types not being exact.
        let separated: Deferred<FxAState> = Deferred(value: SeparatedState())
        let doghouse: Deferred<FxAState> = Deferred(value: DoghouseState())
        let same: Deferred<FxAState> = Deferred(value: state)

        log.info("Advancing from state: \(state.label.rawValue)")
        switch state.label {
        case .married:
            let state = state as! MarriedState
            log.debug("Checking key pair freshness.")
            if state.isKeyPairExpired(now) {
                log.info("Key pair has expired; transitioning to CohabitingBeforeKeyPair.")
                return advanceOne(fromState: state.withoutKeyPair(), now: now)
            }
            log.debug("Checking certificate freshness.")
            if state.isCertificateExpired(now) {
                log.info("Certificate has expired; transitioning to CohabitingAfterKeyPair.")
                return advanceOne(fromState: state.withoutCertificate(), now: now)
            }
            log.info("Key pair and certificate are fresh; staying Married.")
            return same

        case .cohabitingBeforeKeyPair:
            let state = state as! CohabitingBeforeKeyPairState
            log.debug("Generating key pair.")
            return self.client.keyPair().bind { result in
                if let keyPair = result.successValue {
                    log.info("Generated key pair!  Transitioning to CohabitingAfterKeyPair.")
                    let newState = CohabitingAfterKeyPairState(sessionToken: state.sessionToken,
                        kA: state.kA, kB: state.kB,
                        keyPair: keyPair, keyPairExpiresAt: now + OneMonthInMilliseconds)
                    return Deferred(value: newState)
                } else {
                    log.error("Failed to generate key pair!  Something is horribly wrong; transitioning to Separated in the hope that the error is transient.")
                    return separated
                }
            }

        case .cohabitingAfterKeyPair:
            let state = state as! CohabitingAfterKeyPairState
            log.debug("Signing public key.")
            return client.sign(state.sessionToken, publicKey: state.keyPair.publicKey).bind { result in
                if let response = result.successValue {
                    log.info("Signed public key!  Transitioning to Married.")
                    let newState = MarriedState(sessionToken: state.sessionToken,
                        kA: state.kA, kB: state.kB,
                        keyPair: state.keyPair, keyPairExpiresAt: state.keyPairExpiresAt,
                        certificate: response.certificate, certificateExpiresAt: now + OneDayInMilliseconds)
                    return Deferred(value: newState)
                } else {
                    if let error = result.failureValue as? FxAClientError {
                        switch error {
                        case let .remote(remoteError):
                            if remoteError.isUpgradeRequired {
                                log.error("Upgrade required: \(error.description)!  Transitioning to Doghouse.")
                                return doghouse
                            } else if remoteError.isInvalidAuthentication {
                                log.error("Invalid authentication: \(error.description)!  Transitioning to Separated.")
                                return separated
                            } else if remoteError.code < 200 || remoteError.code >= 300 {
                                log.error("Unsuccessful HTTP request: \(error.description)!  Assuming error is transient and not transitioning.")
                                return same
                            } else {
                                log.error("Unknown error: \(error.description).  Transitioning to Separated.")
                                return separated
                            }
                        case let .local(localError) where localError.domain == NSURLErrorDomain:
                            log.warning("Local networking error: \(result.failureValue!).  Assuming transient and not transitioning.")
                            return same
                        default:
                            break
                        }
                    }
                    log.error("Unknown error: \(result.failureValue!).  Transitioning to Separated.")
                    return separated
                }
            }

        case .engagedBeforeVerified, .engagedAfterVerified:
            let state = state as! ReadyForKeys
            log.debug("Fetching keys.")
            return client.keys(state.keyFetchToken).bind { result in
                if let response = result.successValue {
                    if let kB = response.wrapkB.xoredWith(state.unwrapkB) {
                        log.info("Unwrapped keys response.  Transition to CohabitingBeforeKeyPair.")
                        let newState = CohabitingBeforeKeyPairState(sessionToken: state.sessionToken,
                            kA: response.kA, kB: kB)
                        return Deferred(value: newState)
                    } else {
                        log.error("Failed to unwrap keys response!  Transitioning to Separated in order to fetch new initial datum.")
                        return separated
                    }
                } else {
                    if let error = result.failureValue as? FxAClientError {
                        log.error("Error \(error.description) \(error.description)")
                        switch error {
                        case let .remote(remoteError):
                            if remoteError.isUpgradeRequired {
                                log.error("Upgrade required: \(error.description)!  Transitioning to Doghouse.")
                                return doghouse
                            } else if remoteError.isInvalidAuthentication {
                                log.error("Invalid authentication: \(error.description)!  Transitioning to Separated in order to fetch new initial datum.")
                                return separated
                            } else if remoteError.isUnverified {
                                log.warning("Account is not yet verified; not transitioning.")
                                return same
                            } else if remoteError.code < 200 || remoteError.code >= 300 {
                                log.error("Unsuccessful HTTP request: \(error.description)!  Assuming error is transient and not transitioning.")
                                return same
                            } else {
                                log.error("Unknown error: \(error.description).  Transitioning to Separated.")
                                return separated
                            }
                        case let .local(localError) where localError.domain == NSURLErrorDomain:
                            log.warning("Local networking error: \(result.failureValue!).  Assuming transient and not transitioning.")
                            return same
                        default:
                            break
                        }
                    }
                    log.error("Unknown error: \(result.failureValue!).  Transitioning to Separated.")
                    return separated
                }
            }

        case .separated, .doghouse:
            // We can't advance from the separated state (we need user input) or the doghouse (we need a client upgrade).
            log.warning("User interaction required; not transitioning.")
            return same
        }
    }
}
