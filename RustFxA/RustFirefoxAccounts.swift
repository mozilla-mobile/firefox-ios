import Shared
import MozillaAppServices
import SwiftKeychainWrapper

open class RustFirefoxAccounts {
    private let ClientID =  "98adfa37698f255b" // actual one is "1b1a3e44c54fbb58"
    public let redirectURL = "https://lockbox.firefox.com/fxa/ios-redirect.html"
    public static var shared = RustFirefoxAccounts()
    public let accountManager: FxaAccountManager
    public var avatar: Avatar? = nil
    private static var startupCalled = false

    public static func startup(completion: ((RustFirefoxAccounts) -> Void)? = nil) {
        if startupCalled {
            completion?(shared)
            return
        }
        startupCalled = true

        shared.accountManager.initialize() { result in
            completion?(shared)
        }
    }

    private init() {
        let config = FxAConfig.release(clientId: ClientID, redirectUri: redirectURL)
        let type = UIDevice.current.userInterfaceIdiom == .pad ? DeviceType.tablet : DeviceType.mobile
        let deviceConfig = DeviceConfig(name:  DeviceInfo.defaultClientName(), type: type, capabilities: [.sendTab])

        let accessGroupPrefix = Bundle.main.object(forInfoDictionaryKey: "MozDevelopmentTeam") as! String
        let accessGroupIdentifier = AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix)

        accountManager = FxaAccountManager(config: config, deviceConfig: deviceConfig, keychainAccessGroup: accessGroupIdentifier)

        NotificationCenter.default.addObserver(forName: Notification.Name.accountAuthenticated,  object: nil, queue: nil) { notification in
            self.update()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.accountProfileUpdate,  object: nil, queue: nil) { notification in
            self.update()
        }
    }

    class func migrateTokens() -> (String, String, String)? {
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

        return (sessionToken: sessionToken, ksync: ksync, kxcs: kxcs)
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

