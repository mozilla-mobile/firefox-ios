/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public extension Notification.Name {
    static let accountLoggedOut = Notification.Name("accountLoggedOut")
    static let accountAuthProblems = Notification.Name("accountAuthProblems")
    static let accountAuthenticated = Notification.Name("accountAuthenticated")
    static let accountProfileUpdate = Notification.Name("accountProfileUpdate")
}

// A place-holder for now removed migration support. This can be removed once
// https://github.com/mozilla-mobile/firefox-ios/issues/15258 has been resolved.
public enum MigrationResult {}

// swiftlint:disable type_body_length
open class FxAccountManager {
    let accountStorage: KeyChainAccountStorage
    let config: FxAConfig
    var deviceConfig: DeviceConfig
    let applicationScopes: [String]

    var acct: PersistedFirefoxAccount?
    var account: PersistedFirefoxAccount? {
        get { return acct }
        set {
            acct = newValue
            if let acc = acct {
                constellation = makeDeviceConstellation(account: acc)
            }
        }
    }

    var state = AccountState.start
    var profile: Profile?
    var constellation: DeviceConstellation?
    var latestOAuthStateParam: String?

    /// Instantiate the account manager.
    /// This class is intended to be long-lived within your app.
    /// `keychainAccessGroup` is especially important if you are
    /// using the manager in iOS App Extensions.
    public required init(
        config: FxAConfig,
        deviceConfig: DeviceConfig,
        applicationScopes: [String] = [OAuthScope.profile],
        keychainAccessGroup: String? = nil
    ) {
        self.config = config
        self.deviceConfig = deviceConfig
        self.applicationScopes = applicationScopes
        accountStorage = KeyChainAccountStorage(keychainAccessGroup: keychainAccessGroup)
        setupInternalListeners()
    }

    private lazy var statePersistenceCallback: FxAStatePersistenceCallback = .init(manager: self)

    /// Starts the FxA account manager and advances the state machine.
    /// It is required to call this method before doing anything else with the manager.
    /// Note that as a result of this initialization, notifications such as `accountAuthenticated` might be
    /// fired.
    public func initialize(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        processEvent(event: .initialize) {
            DispatchQueue.main.async { completionHandler(Result.success(())) }
        }
    }

    /// Returns true the user is currently logged-in to an account, no matter if they need to reconnect or not.
    public func hasAccount() -> Bool {
        return state == .authenticatedWithProfile ||
            state == .authenticatedNoProfile ||
            state == .authenticationProblem
    }

    /// Resets the inner Persisted Account based on the persisted state
    /// Callers can use this method to refresh the account manager to reflect
    /// the latest persisted state.
    /// It's possible for the account manager to go out sync with the persisted state
    /// in case an extension (Notification Service for example) modifies the persisted state
    public func resetPersistedAccount() {
        account = accountStorage.read()
        account?.registerPersistCallback(statePersistenceCallback)
    }

    /// Returns true if the account needs re-authentication.
    /// Your app should present the option to start a new OAuth flow.
    public func accountNeedsReauth() -> Bool {
        return state == .authenticationProblem
    }

