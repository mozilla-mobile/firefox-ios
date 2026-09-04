// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Storage

import class MozillaAppServices.FxAccountManager
import class MozillaAppServices.FxAConfig
import enum MozillaAppServices.DeviceCapability
import enum MozillaAppServices.DeviceType
import enum MozillaAppServices.OAuthScope
import struct MozillaAppServices.DeviceConfig
import struct MozillaAppServices.Profile

let PendingAccountDisconnectedKey = "PendingAccountDisconnect"

// A convenience to allow other callers to pass in Nimbus/Flaggable features
// to RustFirefoxAccounts
public struct RustFxAFeatures: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

// TODO: FXIOS-13290 Make RustFirefoxAccounts actually sendable
// TODO: renamed FirefoxAccounts.swift once the old code is removed fully.
/**
 A singleton that wraps the Rust FxA library.
 The singleton design is poor for testability through dependency injection and may need to be changed in future.
 */
public final class RustFirefoxAccounts: @unchecked Sendable {
    public static let prefKeyLastDeviceName = "prefKeyLastDeviceName"
    private static let clientID = "1b1a3e44c54fbb58"
    public static let redirectURL = "urn:ietf:wg:oauth:2.0:oob:oauth-redirect-webchannel"
    // The value of the scope comes from
    // https://searchfox.org/mozilla-central/rev/887d4b5da89a11920ed0fd96b7b7f066927a67db/services/fxaccounts/FxAccountsCommon.js#88
    public static let pushScope = "chrome://fxa-device-update"
    public static let shared = RustFirefoxAccounts()

    public var accountManager: FxAccountManager?
    public var avatar: Avatar?
    // TODO: FXIOS-12596 There is no need for this to be static. This should be an easier fix
    nonisolated(unsafe) private static var prefs: Prefs?
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
    @MainActor
    public static func startup(
        prefs: Prefs,
        logger: Logger = DefaultLogger.shared,
        completion: @escaping (FxAccountManager) -> Void
    ) {
        RustFirefoxAccounts.prefs = prefs
        if let accManager = RustFirefoxAccounts.shared.accountManager {
            completion(accManager)
        }
        let manager = RustFirefoxAccounts.shared.createAccountManager()
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
    @MainActor
    public static func reconfig(prefs: Prefs, completion: @escaping (FxAccountManager) -> Void) {
        // reset the accountManager and go through the startup process again with new prefs
        RustFirefoxAccounts.shared.accountManager = nil
        startup(prefs: prefs) { accountManager in
            completion(accountManager)
        }
    }

    public var isChinaSyncServiceEnabled: Bool {
        return RustFirefoxAccounts.isChinaSyncServiceEnabled(prefs: RustFirefoxAccounts.prefs)
    }

    static func isChinaSyncServiceEnabled(prefs: Prefs?) -> Bool {
        return prefs?.boolForKey(PrefsKeys.KeyEnableChinaSyncService) ?? AppInfo.isChinaEdition
    }

    // TODO: FXIOS-16756 These hosts are duplicated from the Rust component, which owns the real
    // server definitions. Drop this copy once app-services exposes them through uniffi.
    private static let releaseContentServer = "https://accounts.firefox.com"
    private static let stageContentServer = "https://accounts.stage.mozaws.net"
    private static let stableDevContentServer = "https://stable.dev.lcip.org"
    private static let chinaContentServer = "https://accounts.firefox.com.cn"

    /// The FxA content server this build is configured against.
    ///
    /// Mirrors the server selection in `createAccountManager` so that callers which must
    /// decide whether web content is trusted, such as the WebChannel bridge and pairing URL
    /// routing, agree with the account manager about which origin is ours.
    public static func contentServerURL() -> URL? {
        return contentServerURL(prefs: RustFirefoxAccounts.prefs)
    }

    /// Stays `public` so the pairing URL parser in Client can resolve the same origin, and so the
    /// prefs seam is reachable from tests in another module.
    public static func contentServerURL(prefs: Prefs?) -> URL? {
        return URL(string: contentServerString(prefs: prefs))
    }

    static func isUsingCustomContentServer(prefs: Prefs?) -> Bool {
        return prefs?.boolForKey(PrefsKeys.KeyUseCustomFxAContentServer) ?? false
            || prefs?.boolForKey(PrefsKeys.KeyUseCustomSyncTokenServerOverride) ?? false
    }

    /// The content server exactly as `createAccountManager` hands it to `FxAConfig`. A custom value
    /// is returned verbatim so an unparseable one still fails loudly in the Rust layer rather than
    /// silently redirecting the account manager to a different live server.
    static func contentServerString(prefs: Prefs?) -> String {
        if isUsingCustomContentServer(prefs: prefs) {
            if prefs?.boolForKey(PrefsKeys.KeyUseCustomFxAContentServer) ?? false,
               let custom = prefs?.stringForKey(PrefsKeys.KeyCustomFxAContentServer) {
                return custom
            }
            return stableDevContentServer
        }

        if prefs?.intForKey(PrefsKeys.UseStageServer) == 1 {
            return stageContentServer
        }
        if isChinaSyncServiceEnabled(prefs: prefs) {
            return chinaContentServer
        }
        return releaseContentServer
    }

    @MainActor
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
        let useCustom = RustFirefoxAccounts.isUsingCustomContentServer(prefs: prefs)
        if useCustom {
            let contentUrl = RustFirefoxAccounts.contentServerString(prefs: prefs)

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
        if let str = avatarUrl, let url = URL(string: str) {
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

    /// In-flight account operation the account manager applies asynchronously; UI reads it to show a
    /// transitional label ("Signing out…") instead of stale account info during the window.
    public enum AccountTransition {
        case idle
        case signingOut
    }

    public private(set) var accountTransition: AccountTransition = .idle

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
        guard let accountManager else { return }
        // Enter the "Signing out…" transition immediately; `logout` completes asynchronously, after which
        // the account manager's state becomes authoritative again.
        accountTransition = .signingOut
        NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        accountManager.logout { [weak self] _ in
            guard let self else { return }
            cachedUserProfile = nil
            RustFirefoxAccounts.prefs?.removeObjectForKey(prefKeyCachedUserProfile)
            accountTransition = .idle
            NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        }
        RustFirefoxAccounts.prefs?.removeObjectForKey(PendingAccountDisconnectedKey)
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
