/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

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
public class FirefoxAccount {
    /// The email address identifying the account.  A Firefox Account is uniquely identified on a particular server
    /// (auth endpoint) by its email address.
    public let email: String

    /// The auth endpoint user identifier identifying the account.  A Firefox Account is uniquely identified on a
    /// particular server (auth endpoint) by its assigned uid.
    public let uid: String

    public var fxaDeviceId: String?
    public var deviceRegistrationVersion: Int

    public let configuration: FirefoxAccountConfiguration

    private let stateCache: KeychainCache<FxAState>
    public var syncAuthState: SyncAuthState! // We can't give a reference to self if this is a let.

    // To prevent advance() consumers racing, we maintain a shared advance() deferred (`advanceDeferred`).  If an
    // advance() is in progress, the shared deferred will be returned.  (Multiple consumers can chain off a single
    // deferred safely.)  If no advance() is in progress, a new shared deferred will be scheduled and returned.  To
    // prevent data races against the shared deferred, advance() locks accesses to `advanceDeferred` using
    // `advanceLock`.
    private var advanceLock = OSSpinLock()
    private var advanceDeferred: Deferred<FxAState>? = nil

    public var actionNeeded: FxAActionNeeded {
        return stateCache.value!.actionNeeded
    }

    public convenience init(configuration: FirefoxAccountConfiguration, email: String, uid: String, fxaDeviceId: String?, deviceRegistrationVersion: Int, stateKeyLabel: String, state: FxAState) {
        self.init(configuration: configuration, email: email, uid: uid, fxaDeviceId: fxaDeviceId, deviceRegistrationVersion: deviceRegistrationVersion, stateCache: KeychainCache(branch: "account.state", label: stateKeyLabel, value: state))
    }

    public init(configuration: FirefoxAccountConfiguration, email: String, uid: String, fxaDeviceId: String?, deviceRegistrationVersion: Int, stateCache: KeychainCache<FxAState>) {
        self.email = email
        self.uid = uid
        self.fxaDeviceId = fxaDeviceId
        self.deviceRegistrationVersion = deviceRegistrationVersion
        self.configuration = configuration
        self.stateCache = stateCache
        self.stateCache.checkpoint()
        self.syncAuthState = FirefoxAccountSyncAuthState(account: self,
            cache: KeychainCache.fromBranch("account.syncAuthState", withLabel: self.stateCache.label, factory: syncAuthStateCachefromJSON))
    }

    public class func fromConfigurationAndJSON(configuration: FirefoxAccountConfiguration, data: JSON) -> FirefoxAccount? {
        guard let email = data["email"].asString ,
            let uid = data["uid"].asString,
            let sessionToken = data["sessionToken"].asString?.hexDecodedData,
            let keyFetchToken = data["keyFetchToken"].asString?.hexDecodedData,
            let unwrapkB = data["unwrapBKey"].asString?.hexDecodedData else {
                return nil
        }

        let verified = data["verified"].asBool ?? false
        return FirefoxAccount.fromConfigurationAndParameters(configuration,
            email: email, uid: uid, fxaDeviceId: nil, deviceRegistrationVersion: 0, verified: verified,
            sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }

    public class func fromConfigurationAndLoginResponse(configuration: FirefoxAccountConfiguration,
            response: FxALoginResponse, unwrapkB: NSData) -> FirefoxAccount {
        return FirefoxAccount.fromConfigurationAndParameters(configuration,
            email: response.remoteEmail, uid: response.uid, fxaDeviceId: nil, deviceRegistrationVersion: 0, verified: response.verified,
            sessionToken: response.sessionToken, keyFetchToken: response.keyFetchToken, unwrapkB: unwrapkB)
    }

    private class func fromConfigurationAndParameters(configuration: FirefoxAccountConfiguration,
            email: String, uid: String, fxaDeviceId: String?, deviceRegistrationVersion: Int, verified: Bool,
            sessionToken: NSData, keyFetchToken: NSData, unwrapkB: NSData) -> FirefoxAccount {
        var state: FxAState! = nil
        if !verified {
            let now = NSDate.now()
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
            fxaDeviceId: fxaDeviceId,
            deviceRegistrationVersion: deviceRegistrationVersion,
            stateKeyLabel: Bytes.generateGUID(),
            state: state
        )
        return account
    }