    /// Set the user data before completing their authentication
    public func setUserData(userData: UserData, completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            self.account?.setUserData(userData: userData)
            completion()
        }
    }

    /// Begins a new authentication flow.
    ///
    /// This function returns a URL string that the caller should open in a webview.
    ///
    /// Once the user has confirmed the authorization grant, they will get redirected to `redirect_url`:
    /// the caller must intercept that redirection, extract the `code` and `state` query parameters and call
    /// `finishAuthentication(...)` to complete the flow.
    public func beginAuthentication(
        entrypoint: String,
        scopes: [String] = [],
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) {
        FxALog.info("beginAuthentication")
        var scopes = scopes
        if scopes.isEmpty {
            scopes = applicationScopes
        }
        DispatchQueue.global().async {
            let result = self.updatingLatestAuthState { account in
                try account.beginOAuthFlow(
                    scopes: scopes,
                    entrypoint: entrypoint
                )
            }
            DispatchQueue.main.async { completionHandler(result) }
        }
    }

    /// Begins a new pairing flow.
    /// The pairing URL corresponds to the URL shown by the other pairing party,
    /// scanned by your app QR code reader.
    ///
    /// This function returns a URL string that the caller should open in a webview.
    ///
    /// Once the user has confirmed the authorization grant, they will get redirected to `redirect_url`:
    /// the caller must intercept that redirection, extract the `code` and `state` query parameters and call
    /// `finishAuthentication(...)` to complete the flow.
    public func beginPairingAuthentication(
        pairingUrl: String,
        entrypoint: String,
        scopes: [String] = [],
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) {
        var scopes = scopes
        if scopes.isEmpty {
            scopes = applicationScopes
        }
        DispatchQueue.global().async {
            let result = self.updatingLatestAuthState { account in
                try account.beginPairingFlow(
                    pairingUrl: pairingUrl,
                    scopes: scopes,
                    entrypoint: entrypoint
                )
            }
            DispatchQueue.main.async { completionHandler(result) }
        }
    }

    /// Run a "begin authentication" closure, extracting the returned `state` from the returned URL
    /// and put it aside for later in `latestOAuthStateParam`.
    /// Afterwards, in `finishAuthentication` we ensure that we are
    /// finishing the correct (and same) authentication flow.
    private func updatingLatestAuthState(_ beginFlowFn: (PersistedFirefoxAccount) throws -> URL) -> Result<URL, Error> {
        do {
            let url = try beginFlowFn(requireAccount())
            let comps = URLComponents(url: url, resolvingAgainstBaseURL: true)
            latestOAuthStateParam = comps!.queryItems!.first(where: { $0.name == "state" })!.value
            return .success(url)
        } catch {
            return .failure(error)
        }
    }

    // A no-op place-holder for now removed support for migrating from a pre-rust
    // session token into a rust fxa-client. This stub remains to avoid causing
    // a breaking change for iOS and can be removed after https://github.com/mozilla-mobile/firefox-ios/issues/15258
    // has been resolved.
    public func authenticateViaMigration(
        sessionToken _: String,
        kSync _: String,
        kXCS _: String,
        completionHandler _: @escaping (MigrationResult) -> Void
    ) {
        // This will almost certainly never be called in practice. If it is, I guess
        // trying to force iOS into a "needs auth" state is the right thing to do...
        processEvent(event: .authenticationError) {}
    }

    /// Finish an authentication flow.
    ///
    /// If it succeeds, a `.accountAuthenticated` notification will get fired.
    public func finishAuthentication(
        authData: FxaAuthData,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        if latestOAuthStateParam == nil {
            DispatchQueue.main.async { completionHandler(.failure(FxaError.NoExistingAuthFlow(message: ""))) }
        } else if authData.state != latestOAuthStateParam {
            DispatchQueue.main.async { completionHandler(.failure(FxaError.WrongAuthFlow(message: ""))) }
        } else { /* state == latestAuthState */
            processEvent(event: .authenticated(authData: authData)) {
                DispatchQueue.main.async { completionHandler(.success(())) }
            }
        }
    }

    /// Try to get an OAuth access token.
    public func getAccessToken(
        scope: String,
        ttl: UInt64? = nil,
        completionHandler: @escaping (Result<AccessTokenInfo, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            do {
                let tokenInfo = try self.requireAccount().getAccessToken(scope: scope, ttl: ttl)
                DispatchQueue.main.async { completionHandler(.success(tokenInfo)) }
            } catch {
                DispatchQueue.main.async { completionHandler(.failure(error)) }
            }
        }
    }

    /// Get the session token associated with this account.
    /// Note that you should have requested the `.session` scope earlier to be able to get this token.
    public func getSessionToken() -> Result<String, Error> {
        do {
            return try .success(requireAccount().getSessionToken())
        } catch {
            return .failure(error)
        }
    }

    /// The account password has been changed locally and a new session token has been sent to us through WebChannel.
    public func handlePasswordChanged(newSessionToken: String, completionHandler: @escaping () -> Void) {
        processEvent(event: .changedPassword(newSessionToken: newSessionToken)) {
            DispatchQueue.main.async { completionHandler() }
        }
    }

    /// Get the account management URL.
    public func getManageAccountURL(
        entrypoint: String,
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            do {
                let url = try self.requireAccount().getManageAccountURL(entrypoint: entrypoint)
                DispatchQueue.main.async { completionHandler(.success(url)) }
            } catch {
                DispatchQueue.main.async { completionHandler(.failure(error)) }
            }
        }
    }

    /// Get the pairing URL to navigate to on the Auth side (typically a computer).
    public func getPairingAuthorityURL(
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            do {
                let url = try self.requireAccount().getPairingAuthorityURL()
                DispatchQueue.main.async { completionHandler(.success(url)) }
            } catch {
                DispatchQueue.main.async { completionHandler(.failure(error)) }
            }
        }
    }

    /// Get the token server URL with `1.0/sync/1.5` appended at the end.
    public func getTokenServerEndpointURL(
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            do {
                let url = try self.requireAccount()
                    .getTokenServerEndpointURL()
                    .appendingPathComponent("1.0/sync/1.5")
                DispatchQueue.main.async { completionHandler(.success(url)) }
            } catch {
                DispatchQueue.main.async { completionHandler(.failure(error)) }
            }
        }
    }

    /// Refresh the user profile in the background. A threshold is applied
    /// to profile fetch calls on the Rust side to avoid hammering the servers
    /// with requests. If you absolutely know your profile is out-of-date and
    /// need a fresh one, use the `ignoreCache` param to bypass the
    /// threshold.
    ///
    /// If it succeeds, a `.accountProfileUpdate` notification will get fired.
    public func refreshProfile(ignoreCache: Bool = false) {
        processEvent(event: .fetchProfile(ignoreCache: ignoreCache)) {
            // Do nothing
        }
    }

    /// Get the user profile synchronously. It could be empty
    /// because of network or authentication problems.
    public func accountProfile() -> Profile? {
        if state == .authenticatedWithProfile || state == .authenticationProblem {
            return profile
        }
        return nil
    }

    /// Get the device constellation.
    public func deviceConstellation() -> DeviceConstellation? {
        return constellation
    }

    /// Log-out from the account.
    /// The `.accountLoggedOut` notification will also get fired.
    public func logout(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        processEvent(event: .logout) {
            DispatchQueue.main.async { completionHandler(.success(())) }
        }
    }

    /// Returns a JSON string containing telemetry events to submit in the next
    /// Sync ping. This is used to collect telemetry for services like Send Tab.
    /// This method can be called anytime, and returns `nil` if the account is
    /// not initialized or there are no events to record.
    public func gatherTelemetry() throws -> String? {
        guard let acct = account else {
            return nil
        }
        return try acct.gatherTelemetry()
    }

    let fxaFsmQueue = DispatchQueue(label: "com.mozilla.fxa-mgr-queue")

    func processEvent(event: Event, completionHandler: @escaping () -> Void) {
        fxaFsmQueue.async {
            var toProcess: Event? = event
            while let evt = toProcess {
                toProcess = nil // Avoid infinite loop if `toProcess` doesn't get replaced.
                guard let nextState = FxAccountManager.nextState(state: self.state, event: evt) else {
                    FxALog.error("Got invalid event \(evt) for state \(self.state).")
                    continue
                }
                FxALog.debug("Processing event \(evt) for state \(self.state). Next state is \(nextState).")
                self.state = nextState
                toProcess = self.stateActions(forState: self.state, via: evt)
                if let successiveEvent = toProcess {
                    FxALog.debug(
                        "Ran \(evt) side-effects for state \(self.state), got successive event \(successiveEvent)."
                    )
                }
            }
            completionHandler()
        }
    }

    // swiftlint:disable function_body_length
    func stateActions(forState: AccountState, via: Event) -> Event? {
        switch forState {
        case .start: do {
                switch via {
                case .initialize: do {
                        if let acct = tryRestoreAccount() {
                            account = acct
                            return .accountRestored
                        } else {
                            return .accountNotFound
                        }
                    }
                default: return nil
                }
            }
        case .notAuthenticated: do {
                switch via {
                case .logout: do {
                        // Clean up internal account state and destroy the current FxA device record.
                        requireAccount().disconnect()
                        FxALog.info("Disconnected FxA account")
                        profile = nil
                        constellation = nil
                        accountStorage.clear()
                        // If we cannot instantiate FxA something is *really* wrong, crashing is a valid option.
                        account = createAccount()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: .accountLoggedOut,
                                object: nil
                            )
                        }
                    }
                case .accountNotFound: do {
                        account = createAccount()
                    }
                default: break // Do nothing
                }
            }
        case .authenticatedNoProfile: do {
                switch via {
                case let .authenticated(authData): do {
                        FxALog.info("Registering persistence callback")
                        requireAccount().registerPersistCallback(statePersistenceCallback)

                        FxALog.debug("Completing oauth flow")
                        do {
                            try requireAccount().completeOAuthFlow(code: authData.code, state: authData.state)
                        } catch {
                            // Reasons this can fail:
                            // - network errors
                            // - unknown auth state
                            // - authenticating via web-content; we didn't beginOAuthFlowAsync
                            FxALog.error("Error completing OAuth flow: \(error)")
                        }

                        FxALog.info("Initializing device")
                        requireConstellation().initDevice(
                            name: deviceConfig.name,
                            type: deviceConfig.deviceType,
                            capabilities: deviceConfig.capabilities
                        )

                        postAuthenticated(authType: authData.authType)

                        return Event.fetchProfile(ignoreCache: false)
                    }
                case .accountRestored: do {
                        FxALog.info("Registering persistence callback")
                        requireAccount().registerPersistCallback(statePersistenceCallback)

                        FxALog.info("Ensuring device capabilities...")
                        requireConstellation().ensureCapabilities(capabilities: deviceConfig.capabilities)

                        postAuthenticated(authType: .existingAccount)

                        return Event.fetchProfile(ignoreCache: false)
                    }
                case .recoveredFromAuthenticationProblem: do {
                        FxALog.info("Registering persistence callback")
                        requireAccount().registerPersistCallback(statePersistenceCallback)

                        FxALog.info("Initializing device")
                        requireConstellation().initDevice(
                            name: deviceConfig.name,
                            type: deviceConfig.deviceType,
                            capabilities: deviceConfig.capabilities
                        )

                        postAuthenticated(authType: .recovered)

                        return Event.fetchProfile(ignoreCache: false)
                    }
                case let .changedPassword(newSessionToken): do {
                        do {
                            try requireAccount().handleSessionTokenChange(sessionToken: newSessionToken)

                            FxALog.info("Initializing device")
                            requireConstellation().initDevice(
                                name: deviceConfig.name,
                                type: deviceConfig.deviceType,
                                capabilities: deviceConfig.capabilities
                            )

                            postAuthenticated(authType: .existingAccount)

                            return Event.fetchProfile(ignoreCache: false)
                        } catch {
                            FxALog.error("Error handling the session token change: \(error)")
                        }
                    }
                case let .fetchProfile(ignoreCache): do {
                        // Profile fetching and account authentication issues:
                        // https://github.com/mozilla/application-services/issues/483
                        FxALog.info("Fetching profile...")

                        do {
                            profile = try requireAccount().getProfile(ignoreCache: ignoreCache)
                        } catch {
                            return Event.failedToFetchProfile
                        }
                        return Event.fetchedProfile
                    }
                default: break // Do nothing
                }
            }
        case .authenticatedWithProfile: do {
                switch via {
                case .fetchedProfile: do {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: .accountProfileUpdate,
                                object: nil,
                                userInfo: ["profile": self.profile!]
                            )
                        }
                    }
                case let .fetchProfile(refresh): do {
                        FxALog.info("Refreshing profile...")
                        do {
                            profile = try requireAccount().getProfile(ignoreCache: refresh)
                        } catch {
                            return Event.failedToFetchProfile
                        }
                        return Event.fetchedProfile
                    }
                default: break // Do nothing
                }
            }
        case .authenticationProblem:
            switch via {
            case .authenticationError: do {
                    // Somewhere in the system, we've just hit an authentication problem.
                    // There are two main causes:
                    // 1) an access token we've obtain from fxalib via 'getAccessToken' expired
                    // 2) password was changed, or device was revoked
                    // We can recover from (1) and test if we're in (2) by asking the fxalib.
                    // If it succeeds, then we can go back to whatever
                    // state we were in before. Future operations that involve access tokens should
                    // succeed.

                    func onError() {
                        // We are either certainly in the scenario (2), or were unable to determine
                        // our connectivity state. Let's assume we need to re-authenticate.
                        // This uncertainty about real state means that, hopefully rarely,
                        // we will disconnect users that hit transient network errors during
                        // an authorization check.
                        // See https://github.com/mozilla-mobile/android-components/issues/3347
                        FxALog.error("Unable to recover from an auth problem.")
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: .accountAuthProblems,
                                object: nil
                            )
                        }
                    }

                    do {
                        let account = requireAccount()
                        let info = try account.checkAuthorizationStatus()
                        if !info.active {
                            onError()
                            return nil
                        }
                        account.clearAccessTokenCache()
                        // Make sure we're back on track by re-requesting the profile access token.
                        _ = try account.getAccessToken(scope: OAuthScope.profile)
                        return .recoveredFromAuthenticationProblem
                    } catch {
                        onError()
                    }
                    return nil
                }
            default: break // Do nothing
            }
        }
        return nil
    }

    func createAccount() -> PersistedFirefoxAccount {
        return PersistedFirefoxAccount(config: config.rustConfig)
    }

    func tryRestoreAccount() -> PersistedFirefoxAccount? {
        return accountStorage.read()
    }

    func makeDeviceConstellation(account: PersistedFirefoxAccount) -> DeviceConstellation {
        return DeviceConstellation(account: account)
    }

    func postAuthenticated(authType: FxaAuthType) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .accountAuthenticated,
                object: nil,
                userInfo: ["authType": authType]
            )
        }
        requireConstellation().refreshState()
    }

    func setupInternalListeners() {
        // Handle auth exceptions caught in classes that don't hold a reference to the manager.
        _ = NotificationCenter.default.addObserver(forName: .accountAuthException, object: nil, queue: nil) { _ in
            self.processEvent(event: .authenticationError) {}
        }
        // Reflect updates to the local device to our own in-memory model.
        _ = NotificationCenter.default.addObserver(
            forName: .constellationStateUpdate, object: nil, queue: nil
        ) { notification in
            if let userInfo = notification.userInfo, let newState = userInfo["newState"] as? ConstellationState {
                if let localDevice = newState.localDevice {
                    self.deviceConfig = DeviceConfig(
                        name: localDevice.displayName,
                        // The other properties are likely to not get modified.
                        type: self.deviceConfig.deviceType,
                        capabilities: self.deviceConfig.capabilities
                    )
                }
            }
        }
    }

    func requireAccount() -> PersistedFirefoxAccount {
        if let acct = account {
            return acct
        }
        preconditionFailure("initialize() must be called first.")
    }

    func requireConstellation() -> DeviceConstellation {
        if let cstl = constellation {
            return cstl
        }
        preconditionFailure("account must be set (sets constellation).")
    }

    // swiftlint:enable function_body_length
}

