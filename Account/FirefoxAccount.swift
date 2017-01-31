/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred
import SwiftyJSON

private let log = Logger.syncLogger

// The version of the account schema we persist.
let AccountSchemaVersion = 1

/// A FirefoxAccount mediates access to identity attached services.
///
/// All data maintained as part of the account or its state should be
/// considered sensitive and stored appropriately.  Usually, that means
/// storing account data in the iOS keychain.
///
/// Non-sensitive but persistent data should be maintained outside of
/// the account itself.
open class FirefoxAccount {
    /// The email address identifying the account.  A Firefox Account is uniquely identified on a particular server
    /// (auth endpoint) by its email address.
    open let email: String

    /// The auth endpoint user identifier identifying the account.  A Firefox Account is uniquely identified on a
    /// particular server (auth endpoint) by its assigned uid.
    open let uid: String

    open var deviceRegistration: FxADeviceRegistration?

    open let configuration: FirefoxAccountConfiguration

    open var pushRegistration: PushRegistration?

    fileprivate let stateCache: KeychainCache<FxAState>
    open var syncAuthState: SyncAuthState! // We can't give a reference to self if this is a let.

    // To prevent advance() consumers racing, we maintain a shared advance() deferred (`advanceDeferred`).  If an
    // advance() is in progress, the shared deferred will be returned.  (Multiple consumers can chain off a single
    // deferred safely.)  If no advance() is in progress, a new shared deferred will be scheduled and returned.  To
    // prevent data races against the shared deferred, advance() locks accesses to `advanceDeferred` using
    // `advanceLock`.
    fileprivate var advanceLock = OSSpinLock()
    fileprivate var advanceDeferred: Deferred<FxAState>?

    open var actionNeeded: FxAActionNeeded {
        return stateCache.value!.actionNeeded
    }

    public convenience init(configuration: FirefoxAccountConfiguration, email: String, uid: String, deviceRegistration: FxADeviceRegistration?, stateKeyLabel: String, state: FxAState) {
        self.init(configuration: configuration, email: email, uid: uid, deviceRegistration: deviceRegistration, stateCache: KeychainCache(branch: "account.state", label: stateKeyLabel, value: state))
    }

    public init(configuration: FirefoxAccountConfiguration, email: String, uid: String, deviceRegistration: FxADeviceRegistration?, stateCache: KeychainCache<FxAState>) {
        self.email = email
        self.uid = uid
        self.deviceRegistration = deviceRegistration
        self.configuration = configuration
        self.stateCache = stateCache
        self.stateCache.checkpoint()
        self.syncAuthState = FirefoxAccountSyncAuthState(account: self,
            cache: KeychainCache.fromBranch("account.syncAuthState", withLabel: self.stateCache.label, factory: syncAuthStateCachefromJSON))
    }

    open class func from(_ configuration: FirefoxAccountConfiguration, andJSON data: JSON) -> FirefoxAccount? {
        guard let email = data["email"].string ,
            let uid = data["uid"].string,
            let sessionToken = data["sessionToken"].string?.hexDecodedData,
            let keyFetchToken = data["keyFetchToken"].string?.hexDecodedData,
            let unwrapkB = data["unwrapBKey"].string?.hexDecodedData else {
                return nil
        }

        let verified = data["verified"].bool ?? false
        return FirefoxAccount.from(configuration: configuration,
            andParametersWithEmail: email, uid: uid, deviceRegistration: nil, verified: verified,
            sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }

    open class func from(_ configuration: FirefoxAccountConfiguration,
                         andLoginResponse response: FxALoginResponse,
                         unwrapkB: Data) -> FirefoxAccount {
        return FirefoxAccount.from(configuration: configuration,
            andParametersWithEmail: response.remoteEmail, uid: response.uid, deviceRegistration: nil, verified: response.verified,
            sessionToken: response.sessionToken as Data, keyFetchToken: response.keyFetchToken as Data, unwrapkB: unwrapkB)
    }

    fileprivate class func from(configuration: FirefoxAccountConfiguration,
                                andParametersWithEmail email: String,
                                uid: String,
                                deviceRegistration: FxADeviceRegistration?,
                                verified: Bool,
                                sessionToken: Data,
                                keyFetchToken: Data,
                                unwrapkB: Data) -> FirefoxAccount {
        var state: FxAState! = nil
        if !verified {
            let now = Date.now()
            state = EngagedBeforeVerifiedState(knownUnverifiedAt: now,
                lastNotifiedUserAt: now,
                sessionToken: sessionToken,
                keyFetchToken: keyFetchToken,
                unwrapkB: unwrapkB
            )
        } else {
            state = EngagedAfterVerifiedState(
                sessionToken: sessionToken,
                keyFetchToken: keyFetchToken,
                unwrapkB: unwrapkB
            )
        }

        let account = FirefoxAccount(
            configuration: configuration,
            email: email,
            uid: uid,
            deviceRegistration: deviceRegistration,
            stateKeyLabel: Bytes.generateGUID(),
            state: state
        )
        return account
    }

