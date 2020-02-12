import Shared
import MozillaAppServices
import SwiftKeychainWrapper

open class RustFirefoxAccounts {
    private let ClientID =  "a2270f727f45f648" // actual one is "1b1a3e44c54fbb58"
    public let redirectURL = "urn:ietf:wg:oauth:2.0:oob:oauth-redirect-webchannel"
    public static var shared = RustFirefoxAccounts()
    public let accountManager: FxaAccountManager
    public var avatar: Avatar? = nil
    private static var startupCalled = false
    public let syncAuthState: SyncAuthState

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
                shared.accountManager.migrationAuthentication(sessionToken: tokens.session, kSync: tokens.ksync, kXCS: tokens.kxcs) { result in
                    // handle failure case
                    switch result {
                    case .success:
                        break
                    case .failure:
                        break
                    case .willRetry:
                        break
                    }
                }
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

        accountManager = FxaAccountManager(config: config, deviceConfig: deviceConfig, applicationScopes: [OAuthScope.profile, OAuthScope.oldSync, OAuthScope.session], keychainAccessGroup: accessGroupIdentifier)

        syncAuthState = FirefoxAccountSyncAuthState(
            cache: KeychainCache.fromBranch("rustAccounts.syncAuthState",
                                            withLabel: nil /* we probably want a random string associated with the current account here*/,
                factory: syncAuthStateCachefromJSON))

        NotificationCenter.default.addObserver(forName: Notification.Name.accountAuthenticated,  object: nil, queue: nil) { notification in
            self.update()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.accountProfileUpdate,  object: nil, queue: nil) { notification in
            self.update()
        }
    }

    class func migrationTokens() -> (session: String, ksync: String, kxcs: String)? {
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

