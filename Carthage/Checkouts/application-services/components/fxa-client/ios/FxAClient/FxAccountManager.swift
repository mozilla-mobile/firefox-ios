/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public extension Notification.Name {
    static let accountLoggedOut = Notification.Name("accountLoggedOut")
    static let accountAuthProblems = Notification.Name("accountAuthProblems")
    static let accountAuthenticated = Notification.Name("accountAuthenticated")
    static let accountProfileUpdate = Notification.Name("accountProfileUpdate")
    static let accountMigrationFailed = Notification.Name("accountMigrationFailed")
}

// swiftlint:disable type_body_length
open class FxAccountManager {
    let accountStorage: KeyChainAccountStorage
    let config: FxAConfig
    var deviceConfig: DeviceConfig
    let applicationScopes: [String]

    var acct: FxAccount?
    var account: FxAccount? {
        get { return acct }
        set {
            acct = newValue
            if let acc = acct {
                constellation = makeDeviceConstellation(account: acc)
            }
        }
    }

    var state: AccountState = AccountState.start
    var profile: Profile?
    var constellation: DeviceConstellation?
    var latestOAuthStateParam: String?

    /// Instanciate the account manager.
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

    private lazy var statePersistenceCallback: FxAStatePersistenceCallback = {
        FxAStatePersistenceCallback(manager: self)
    }()

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
            state == .authenticationProblem ||
            state == .canAutoretryMigration
    }

    /// Returns true if the account needs re-authentication.
    /// Your app should present the option to start a new OAuth flow.
    public func accountNeedsReauth() -> Bool {
        return state == .authenticationProblem
    }

    /// Returns true if there is a migration in-flight.
    /// The caller should then call `retryMigration`.
    public func accountMigrationInFlight() -> Bool {
        return state == .canAutoretryMigration
    }

    /// Begins a new authentication flow.
    ///
    /// This function returns a URL string that the caller should open in a webview.
    ///
    /// Once the user has confirmed the authorization grant, they will get redirected to `redirect_url`:
    /// the caller must intercept that redirection, extract the `code` and `state` query parameters and call
    /// `finishAuthentication(...)` to complete the flow.
    public func beginAuthentication(completionHandler: @escaping (Result<URL, Error>) -> Void) {
        FxALog.info("beginAuthentication")
        DispatchQueue.global().async {
            let result = self.updatingLatestAuthState { account in
                try account.beginOAuthFlow(scopes: self.applicationScopes)
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
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            let result = self.updatingLatestAuthState { account in
                try account.beginPairingFlow(pairingUrl: pairingUrl, scopes: self.applicationScopes)
            }
            DispatchQueue.main.async { completionHandler(result) }
        }
    }

    /// Run a "begin authentication" closure, extracting the returned `state` from the returned URL
    /// and put it aside for later in `latestOAuthStateParam`.
    /// Afterwards, in `finishAuthentication` we ensure that we are
    /// finishing the correct (and same) authentication flow.
    private func updatingLatestAuthState(_ beginFlowFn: (FxAccount) throws -> URL) -> Result<URL, Error> {
        do {
            let url = try beginFlowFn(requireAccount())
            let comps = URLComponents(url: url, resolvingAgainstBaseURL: true)
            latestOAuthStateParam = comps!.queryItems!.first(where: { $0.name == "state" })!.value
            return .success(url)
        } catch {
            return .failure(error)
        }
    }

    /// Use the provided user account information to sign-in without any user interaction.
    public func authenticateViaMigration(
        sessionToken: String,
        kSync: String,
        kXCS: String,
        completionHandler: @escaping (MigrationResult) -> Void
    ) {
        processEvent(event: .authenticateViaMigration(sessionToken: sessionToken, kSync: kSync, kXCS: kXCS)) {
            if self.accountMigrationInFlight() {
                completionHandler(.willRetry)
            } else if self.hasAccount() {
                completionHandler(.success)
            } else {
                completionHandler(.failure)
            }
        }
    }

    /// If `accountMigrationInFlight` returns true, this function should be called
    /// on a regular basic by the caller.
    public func retryMigration(completionHandler: @escaping (MigrationResult) -> Void) {
        processEvent(event: .retryMigration) {
            if self.accountMigrationInFlight() {
                completionHandler(.willRetry)
            } else if self.hasAccount() {
                completionHandler(.success)
            } else {
                completionHandler(.failure)
            }
        }
    }

    /// Finish an authentication flow.
    ///
    /// If it succeeds, a `.accountAuthenticated` notification will get fired.
    public func finishAuthentication(
        authData: FxaAuthData,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        if latestOAuthStateParam == nil {
            DispatchQueue.main.async { completionHandler(.failure(FirefoxAccountError.noExistingAuthFlow)) }
        } else if authData.state != latestOAuthStateParam {
            DispatchQueue.main.async { completionHandler(.failure(FirefoxAccountError.wrongAuthFlow)) }
        } else { /* state == latestAuthState */
            processEvent(event: .authenticated(authData: authData)) {
                DispatchQueue.main.async { completionHandler(.success(())) }
            }
        }
    }

    /// Try to get an OAuth access token.
    public func getAccessToken(scope: String, completionHandler: @escaping (Result<AccessTokenInfo, Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                let tokenInfo = try self.requireAccount().getAccessToken(scope: scope)
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
            return .success(try requireAccount().getSessionToken())
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
    public func getManageAccountURL(entrypoint: String) -> Result<URL, Error> {
        do {
            return .success(try requireAccount().getManageAccountURL(entrypoint: entrypoint))
        } catch {
            return .failure(error)
        }
    }

    /// Get the token server URL with `1.0/sync/1.5` appended at the end.
    public func getTokenServerEndpointURL() -> Result<URL, Error> {
        do {
            return .success(
                try requireAccount()
                    .getTokenServerEndpointURL()
                    .appendingPathComponent("1.0/sync/1.5")
            )
        } catch {
            return .failure(error)
        }
    }

    /// Refresh the user profile in the background.
    ///
    /// If it succeeds, a `.accountProfileUpdate` notification will get fired.
    public func refreshProfile() {
        processEvent(event: .fetchProfile) {
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

    let fxaFsmQueue = DispatchQueue(label: "com.mozilla.fxa-mgr-queue")

    internal func processEvent(event: Event, completionHandler: @escaping () -> Void) {
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
    internal func stateActions(forState: AccountState, via: Event) -> Event? {
        switch forState {
        case .start: do {
            switch via {
            case .initialize: do {
                if let acct = tryRestoreAccount() {
                    account = acct
                    if !acct.isInMigrationState() {
                        return .accountRestored
                    } else {
                        // We may have attempted a migration previously, which failed
                        // in a way that allows us to retry it.
                        return .inFlightMigration
                    }
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
                do {
                    try requireAccount().disconnect()
                    FxALog.info("Disconnected FxA account")
                } catch {
                    FxALog.error("Failed to fully disconnect the FxA account: \(error).")
                }
                profile = nil
                constellation = nil
                accountStorage.clear()
                // If we cannot instanciate FxA something is *really* wrong, crashing is a valid option.
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
            case let .authenticateViaMigration(sessionToken, kSync, kXCS): do {
                let acct = requireAccount()
                FxALog.info("Registering persistence callback")
                acct.registerPersistCallback(statePersistenceCallback)

                if acct.migrateFromSessionToken(
                    sessionToken: sessionToken,
                    kSync: kSync,
                    kXCS: kXCS
                ) {
                    return .authenticatedViaMigration
                }
                if acct.isInMigrationState() {
                    return .retryMigrationLater
                }
            }
            default: break // Do nothing
            }
        }
        case .canAutoretryMigration: do {
            switch via {
            case .retryMigration, .inFlightMigration: do {
                let acct = requireAccount()
                FxALog.info("Registering persistence callback")
                acct.registerPersistCallback(statePersistenceCallback)

                // Case 1: Success!
                if acct.retryMigrateFromSessionToken() {
                    return .authenticatedViaMigration
                }
                // Case 2: Transient error, we can still retry later.
                if acct.isInMigrationState() {
                    return .retryMigrationLater
                }
                // Case 3: Non-recoverable error, at this point there's nothing we can do.
                return .migrationFailure
            }
            default: break // Do Nothing
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
                    type: deviceConfig.type,
                    capabilities: deviceConfig.capabilities
                )

                postAuthenticated(authType: authData.authType)

                return Event.fetchProfile
            }
            case .accountRestored: do {
                FxALog.info("Registering persistence callback")
                requireAccount().registerPersistCallback(statePersistenceCallback)

                FxALog.info("Ensuring device capabilities...")
                requireConstellation().ensureCapabilities(capabilities: deviceConfig.capabilities)

                postAuthenticated(authType: .existingAccount)

                return Event.fetchProfile
            }
            case .authenticatedViaMigration: do {
                // Note that we are not registering an account persistence callback here like
                // we do in other `.authenticatedNoProfile` cases, because it would have been
                // already registered while handling any of the precursor events, such as
                // `.authenticateViaMigration`, `.retryMigration` or `.inFlightMigration`
                FxALog.info("Ensuring device capabilities...")
                // At the minimum, we need to ensure the device capabilities.
                requireConstellation().ensureCapabilities(capabilities: deviceConfig.capabilities)

                postAuthenticated(authType: .migrated)

                return Event.fetchProfile
            }
            case .recoveredFromAuthenticationProblem: do {
                FxALog.info("Registering persistence callback")
                requireAccount().registerPersistCallback(statePersistenceCallback)

                FxALog.info("Initializing device")
                requireConstellation().initDevice(
                    name: deviceConfig.name,
                    type: deviceConfig.type,
                    capabilities: deviceConfig.capabilities
                )

                postAuthenticated(authType: .recovered)

                return Event.fetchProfile
            }
            case let .changedPassword(newSessionToken): do {
                do {
                    try requireAccount().handleSessionTokenChange(sessionToken: newSessionToken)

                    FxALog.info("Initializing device")
                    requireConstellation().initDevice(
                        name: deviceConfig.name,
                        type: deviceConfig.type,
                        capabilities: deviceConfig.capabilities
                    )

                    postAuthenticated(authType: .existingAccount)

                    return Event.fetchProfile
                } catch {
                    FxALog.error("Error handling the session token change: \(error)")
                }
            }
            case .fetchProfile: do {
                // Profile fetching and account authentication issues:
                // https://github.com/mozilla/application-services/issues/483
                FxALog.info("Fetching profile...")

                do {
                    profile = try requireAccount().getProfile()
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
                    try account.clearAccessTokenCache()
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

    internal func createAccount() -> FxAccount {
        return try! FxAccount(config: config)
    }

    internal func tryRestoreAccount() -> FxAccount? {
        return accountStorage.read()
    }

    internal func makeDeviceConstellation(account: FxAccount) -> DeviceConstellation {
        return DeviceConstellation(account: account)
    }

    internal func postAuthenticated(authType: FxaAuthType) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .accountAuthenticated,
                object: nil,
                userInfo: ["authType": authType]
            )
        }
        requireConstellation().refreshState()
    }

    internal func setupInternalListeners() {
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
                        type: self.deviceConfig.type,
                        capabilities: self.deviceConfig.capabilities
                    )
                }
            }
        }
    }

    internal func requireAccount() -> FxAccount {
        if let acct = account {
            return acct
        }
        preconditionFailure("initialize() must be called first.")
    }

    internal func requireConstellation() -> DeviceConstellation {
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

    public init(manager: FxAccountManager) {
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
    case migrated
    case other(reason: String)

    internal static func fromActionQueryParam(_ action: String) -> FxaAuthType {
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

public struct DeviceConfig {
    let name: String
    let type: DeviceType
    let capabilities: [DeviceCapability]

    public init(name: String, type: DeviceType, capabilities: [DeviceCapability]) {
        self.name = name
        self.type = type
        self.capabilities = capabilities
    }
}