// swiftlint:enable type_body_length

extension Notification.Name {
    static let accountAuthException = Notification.Name("accountAuthException")
}

class FxAStatePersistenceCallback: PersistCallback {
    weak var manager: FxAccountManager?

    init(manager: FxAccountManager) {
        self.manager = manager
    }

    func persist(json: String) {
        manager?.accountStorage.write(json)
    }
}

public enum FxaAuthType {
    case existingAccount
    case signin
    case signup
    case pairing
    case recovered
    case other(reason: String)

    static func fromActionQueryParam(_ action: String) -> FxaAuthType {
        switch action {
        case "signin": return .signin
        case "signup": return .signup
        case "pairing": return .pairing
        default: return .other(reason: action)
        }
    }
}

public struct FxaAuthData {
    public let code: String
    public let state: String
    public let authType: FxaAuthType

    /// These constructor paramers shall be extracted from the OAuth final redirection URL query
    /// parameters.
    public init(code: String, state: String, actionQueryParam: String) {
        self.code = code
        self.state = state
        authType = FxaAuthType.fromActionQueryParam(actionQueryParam)
    }
}

extension DeviceConfig {
    init(name: String, type: DeviceType, capabilities: [DeviceCapability]) {
        self.init(name: name, deviceType: type, capabilities: capabilities)
    }
}
