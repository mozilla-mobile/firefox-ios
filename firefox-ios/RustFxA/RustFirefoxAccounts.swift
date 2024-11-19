// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

import class MozillaAppServices.FxAccountManager
import class MozillaAppServices.FxAConfig
import enum MozillaAppServices.DeviceCapability
import enum MozillaAppServices.DeviceType
import enum MozillaAppServices.OAuthScope
import struct MozillaAppServices.DeviceConfig
import struct MozillaAppServices.Profile

let PendingAccountDisconnectedKey = "PendingAccountDisconnect"

// Used to ignore unknown classes when de-archiving
final class Unknown: NSObject, NSCoding {
    func encode(with coder: NSCoder) {}
    init(coder aDecoder: NSCoder) {
        super.init()
    }
}

// A convenience to allow other callers to pass in Nimbus/Flaggable features
// to RustFirefoxAccounts
public struct RustFxAFeatures: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
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
    // The value of the scope comes from
    // https://searchfox.org/mozilla-central/rev/887d4b5da89a11920ed0fd96b7b7f066927a67db/services/fxaccounts/FxAccountsCommon.js#88
    public static let pushScope = "chrome://fxa-device-update"
    public static let shared = RustFirefoxAccounts()
    public var accountManager: FxAccountManager?
    public var avatar: Avatar?
    fileprivate static var prefs: Prefs?
    public let pushNotifications = PushNotificationSetup()
    private let logger: Logger

    private init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger

        NotificationCenter.default.addObserver(
            forName: .accountAuthenticated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.update()
        }

        NotificationCenter.default.addObserver(
            forName: .accountProfileUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.update()
        }
    }

    /** Must be called before this class is fully usable. Until this function is complete,
     all methods in this class will behave as if there is no Fx account.
     It will be called on app startup, and extensions must call this before using the class.
     If it is possible code could access `shared` before initialize() is complete, these callers should also
     hook into notifications like `.accountProfileUpdate` to refresh once initialize() is complete.
     Or they can wait on the accountManager deferred to fill.
     */
    public static func startup(
        prefs: Prefs,
        features: RustFxAFeatures = RustFxAFeatures(),
        logger: Logger = DefaultLogger.shared,
        completion: @escaping (FxAccountManager) -> Void
    ) {
        assert(Thread.isMainThread)
        if !Thread.isMainThread {
            logger.log("Startup of RustFirefoxAccounts is happening OFF the main thread!",
                       level: .warning,
                       category: .sync)
        }
        RustFirefoxAccounts.prefs = prefs
        if let accManager = RustFirefoxAccounts.shared.accountManager {
            completion(accManager)
        }
        let manager = RustFirefoxAccounts.shared.createAccountManager(features: features)
        manager.initialize { result in
            assert(Thread.isMainThread)
            if !Thread.isMainThread {
                logger.log("Initialization of RustFirefoxAccountsManager is happening OFF the main thread!",
                           level: .warning,
                           category: .sync)
            }

            RustFirefoxAccounts.shared.accountManager = manager

           // After everything is setup, register for push notifications
            if manager.hasAccount() {
                NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
            }

            completion(manager)
        }
    }

    // Reconfiguring a completed FxA init
    public static func reconfig(prefs: Prefs, completion: @escaping (FxAccountManager) -> Void) {
        // reset the accountManager and go through the startup process again with new prefs
        RustFirefoxAccounts.shared.accountManager = nil
        startup(prefs: prefs) { accountManager in
            completion(accountManager)
        }
    }

    public var isChinaSyncServiceEnabled: Bool {
        return RustFirefoxAccounts.prefs?.boolForKey(PrefsKeys.KeyEnableChinaSyncService) ?? AppInfo.isChinaEdition
    }

    private func createAccountManager(features: RustFxAFeatures) -> FxAccountManager {
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
        let useCustom = prefs?.boolForKey(
            PrefsKeys.KeyUseCustomFxAContentServer
        ) ?? false || prefs?.boolForKey(
            PrefsKeys.KeyUseCustomSyncTokenServerOverride
        ) ?? false
        if useCustom {
            let contentUrl: String
            if prefs?.boolForKey(PrefsKeys.KeyUseCustomFxAContentServer) ?? false,
               let url = prefs?.stringForKey(PrefsKeys.KeyCustomFxAContentServer) {
                contentUrl = url
            } else {
                contentUrl = "https://stable.dev.lcip.org"
            }

            let serverOverride = prefs?.boolForKey(PrefsKeys.KeyUseCustomSyncTokenServerOverride) ?? false
            let tokenServer = serverOverride ? prefs?.stringForKey(PrefsKeys.KeyCustomSyncTokenServerOverride) : nil
            config = FxAConfig(
                contentUrl: contentUrl,
                clientId: RustFirefoxAccounts.clientID,
                redirectUri: RustFirefoxAccounts.redirectURL,
                tokenServerUrlOverride: tokenServer
            )
        } else {
            config = FxAConfig(
                server: server,
                clientId: RustFirefoxAccounts.clientID,
                redirectUri: RustFirefoxAccounts.redirectURL
            )
        }

        let type = UIDevice.current.userInterfaceIdiom == .pad ? DeviceType.tablet : DeviceType.mobile

        let capabilities: [DeviceCapability] = [.sendTab, .closeTabs]
        let deviceConfig = DeviceConfig(
            name: DeviceInfo.defaultClientName(),
            deviceType: type,
            capabilities: capabilities
        )
        guard let accessGroupPrefix = Bundle.main.object(forInfoDictionaryKey: "MozDevelopmentTeam") as? String else {
            fatalError("Missing or invalid 'MozDevelopmentTeam' key in Info.plist")
        }
        let accessGroupIdentifier = AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix)

        return FxAccountManager(
            config: config,
            deviceConfig: deviceConfig,
            applicationScopes: [OAuthScope.profile, OAuthScope.oldSync, OAuthScope.session],
            keychainAccessGroup: accessGroupIdentifier
        )
    }

    /// This is typically used to add a UI indicator that FxA needs attention (usually re-login manually).
    public var isActionNeeded: Bool {
        if !hasAccount() { return false }
        return accountNeedsReauth()
    }

    /// Rust FxA notification handlers can call this to update caches and the UI.
    private func update() {
        guard let accountManager = RustFirefoxAccounts.shared.accountManager else { return}
        let avatarUrl = accountManager.accountProfile()?.avatar
        if let str = avatarUrl, let url = URL(string: str, invalidCharacters: false) {
            avatar = Avatar(url: url)
        }

        // The userProfile (email, display name, etc) and the device name need to be cached for when
        // the app starts in an offline state. Now is a good time to update those caches.

        // Accessing the profile will trigger a cache update if needed
        _ = userProfile

        // Update the device name cache
        if let deviceName = accountManager.deviceConstellation()?.state()?.localDevice?.displayName {
            UserDefaults.standard.set(deviceName, forKey: RustFirefoxAccounts.prefKeyLastDeviceName)
        }

        // The legacy system had both of these notifications for UI updates. Possibly they could be
        // made into a single notification
        NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        NotificationCenter.default.post(name: .FirefoxAccountStateChange, object: self)
    }

    /// Cache the user profile (i.e. email, user name) for when the app starts offline. Notice this gets
    /// cleared when an account is disconnected.
    private let prefKeyCachedUserProfile = "prefKeyCachedUserProfile"
    private var cachedUserProfile: FxAUserProfile?
    public var userProfile: FxAUserProfile? {
        let prefs = RustFirefoxAccounts.prefs

        if let profile = RustFirefoxAccounts.shared.accountManager?.accountProfile() {
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

    public func disconnect() {
        guard let accountManager = accountManager else { return }
        accountManager.logout { _ in }
        let prefs = RustFirefoxAccounts.prefs
        prefs?.removeObjectForKey(prefKeyCachedUserProfile)
        prefs?.removeObjectForKey(PendingAccountDisconnectedKey)
        cachedUserProfile = nil
    }

    public func hasAccount(completion: @escaping (Bool) -> Void) {
        if let manager = RustFirefoxAccounts.shared.accountManager {
            completion(manager.hasAccount())
        }
    }

    public func hasAccount() -> Bool {
        guard let accountManager = RustFirefoxAccounts.shared.accountManager else { return false }
        return accountManager.hasAccount()
    }

    public func accountNeedsReauth() -> Bool {
        guard let accountManager = RustFirefoxAccounts.shared.accountManager else { return false }
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
