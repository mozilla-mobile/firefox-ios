import Shared
import MozillaAppServices

open class RustFirefoxAccounts {
    private let ClientID =  "98adfa37698f255b" // actual one is "1b1a3e44c54fbb58"
    public let redirectURL = "https://lockbox.firefox.com/fxa/ios-redirect.html"
    public static var shared = RustFirefoxAccounts()
    public let accountManager: FxaAccountManager
    public var avatar: Avatar? = nil
    private var isInit = false

    public static func startup(completion: ((RustFirefoxAccounts) -> Void)? = nil) {
        if shared.isInit {
            completion?(shared)
            return
        }
        shared.accountManager.initialize() { result in
            shared.isInit = true
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