    public func asDictionary() -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        dict["version"] = AccountSchemaVersion
        dict["email"] = email
        dict["uid"] = uid
        dict["fxaDeviceId"] = fxaDeviceId
        dict["deviceRegistrationVersion"] = deviceRegistrationVersion
        dict["configurationLabel"] = configuration.label.rawValue
        dict["stateKeyLabel"] = stateCache.label
        return dict
    }

    public class func fromDictionary(dictionary: [String: AnyObject]) -> FirefoxAccount? {
        if let version = dictionary["version"] as? Int {
            if version == AccountSchemaVersion {
                return FirefoxAccount.fromDictionaryV1(dictionary)
            }
        }
        return nil
    }

    private class func fromDictionaryV1(dictionary: [String: AnyObject]) -> FirefoxAccount? {
        var configurationLabel: FirefoxAccountConfigurationLabel? = nil
        if let rawValue = dictionary["configurationLabel"] as? String {
            configurationLabel = FirefoxAccountConfigurationLabel(rawValue: rawValue)
        }
        if let
            configurationLabel = configurationLabel,
            email = dictionary["email"] as? String,
            uid = dictionary["uid"] as? String {
                let fxaDeviceId = dictionary["fxaDeviceId"] as? String
                let deviceRegistrationVersion = dictionary["deviceRegistrationVersion"] as? Int ?? 0
                let stateCache = KeychainCache.fromBranch("account.state", withLabel: dictionary["stateKeyLabel"] as? String, withDefault: SeparatedState(), factory: stateFromJSON)
                return FirefoxAccount(
                    configuration: configurationLabel.toConfiguration(),
                    email: email, uid: uid,
                    fxaDeviceId: fxaDeviceId, deviceRegistrationVersion: deviceRegistrationVersion,
                    stateCache: stateCache)
        }
        return nil
    }

    public enum AccountError: MaybeErrorType {
        case NotMarried
        case DeviceRegistrationFailed

        public var description: String {
            switch self {
            case NotMarried: return "Not married."
            case DeviceRegistrationFailed: return "Device registration failed."
            }
        }
    }

    public func advance() -> Deferred<FxAState> {
        OSSpinLockLock(&advanceLock)
        if let deferred = advanceDeferred {
            // We already have an advance() in progress.  This consumer can chain from it.
            log.debug("advance already in progress; returning shared deferred.")
            OSSpinLockUnlock(&advanceLock)
            return deferred
        }

        // Alright, we haven't an advance() in progress.  Schedule a new deferred to chain from.
        let client = FxAClient10(endpoint: configuration.authEndpointURL)
        let stateMachine = FxALoginStateMachine(client: client)
        let now = NSDate.now()
        let deferred: Deferred<FxAState> = stateMachine.advanceFromState(stateCache.value!, now: now).map { newState in
            self.stateCache.value = newState
            return newState
        }
        advanceDeferred = deferred
        log.debug("no advance() in progress; setting and returning new shared deferred.")
        OSSpinLockUnlock(&advanceLock)

        deferred.upon { _ in
            // This advance() is complete.  Clear the shared deferred.
            OSSpinLockLock(&self.advanceLock)
            if let existingDeferred = self.advanceDeferred where existingDeferred === deferred {
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

    public func marriedState() -> Deferred<Maybe<MarriedState>> {
        return advance().map { newState in
            if newState.label == FxAStateLabel.Married {
                if let married = newState as? MarriedState {
                    return Maybe(success: married)
                }
            }
            return Maybe(failure: AccountError.NotMarried)
        }
    }

    public func makeSeparated() -> Bool {
        log.info("Making Account State be Separated.")
        self.stateCache.value = SeparatedState()
        return true
    }

    public func makeDoghouse() -> Bool {
        log.info("Making Account State be Doghouse.")
        self.stateCache.value = DoghouseState()
        return true
    }

    public func makeCohabitingWithoutKeyPair() -> Bool {
        if let married = self.stateCache.value as? MarriedState {
            log.info("Making Account State be CohabitingWithoutKeyPair.")
            self.stateCache.value = married.withoutKeyPair()
            return true
        }
        log.info("Cannot make Account State be CohabitingWithoutKeyPair from state with label \(self.stateCache.value?.label).")
        return false
    }
}
