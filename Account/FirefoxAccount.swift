/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import SwiftKeychainWrapper
import SwiftyJSON
import FxA
import SDWebImage

private let log = Logger.syncLogger

// The version of the account schema we persist.
let AccountSchemaVersion = 2

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
    public let email: String

    /// The auth endpoint user identifier identifying the account.  A Firefox Account is uniquely identified on a
    /// particular server (auth endpoint) by its assigned uid.
    public let uid: String

    open var fxaProfile: FxAProfile?

    open var deviceRegistration: FxADeviceRegistration?

    // Only set one time in the Choose What to Sync FxA screen shown during registration.
    open var declinedEngines: [String]?

    // Use updateDeviceName() to set the device name and update the device registration.
    private(set) open var deviceName: String

    open var configuration: FirefoxAccountConfiguration

    open var pushRegistration: PushRegistration?

    private(set) open var commandsClient: FxACommandsClient!

    // Add notification on state change (checkpoint is called on each change)
    class KeychainCacheState : KeychainCache<FxAState> {
        open override func checkpoint() {
            super.checkpoint()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .FirefoxAccountStateChange, object: nil)
            }
        }
    }

    let stateCache: KeychainCacheState

//    open var syncAuthState: SyncAuthState! // We can't give a reference to self if this is a let.

    // To prevent advance() consumers racing, we maintain a shared advance() deferred (`advanceDeferred`).  If an
    // advance() is in progress, the shared deferred will be returned.  (Multiple consumers can chain off a single
    // deferred safely.)  If no advance() is in progress, a new shared deferred will be scheduled and returned.  To
    // prevent data races against the shared deferred, advance() locks accesses to `advanceDeferred` using
    // `advanceLock`.
    fileprivate var advanceLock = os_unfair_lock()
    fileprivate var advanceDeferred: Deferred<FxAState>?

    open var actionNeeded: FxAActionNeeded {
        return stateCache.value!.actionNeeded
    }

    public convenience init(configuration: FirefoxAccountConfiguration, email: String, uid: String, deviceRegistration: FxADeviceRegistration?, declinedEngines: [String]?, stateKeyLabel: String, state: FxAState, deviceName: String) {
        self.init(configuration: configuration, email: email, uid: uid, deviceRegistration: deviceRegistration, declinedEngines: declinedEngines, stateCache: KeychainCache(branch: "account.state", label: stateKeyLabel, value: state), deviceName: deviceName)
    }

    public init(configuration: FirefoxAccountConfiguration, email: String, uid: String, deviceRegistration: FxADeviceRegistration?, declinedEngines: [String]?, stateCache: KeychainCache<FxAState>, deviceName: String) {
        self.email = email
        self.uid = uid
        self.deviceRegistration = deviceRegistration
        self.declinedEngines = declinedEngines
        self.configuration = configuration
        self.stateCache = KeychainCacheState(branch: stateCache.branch, label: stateCache.label, value: stateCache.value)
        self.stateCache.checkpoint()
        self.fxaProfile = nil
        self.deviceName = deviceName

        self.commandsClient = FxACommandsClient(account: self)
//        self.syncAuthState = FirefoxAccountSyncAuthState(account: self,
//            cache: KeychainCache.fromBranch("account.syncAuthState", withLabel: self.stateCache.label, factory: syncAuthStateCachefromJSON))
    }

    open class func from(_ configuration: FirefoxAccountConfiguration, andJSON data: JSON) -> FirefoxAccount? {
        guard let email = data["email"].string ,
            let uid = data["uid"].string,
            let sessionToken = data["sessionToken"].string?.hexDecodedData,
            let keyFetchToken = data["keyFetchToken"].string?.hexDecodedData,
            let unwrapkB = data["unwrapBKey"].string?.hexDecodedData else {
                return nil
        }
        let declinedEngines = data["declinedSyncEngines"].array?.compactMap { $0.string }
        let deviceName = DeviceInfo.defaultClientName()

        let verified = data["verified"].bool ?? false
        return FirefoxAccount.from(configuration: configuration,
            andParametersWithEmail: email, uid: uid, deviceRegistration: nil, declinedEngines: declinedEngines, verified: verified,
            sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB, deviceName: deviceName)
    }

    open class func from(_ configuration: FirefoxAccountConfiguration,
                         andLoginResponse response: FxALoginResponse,
                         unwrapkB: Data, deviceName: String) -> FirefoxAccount {
        return FirefoxAccount.from(configuration: configuration,
                                   andParametersWithEmail: response.remoteEmail, uid: response.uid, deviceRegistration: nil, declinedEngines: nil, verified: response.verified,
                                   sessionToken: response.sessionToken as Data, keyFetchToken: response.keyFetchToken as Data, unwrapkB: unwrapkB, deviceName: deviceName)
    }

    fileprivate class func from(configuration: FirefoxAccountConfiguration,
                                andParametersWithEmail email: String,
                                uid: String,
                                deviceRegistration: FxADeviceRegistration?,
                                declinedEngines: [String]?,
                                verified: Bool,
                                sessionToken: Data,
                                keyFetchToken: Data,
                                unwrapkB: Data,
                                deviceName: String) -> FirefoxAccount {
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
            declinedEngines: declinedEngines,
            stateKeyLabel: Bytes.generateGUID(),
            state: state,
            deviceName: deviceName
        )
        return account
    }

    open func dictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["version"] = AccountSchemaVersion
        dict["email"] = email
        dict["uid"] = uid
        dict["deviceRegistration"] = deviceRegistration
        dict["declinedEngines"] = declinedEngines
        dict["pushRegistration"] = pushRegistration
        dict["configurationLabel"] = configuration.label.rawValue
        dict["stateKeyLabel"] = stateCache.label
        dict["deviceName"] = deviceName
        return dict
    }

    open class func fromDictionary(_ dictionary: [String: Any], withPrefs prefs: Prefs) -> FirefoxAccount? {
        if let version = dictionary["version"] as? Int {
            // As of this writing, the current version, v2, is backward compatible with v1. The only
            // field added is pushRegistration, which is ok to be nil. If it is nil, then the app
            // will attempt registration when it starts up.
            if version <= AccountSchemaVersion {
                return FirefoxAccount.fromDictionaryV1(dictionary, withPrefs: prefs)
            }
        }
        return nil
    }

    fileprivate class func fromDictionaryV1(_ dictionary: [String: Any], withPrefs prefs: Prefs) -> FirefoxAccount? {
        var configurationLabel: FirefoxAccountConfigurationLabel?
        if let rawValue = dictionary["configurationLabel"] as? String {
            configurationLabel = FirefoxAccountConfigurationLabel(rawValue: rawValue)
        }
        if let
            configurationLabel = configurationLabel,
            let email = dictionary["email"] as? String,
            let uid = dictionary["uid"] as? String {
                let deviceRegistration = dictionary["deviceRegistration"] as? FxADeviceRegistration
                let declinedEngines = dictionary["declinedEngines"] as? [String]
                let deviceName = dictionary["deviceName"] as? String ?? DeviceInfo.defaultClientName() // Upgrading clients may not have this key!
                let stateCache = KeychainCache.fromBranch("account.state", withLabel: dictionary["stateKeyLabel"] as? String, withDefault: SeparatedState(), factory: state)
                let account = FirefoxAccount(
                    configuration: configurationLabel.toConfiguration(prefs: prefs),
                    email: email, uid: uid,
                    deviceRegistration: deviceRegistration,
                    declinedEngines: declinedEngines,
                    stateCache: stateCache,
                    deviceName: deviceName)
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

    public class NotATokenStateError: MaybeErrorType {
        let state: FxAState?
        init(state: FxAState?) {
            self.state = state
        }
        public var description: String {
            return "Not in a Token State: \(state?.label.rawValue ?? "Empty State")"
        }
    }

    public class FxAProfile {
        open var displayName: String?
        public let email: String
        public let avatar: Avatar

        init(email: String, displayName: String?, avatar: String?) {
            self.email = email
            self.displayName = displayName
            self.avatar = Avatar(url: avatar?.asURL)
        }
    }

    // Don't forget to call Profile.flushAccount() to persist this change!
    open func updateDeviceName(_ newName: String) {
        self.deviceName = newName
        if let registration = self.deviceRegistration {
            // Reset the registration version/ts to make sure we'll do it again if we fail now.
            self.deviceRegistration = FxADeviceRegistration(id: registration.id, version: 0, lastRegistered: 0)
        }
        if let session = stateCache.value as? TokenState {
            // Update the device registration in the background.
            _ = self.registerOrUpdateDevice(session: session)
        }
    }

    // Fetch current user's FxA profile. It contains the most updated email, displayName and avatar. This
    // emits two `NotificationFirefoxAccountProfileChanged`, once when the profile has been downloaded and
    // another when the avatar image has been downloaded.
    open func updateProfile() {
        guard let married = stateCache.value as? MarriedState else {
            return
        }

        if self.fxaProfile == nil,
            let fxaProfileCache = KeychainStore.shared.dictionary(forKey: "fxaProfileCache"),
            let email = fxaProfileCache["email"] as? String {
            let displayName = fxaProfileCache["displayName"] as? String
            let avatarURL = fxaProfileCache["avatarURL"] as? String
            self.fxaProfile = FxAProfile(email: email, displayName: displayName, avatar: avatarURL)
        }

        let client = FxAClient10(configuration: configuration)
        client.getProfile(withSessionToken: married.sessionToken as NSData) >>== { result in
            self.fxaProfile = FxAProfile(email: result.email, displayName: result.displayName, avatar: result.avatarURL)

            let fxaProfileCache: [String : Any] = [
                "email": result.email,
                "displayName": result.displayName as Any,
                "avatarURL": result.avatarURL as Any
            ]
            KeychainStore.shared.setDictionary(fxaProfileCache, forKey: "fxaProfileCache")

            NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        }
    }

    // Fetch the devices list from FxA then replace the current stored remote devices.
    open func updateFxADevices(remoteDevices: RemoteDevices) -> Success {
        guard let session = stateCache.value as? TokenState else {
            return deferMaybe(NotATokenStateError(state: stateCache.value))
        }
        let client = FxAClient10(configuration: configuration)
        return client.devices(withSessionToken: session.sessionToken as NSData) >>== { resp in
            return remoteDevices.replaceRemoteDevices(resp.devices)
        }
    }

    public class NotifyError: MaybeErrorType {
        public var description = "The server could not notify the clients."
    }

    @discardableResult open func notify(deviceIDs: [GUID], collectionsChanged collections: [String], reason: String) -> Success {
        guard let session = stateCache.value as? TokenState else {
            return deferMaybe(NotATokenStateError(state: stateCache.value))
        }
        let client = FxAClient10(configuration: configuration)
        return client.notify(deviceIDs: deviceIDs, collectionsChanged: collections, reason: reason, withSessionToken: session.sessionToken as NSData) >>== { resp in
            guard resp.success else {
                return deferMaybe(NotifyError())
            }
            return succeed()
        }
    }

    @discardableResult open func notifyAll(collectionsChanged collections: [String], reason: String) -> Success {
        guard let session = stateCache.value as? TokenState else {
            return deferMaybe(NotATokenStateError(state: stateCache.value))
        }
        guard let ownDeviceId = self.deviceRegistration?.id else {
            return deferMaybe(FxAClientError.local(NSError()))
        }
        let client = FxAClient10(configuration: configuration)
        return client.notifyAll(ownDeviceId: ownDeviceId, collectionsChanged: collections, reason: reason, withSessionToken: session.sessionToken as NSData) >>== { resp in
            guard resp.success else {
                return deferMaybe(NotifyError())
            }
            return succeed()
        }
    }

    @discardableResult open func destroyDevice() -> Success {
        guard let session = stateCache.value as? TokenState else {
            return deferMaybe(NotATokenStateError(state: stateCache.value))
        }
        guard let ownDeviceId = self.deviceRegistration?.id else {
            return deferMaybe(FxAClientError.local(NSError()))
        }

        // Clear Send Tab keys from Keychain.
        KeychainStore.shared.setDictionary(nil, forKey: "apnsToken")
        commandsClient.sendTab.sendTabKeysCache.value = nil

        // Clear cached FxA profile data from Keychain.
        KeychainStore.shared.setDictionary(nil, forKey: "fxaProfileCache")

        // Clear cached OAuth data from Keychain.
        [ FxAOAuthScope.Profile, FxAOAuthScope.OldSync ].forEach { scope in
            let oauthKeyIDKeychainKey = "FxAOAuthKeyID:\(scope)"
            let oauthResponseKeychainKey = "FxAOAuthResponse:\(scope)"
            KeychainStore.shared.setDictionary(nil, forKey: oauthKeyIDKeychainKey)
            KeychainStore.shared.setDictionary(nil, forKey: oauthResponseKeychainKey)
        }

        let client = FxAClient10(configuration: configuration)
        return client.destroyDevice(ownDeviceId: ownDeviceId, withSessionToken: session.sessionToken as NSData) >>> succeed
    }

    fileprivate func registerOrUpdateDevice(session: TokenState) -> Success {
        let d = FxADeviceRegistrator.registerOrUpdateDevice(self, sessionToken: session.sessionToken as NSData)
        d.upon { result in
            if result.successValue != FxADeviceRegistrationResult.alreadyRegistered {
                NotificationCenter.default.post(name: .FirefoxAccountDeviceRegistrationUpdated, object: nil)
            }
        }
        return d >>> succeed
    }

    open func availableCommands() -> JSON {
        guard let sendTabKey = commandsClient.sendTab.getEncryptedKey() else {
            KeychainStore.shared.setDictionary(nil, forKey: "apnsToken")
            return JSON()
        }

        let commands = [FxACommandSendTab.Name: sendTabKey]
        return JSON(commands)
    }

    @discardableResult open func advance() -> Deferred<FxAState> {
        os_unfair_lock_lock(&advanceLock)
        if let deferred = advanceDeferred {
            // We already have an advance() in progress.  This consumer can chain from it.
            log.debug("advance already in progress; returning shared deferred.")
            os_unfair_lock_unlock(&advanceLock)
            return deferred
        }

        // Alright, we haven't an advance() in progress.  Schedule a new deferred to chain from.
        let cachedState = stateCache.value!
        let registration: Success
        if let session = cachedState as? TokenState {
            registration = self.registerOrUpdateDevice(session: session)
        } else {
            registration = succeed()
        }
        let deferred: Deferred<FxAState> = registration.bind { _ in
            let client = FxAClient10(configuration: self.configuration)
            let stateMachine = FxALoginStateMachine(client: client)
            let now = Date.now()
            return stateMachine.advance(fromState: cachedState, now: now).map { newState in
                self.stateCache.value = newState

                // If we were not previously married, but we are now,
                // we need to re-register our device for push.
                if let newSession = newState as? MarriedState,
                    cachedState as? MarriedState == nil {
                    DispatchQueue.main.async {
                        _ = self.registerOrUpdateDevice(session: newSession)
                        self.updateProfile()
                    }
                }

                return newState
            }
        }

        advanceDeferred = deferred
        log.debug("no advance() in progress; setting and returning new shared deferred.")
        os_unfair_lock_unlock(&advanceLock)

        deferred.upon { _ in
            // This advance() is complete.  Clear the shared deferred.
            os_unfair_lock_lock(&self.advanceLock)
            if let existingDeferred = self.advanceDeferred, existingDeferred === deferred {
                // The guard should not be needed, but should prevent trampling racing consumers.
                self.advanceDeferred = nil
                log.debug("advance() completed and shared deferred is existing deferred; clearing shared deferred.")
            } else {
                log.warning("advance() completed but shared deferred is not existing deferred; ignoring potential bug!")
            }
            os_unfair_lock_unlock(&self.advanceLock)
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

        log.info("Cannot make Account State be CohabitingWithoutKeyPair from state with label \(self.stateCache.value?.label ??? "nil").")
        return false
    }
}