    open func dictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["version"] = AccountSchemaVersion
        dict["email"] = email
        dict["uid"] = uid
        dict["deviceRegistration"] = deviceRegistration
        dict["pushRegistration"] = pushRegistration
        dict["configurationLabel"] = configuration.label.rawValue
        dict["stateKeyLabel"] = stateCache.label
        dict["pushRegistration"] = pushRegistration
        return dict
    }

    open class func fromDictionary(_ dictionary: [String: Any]) -> FirefoxAccount? {
        if let version = dictionary["version"] as? Int {
            if version == AccountSchemaVersion {
                return FirefoxAccount.fromDictionaryV1(dictionary)
            }
        }
        return nil
    }

    fileprivate class func fromDictionaryV1(_ dictionary: [String: Any]) -> FirefoxAccount? {
        var configurationLabel: FirefoxAccountConfigurationLabel? = nil
        if let rawValue = dictionary["configurationLabel"] as? String {
            configurationLabel = FirefoxAccountConfigurationLabel(rawValue: rawValue)
        }
        if let
            configurationLabel = configurationLabel,
            let email = dictionary["email"] as? String,
            let uid = dictionary["uid"] as? String {
                let deviceRegistration = dictionary["deviceRegistration"] as? FxADeviceRegistration
                let stateCache = KeychainCache.fromBranch("account.state", withLabel: dictionary["stateKeyLabel"] as? String, withDefault: SeparatedState(), factory: state)
                let account = FirefoxAccount(
                    configuration: configurationLabel.toConfiguration(),
                    email: email, uid: uid,
                    deviceRegistration: deviceRegistration,
                    stateCache: stateCache)
                account.pushRegistration = dictionary["pushRegistration"] as? PushRegistration
                return account
        }
        return nil
    }

    public enum AccountError: MaybeErrorType {
        case notMarried

        public var description: String {
            switch self {
            case .notMarried: return "Not married."
            }
        }
    }

    @discardableResult open func advance() -> Deferred<FxAState> {
        OSSpinLockLock(&advanceLock)
        if let deferred = advanceDeferred {
            // We already have an advance() in progress.  This consumer can chain from it.
            log.debug("advance already in progress; returning shared deferred.")
            OSSpinLockUnlock(&advanceLock)
            return deferred
        }

        // Alright, we haven't an advance() in progress.  Schedule a new deferred to chain from.
        let cachedState = stateCache.value!
        var registration = succeed()
        if let session = cachedState as? TokenState {
            registration = FxADeviceRegistrator.registerOrUpdateDevice(self, sessionToken: session.sessionToken as NSData).bind { result in
                if result.successValue != FxADeviceRegistrationResult.alreadyRegistered {
                    NotificationCenter.default.post(name: NotificationFirefoxAccountDeviceRegistrationUpdated, object: nil)
                }
                return succeed()
            }
        }

        let deferred: Deferred<FxAState> = registration.bind { _ in
            let client = FxAClient10(endpoint: self.configuration.authEndpointURL)
            let stateMachine = FxALoginStateMachine(client: client)
            let now = Date.now()
            return stateMachine.advance(fromState: cachedState, now: now).map { newState in
                self.stateCache.value = newState
                return newState
            }
        }

        advanceDeferred = deferred
        log.debug("no advance() in progress; setting and returning new shared deferred.")
        OSSpinLockUnlock(&advanceLock)

        deferred.upon { _ in
            // This advance() is complete.  Clear the shared deferred.
            OSSpinLockLock(&self.advanceLock)
            if let existingDeferred = self.advanceDeferred, existingDeferred === deferred {
                // The guard should not be needed, but should prevent trampling racing consumers.
                self.advanceDeferred = nil
                log.debug("advance() completed and shared deferred is existing deferred; clearing shared deferred.")
            } else {
                log.warning("advance() completed but shared deferred is not existing deferred; ignoring potential bug!")
            }
            OSSpinLockUnlock(&self.advanceLock)
        }
        return deferred
    }

    open func marriedState() -> Deferred<Maybe<MarriedState>> {
        return advance().map { newState in
            if newState.label == FxAStateLabel.married {
                if let married = newState as? MarriedState {
                    return Maybe(success: married)
                }
            }
            return Maybe(failure: AccountError.notMarried)
        }
    }

    @discardableResult open func makeSeparated() -> Bool {
        log.info("Making Account State be Separated.")
        self.stateCache.value = SeparatedState()
        return true
    }

    @discardableResult open func makeDoghouse() -> Bool {
        log.info("Making Account State be Doghouse.")
        self.stateCache.value = DoghouseState()
        return true
    }

    open func makeCohabitingWithoutKeyPair() -> Bool {
        if let married = self.stateCache.value as? MarriedState {
            log.info("Making Account State be CohabitingWithoutKeyPair.")
            self.stateCache.value = married.withoutKeyPair()
            return true
        }
        log.info("Cannot make Account State be CohabitingWithoutKeyPair from state with label \(self.stateCache.value?.label).")
        return false
    }
}
