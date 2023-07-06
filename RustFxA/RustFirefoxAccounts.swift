// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import MozillaAppServices

let PendingAccountDisconnectedKey = "PendingAccountDisconnect"

// Used to ignore unknown classes when de-archiving
final class Unknown: NSObject, NSCoding {
    func encode(with coder: NSCoder) {}
    init(coder aDecoder: NSCoder) {
        super.init()
    }
}

// TODO: renamed FirefoxAccounts.swift once the old code is removed fully.
/**
 A singleton that wraps the Rust FxA library.
 The singleton design is poor for testability through dependency injection and may need to be changed in future.
 */
open class RustFirefoxAccounts {
    public static let prefKeyLastDeviceName = "prefKeyLastDeviceName"
    private static let clientID = "1b1a3e44c54fbb58"
    public static let redirectURL = "urn:ietf:wg:oauth:2.0:oob:oauth-redirect-webchannel"
    // The value of the scope comes from https://searchfox.org/mozilla-central/rev/887d4b5da89a11920ed0fd96b7b7f066927a67db/services/fxaccounts/FxAccountsCommon.js#88
    public static let pushScope = "chrome://fxa-device-update"
    public static var shared = RustFirefoxAccounts()
    public var accountManager = Deferred<FxAccountManager>()
    private static var isInitializingAccountManager = false
    public var avatar: Avatar?
    public let syncAuthState: SyncAuthState
    fileprivate static var prefs: Prefs?
    public let pushNotifications = PushNotificationSetup()
    private let logger: Logger

