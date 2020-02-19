import Shared
import MozillaAppServices
import SwiftKeychainWrapper

open class RustFirefoxAccounts {
    private let ClientID =  "a2270f727f45f648" // actual one is "1b1a3e44c54fbb58"
    public let redirectURL = "urn:ietf:wg:oauth:2.0:oob:oauth-redirect-webchannel"
    public static var shared = RustFirefoxAccounts()
    public let accountManager: FxAccountManager
    public var avatar: Avatar? = nil
    private static var startupCalled = false
    public let syncAuthState: SyncAuthState

    public var accountMigrationFailed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "fxaccount-migration-failed")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "fxaccount-migration-failed")
        }
    }

    public static func startup(completion: ((RustFirefoxAccounts) -> Void)? = nil) {
        if startupCalled {
            completion?(shared)
            return
        }
        startupCalled = true

        shared.accountManager.initialize() { result in
            let hasAttemptedMigration = UserDefaults.standard.bool(forKey: "hasAttemptedMigration")
            if Bundle.main.bundleURL.pathExtension != "appex", let tokens = migrationTokens(), !hasAttemptedMigration {
                UserDefaults.standard.set(true, forKey: "hasAttemptedMigration")

                let prefs = NSUserDefaultsPrefs(prefix: "profile")
                ["bookmarks", "history", "passwords", "tabs"].forEach {
                    if let val = prefs.boolForKey("sync.engine.\($0).enabled"), !val {
                        // is disabled
                    }
                }

                shared.accountManager.authenticateViaMigration(sessionToken: tokens.session, kSync: tokens.ksync, kXCS: tokens.kxcs) { _ in }
            }

            completion?(shared)
        }
    }

    private init() {
        let config = FxAConfig.release(clientId: ClientID, redirectUri: redirectURL)
        let type = UIDevice.current.userInterfaceIdiom == .pad ? DeviceType.tablet : DeviceType.mobile
        let deviceConfig = DeviceConfig(name:  DeviceInfo.defaultClientName(), type: type, capabilities: [.sendTab])

        let accessGroupPrefix = Bundle.main.object(forInfoDictionaryKey: "MozDevelopmentTeam") as! String
        let accessGroupIdentifier = AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix)

        accountManager = FxAccountManager(config: config, deviceConfig: deviceConfig, applicationScopes: [OAuthScope.profile, OAuthScope.oldSync, OAuthScope.session], keychainAccessGroup: accessGroupIdentifier)

        syncAuthState = FirefoxAccountSyncAuthState(
            cache: KeychainCache.fromBranch("rustAccounts.syncAuthState",
                                            withLabel: "bobo" /* TODO: we probably want a random string associated with the current account here*/,
                factory: syncAuthStateCachefromJSON))

        NotificationCenter.default.addObserver(forName: .accountAuthenticated,  object: nil, queue: .main) { [weak self] notification in
            if let type = notification.userInfo?["authType"] as? FxaAuthType, case .migrated = type {
                KeychainWrapper.sharedAppContainerKeychain.removeObject(forKey: "apnsToken", withAccessibility: .afterFirstUnlock)
                NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
            }

            self?.update()
        }
        
        NotificationCenter.default.addObserver(forName: .accountProfileUpdate,  object: nil, queue: .main) { [weak self] notification in
            self?.update()
        }

        NotificationCenter.default.addObserver(forName: .accountMigrationFailed, object: nil, queue: .main) { [weak self] notification in
            var info = ""
            if let error = notification.userInfo?["error"] as? Error {
                info = error.localizedDescription
            }
            Sentry.shared.send(message: "RustFxa failed account migration", tag: .rustLog, severity: .error, description: info)
            self?.accountMigrationFailed = true
            NotificationCenter.default.post(name: .FirefoxAccountStateChange, object: nil)
        }
    }

    private class func migrationTokens() -> (session: String, ksync: String, kxcs: String)? {
        // Keychain forKey("profile.account"), return dictionary, from there
        // forKey("account.state.<guid>"), guid is dictionary["stateKeyLabel"]
        // that returns JSON string.
        let keychain = KeychainWrapper.sharedAppContainerKeychain
        let key = "profile.account"
        keychain.ensureObjectItemAccessibility(.afterFirstUnlock, forKey: key)
        guard let dict = keychain.object(forKey: key) as? [String: AnyObject], let guid = dict["stateKeyLabel"] else {
            return nil
        }

        let key2 = "account.state.\(guid)"
        keychain.ensureObjectItemAccessibility(.afterFirstUnlock, forKey: key2)
        guard let jsonData = keychain.data(forKey: key2) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else {
            return nil
        }

        guard let sessionToken = json["sessionToken"] as? String, let ksync = json["kSync"] as? String, let kxcs = json["kXCS"] as? String else {
            return nil
        }

        return (session: sessionToken, ksync: ksync, kxcs: kxcs)
    }

    public var isActionNeeded: Bool {
        if accountManager.accountMigrationInFlight() || accountMigrationFailed { return true }
        if !accountManager.hasAccount() { return false }
        return accountManager.accountNeedsReauth()
    }

    private func update() {
        let avatarUrl = accountManager.accountProfile()?.avatar?.url
        if let str = avatarUrl, let url = URL(string: str) {
            avatar = Avatar(url: url)
        }
        
        NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
    }
}