    // This is used so that if a migration failed, show a UI indicator for the user to manually log in to their account.
    public var accountMigrationFailed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "fxaccount-migration-failed")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "fxaccount-migration-failed")
        }
    }

    /** Must be called before this class is fully usable. Until this function is complete,
     all methods in this class will behave as if there is no Fx account.
     It will be called on app startup, and extensions must call this before using the class.
     If it is possible code could access `shared` before initialize() is complete, these callers should also
     hook into notifications like `.accountProfileUpdate` to refresh once initialize() is complete.
     Or they can wait on the accountManager deferred to fill.
     */
    public static func startup(prefs: Prefs,
                               logger: Logger = DefaultLogger.shared) -> Deferred<FxAccountManager> {
        assert(Thread.isMainThread)
        if !Thread.isMainThread {
            logger.log("Startup of RustFirefoxAccounts is happening OFF the main thread!",
                       level: .warning,
                       category: .sync)
        }

        RustFirefoxAccounts.prefs = prefs
        if RustFirefoxAccounts.shared.accountManager.isFilled || isInitializingAccountManager {
            return RustFirefoxAccounts.shared.accountManager
        }

        // Setup the re-entrancy guard so consecutive calls to startup() won't do manager.initialize(). This flag is cleared when initialize is complete, or by calling reconfig().
        isInitializingAccountManager = true

        let manager = RustFirefoxAccounts.shared.createAccountManager()
        manager.initialize { result in
            assert(Thread.isMainThread)
            if !Thread.isMainThread {
                logger.log("Initialization of RustFirefoxAccountsManager is happening OFF the main thread!",
                           level: .warning,
                           category: .sync)
            }

            isInitializingAccountManager = false

            let hasAttemptedMigration = UserDefaults.standard.bool(forKey: "hasAttemptedMigration")

            // Note this checks if startup() is called in an app extensions, and if so, do not try account migration
            if Bundle.main.bundleURL.pathExtension != "appex", let tokens = migrationTokens(), !hasAttemptedMigration {
                UserDefaults.standard.set(true, forKey: "hasAttemptedMigration")

                // The client app only needs to trigger this one time. If it fails due to offline state, the rust library
                // will automatically re-try until success or permanent failure (notifications accountAuthenticated / accountMigrationFailed respectively).
                // See also `init()` use of `.accountAuthenticated` below.
                manager.authenticateViaMigration(sessionToken: tokens.session, kSync: tokens.ksync, kXCS: tokens.kxcs) { _ in }
            }

            RustFirefoxAccounts.shared.accountManager.fill(manager)

            // After everything is setup, register for push notifications
            if manager.hasAccount() {
                NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
            }
        }
        return RustFirefoxAccounts.shared.accountManager
    }

    private static let prefKeySyncAuthStateUniqueID = "PrefKeySyncAuthStateUniqueID"
    private static func syncAuthStateUniqueId(prefs: Prefs?) -> String {
        let id: String
        let key = RustFirefoxAccounts.prefKeySyncAuthStateUniqueID
        if let _id = prefs?.stringForKey(key) {
            id = _id
        } else {
            id = UUID().uuidString
            prefs?.setString(id, forKey: key)
        }
        return id
    }

    @discardableResult
    public static func reconfig(prefs: Prefs) -> Deferred<FxAccountManager> {
        if isInitializingAccountManager {
            // This func is for reconfiguring a completed FxA init, if FxA init is in-progress, let it complete the init as-is
            return shared.accountManager
        }
        isInitializingAccountManager = false
        shared.accountManager = Deferred<FxAccountManager>()
        return startup(prefs: prefs)
    }

    public var isChinaSyncServiceEnabled: Bool {
        return RustFirefoxAccounts.prefs?.boolForKey(PrefsKeys.KeyEnableChinaSyncService) ?? AppInfo.isChinaEdition
    }

    private func createAccountManager() -> FxAccountManager {
        let prefs = RustFirefoxAccounts.prefs
        if prefs == nil {
            logger.log("prefs is unexpectedly nil", level: .warning, category: .sync)
        }

        let server: FxAConfig.Server
        if prefs?.intForKey(PrefsKeys.UseStageServer) == 1 {
            server = FxAConfig.Server.stage
        } else {
            server = isChinaSyncServiceEnabled ? FxAConfig.Server.china : FxAConfig.Server.release
        }

        let config: FxAConfig
        let useCustom = prefs?.boolForKey(PrefsKeys.KeyUseCustomFxAContentServer) ?? false || prefs?.boolForKey(PrefsKeys.KeyUseCustomSyncTokenServerOverride) ?? false
        if useCustom {
            let contentUrl: String
            if prefs?.boolForKey(PrefsKeys.KeyUseCustomFxAContentServer) ?? false, let url = prefs?.stringForKey(PrefsKeys.KeyCustomFxAContentServer) {
                contentUrl = url
            } else {
                contentUrl = "https://stable.dev.lcip.org"
            }

            let tokenServer = prefs?.boolForKey(PrefsKeys.KeyUseCustomSyncTokenServerOverride) ?? false ? prefs?.stringForKey(PrefsKeys.KeyCustomSyncTokenServerOverride) : nil
            config = FxAConfig(contentUrl: contentUrl, clientId: RustFirefoxAccounts.clientID, redirectUri: RustFirefoxAccounts.redirectURL, tokenServerUrlOverride: tokenServer)
        } else {
            config = FxAConfig(server: server, clientId: RustFirefoxAccounts.clientID, redirectUri: RustFirefoxAccounts.redirectURL)
        }

        let type = UIDevice.current.userInterfaceIdiom == .pad ? DeviceType.tablet : DeviceType.mobile
        let deviceConfig = DeviceConfig(name: DeviceInfo.defaultClientName(), type: type, capabilities: [.sendTab])
        let accessGroupPrefix = Bundle.main.object(forInfoDictionaryKey: "MozDevelopmentTeam") as! String
        let accessGroupIdentifier = AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix)

        return FxAccountManager(config: config, deviceConfig: deviceConfig, applicationScopes: [OAuthScope.profile, OAuthScope.oldSync, OAuthScope.session], keychainAccessGroup: accessGroupIdentifier)
    }

    private init(logger: Logger = DefaultLogger.shared) {
        // Set-up Rust network stack. Note that this has to be called
        // before any Application Services component gets used.
        Viaduct.shared.useReqwestBackend()

        let prefs = RustFirefoxAccounts.prefs
        self.logger = logger
        let cache = KeychainCache.fromBranch("rustAccounts.syncAuthState",
                                             withLabel: RustFirefoxAccounts.syncAuthStateUniqueId(prefs: prefs),
                                             factory: syncAuthStateCachefromJSON)
        syncAuthState = FirefoxAccountSyncAuthState(cache: cache)

        // Called when account is logged in for the first time, on every app start when the account is found (even if offline), and when migration of an account is completed.
        NotificationCenter.default.addObserver(forName: .accountAuthenticated, object: nil, queue: .main) { [weak self] notification in
            // Handle account migration completed successfully. Need to clear the old stored apnsToken and re-register push.
            if let type = notification.userInfo?["authType"] as? FxaAuthType, case .migrated = type {
                MZKeychainWrapper.sharedClientAppContainerKeychain.removeObject(forKey: KeychainKey.apnsToken, withAccessibility: .afterFirstUnlock)
                NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
            }

            self?.update()
        }

        NotificationCenter.default.addObserver(forName: .accountProfileUpdate, object: nil, queue: .main) { [weak self] notification in
            self?.update()
        }

        NotificationCenter.default.addObserver(forName: .accountMigrationFailed, object: nil, queue: .main) { [weak self] notification in
            var info = ""
            if let error = notification.userInfo?["error"] as? Error {
                info = error.localizedDescription
            }
            logger.log("RustFxa failed account migration",
                       level: .warning,
                       category: .sync,
                       description: info)
            self?.accountMigrationFailed = true
            NotificationCenter.default.post(name: .FirefoxAccountStateChange, object: nil)
        }
    }

    struct MigrationTokens {
        let session: String
        let ksync: String
        let kxcs: String
    }

    /// When migrating to new rust FxA, grab the old session tokens and try to re-use them.
    private class func migrationTokens() -> MigrationTokens? {
        // Keychain forKey("profile.account"), return dictionary, from there
        // forKey("account.state.<guid>"), guid is dictionary["stateKeyLabel"]
        // that returns JSON string.
        let keychain = MZKeychainWrapper.sharedClientAppContainerKeychain
        let key = "profile.account"
        keychain.ensureDictonaryItemAccessibility(.afterFirstUnlock, forKey: key)

        // Ignore this class when de-archiving, it isn't needed.
        NSKeyedUnarchiver.setClass(Unknown.self, forClassName: "Account.FxADeviceRegistration")

        guard let dict = keychain.object(forKey: key, ofClass: NSDictionary.self) as? [String: AnyObject],
              let guid = dict["stateKeyLabel"]
        else { return nil }

        let key2 = "account.state.\(guid)"
        keychain.ensureDictonaryItemAccessibility(.afterFirstUnlock, forKey: key2)
        guard let jsonData = keychain.data(forKey: key2) else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else { return nil }

        guard let sessionToken = json["sessionToken"] as? String,
              let ksync = json["kSync"] as? String,
              let kxcs = json["kXCS"] as? String
        else { return nil }

        return MigrationTokens(session: sessionToken, ksync: ksync, kxcs: kxcs)
    }

    /// This is typically used to add a UI indicator that FxA needs attention (usually re-login manually).
    public var isActionNeeded: Bool {
        guard let accountManager = accountManager.peek() else { return false }
        if accountManager.accountMigrationInFlight() || accountMigrationFailed { return true }
        if !hasAccount() { return false }
        return accountNeedsReauth()
    }

    /// Rust FxA notification handlers can call this to update caches and the UI.
    private func update() {
        guard let accountManager = accountManager.peek() else { return }
        let avatarUrl = accountManager.accountProfile()?.avatar
        if let str = avatarUrl, let url = URL(string: str) {
            avatar = Avatar(url: url)
        }

        // The userProfile (email, display name, etc) and the device name need to be cached for when the app starts in an offline state. Now is a good time to update those caches.

        // Accessing the profile will trigger a cache update if needed
        _ = userProfile

        // Update the device name cache
        if let deviceName = accountManager.deviceConstellation()?.state()?.localDevice?.displayName {
            UserDefaults.standard.set(deviceName, forKey: RustFirefoxAccounts.prefKeyLastDeviceName)
        }

        // The legacy system had both of these notifications for UI updates. Possibly they could be made into a single notification
        NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        NotificationCenter.default.post(name: .FirefoxAccountStateChange, object: self)
    }

    /// Cache the user profile (i.e. email, user name) for when the app starts offline. Notice this gets cleared when an account is disconnected.
    private let prefKeyCachedUserProfile = "prefKeyCachedUserProfile"
    private var cachedUserProfile: FxAUserProfile?
    public var userProfile: FxAUserProfile? {
        let prefs = RustFirefoxAccounts.prefs

        if let accountManager = accountManager.peek(), let profile = accountManager.accountProfile() {
            if let p = cachedUserProfile, FxAUserProfile(profile: profile) == p {
                return cachedUserProfile
            }

            cachedUserProfile = FxAUserProfile(profile: profile)
            if let data = try? JSONEncoder().encode(cachedUserProfile!) {
                prefs?.setObject(data, forKey: prefKeyCachedUserProfile)
            }
        } else if cachedUserProfile == nil {
            if let data: Data = prefs?.objectForKey(prefKeyCachedUserProfile) {
                cachedUserProfile = try? JSONDecoder().decode(FxAUserProfile.self, from: data)
            }
        }

        return cachedUserProfile
    }

    public func disconnect(useNewAutopush: Bool) {
        guard let accountManager = accountManager.peek() else { return }
        accountManager.logout { _ in }
        let prefs = RustFirefoxAccounts.prefs
        prefs?.removeObjectForKey(RustFirefoxAccounts.prefKeySyncAuthStateUniqueID)
        prefs?.removeObjectForKey(prefKeyCachedUserProfile)
        prefs?.removeObjectForKey(PendingAccountDisconnectedKey)
        self.syncAuthState.invalidate()
        cachedUserProfile = nil
        if !useNewAutopush {
            pushNotifications.unregister()
        }
        MZKeychainWrapper.sharedClientAppContainerKeychain.removeObject(forKey: KeychainKey.apnsToken, withAccessibility: .afterFirstUnlock)
    }

    public func hasAccount(completion: @escaping (Bool) -> Void) {
        accountManager.uponQueue(.global()) { manager in
            completion(manager.hasAccount())
        }
    }

    public func hasAccount() -> Bool {
        guard let accountManager = accountManager.peek() else { return false }
        return accountManager.hasAccount()
    }

    public func accountNeedsReauth() -> Bool {
        guard let accountManager = accountManager.peek() else { return false }
        return accountManager.accountNeedsReauth()
    }
}

/**
 Wrap MozillaAppServices.Profile in an easy-to-serialize (and cache) FxAUserProfile.
 Caching of this is required for when the app starts offline.
 */
public struct FxAUserProfile: Codable, Equatable {
    public let uid: String
    public let email: String
    public let avatarUrl: String?
    public let displayName: String?

    init(profile: Profile) {
        uid = profile.uid
        email = profile.email
        avatarUrl = profile.avatar
        displayName = profile.displayName
    }
}
