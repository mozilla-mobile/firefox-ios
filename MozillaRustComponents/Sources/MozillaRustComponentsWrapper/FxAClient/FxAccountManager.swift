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
// FIXME: FXIOS-13537 Make this type actually Sendable, or isolate or otherwise protect any mutable state
open class FxAccountManager: @unchecked Sendable {
    let accountStorage: KeyChainAccountStorage
    let config: FxAConfig
    // FIXME: FXIOS-13501 Unprotected shared mutable state is an error in Swift 6
    public nonisolated(unsafe) var deviceConfig: DeviceConfig
    let applicationScopes: [String]

    // Serial by default (no .concurrent attribute). All finite state machine (FSM) state
    // mutations and accountStateSideEffects calls must happen on this queue.
    let fxaFsmQueue = DispatchQueue(label: "com.mozilla.fxa-mgr-queue")

    // FIXME: FXIOS-13501 Unprotected shared mutable state is an error in Swift 6
    nonisolated(unsafe) var acct: PersistedFirefoxAccount?
    var account: PersistedFirefoxAccount? {
        get { return acct }
        set {
            acct = newValue
            if let acc = acct {
                constellation = makeDeviceConstellation(account: acc)
            }
        }
    }

    var state: FxaState = .uninitialized
    var profile: Profile?
    var constellation: DeviceConstellation?
    // Stores the auth type from the processEvent(.completeOAuthFlow) call
    var pendingAuthType: FxaAuthType?

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
    public func initialize(completionHandler: @escaping @MainActor @Sendable (Result<Void, Error>) -> Void) {
        fxaFsmQueue.async {
            if let account = self.tryRestoreAccount() {
                self.account = account
            } else {
                self.account = self.createAccount()
            }
            let deviceConfig = DeviceConfig(
                name: self.deviceConfig.name,
                deviceType: self.deviceConfig.deviceType,
                capabilities: self.deviceConfig.capabilities
            )
            self.processEvent(.initialize(deviceConfig: deviceConfig))
            DispatchQueue.main.async { completionHandler(.success(())) }
        }
    }

    /// Returns true the user is currently logged-in to an account, no matter if they need to reconnect or not.
    public func hasAccount() -> Bool {
        return state == .connected || state == .authIssues
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
        return state == .authIssues
    }

    /// Set the user data before completing their authentication
    public func setUserData(userData: UserData, completion: @Sendable @escaping () -> Void) {
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
        completionHandler: @escaping @MainActor @Sendable (Result<URL, Error>) -> Void
    ) {
        FxALog.info("beginAuthentication")
        fxaFsmQueue.async {
            let actualScopes = scopes.isEmpty ? self.applicationScopes : scopes
            self.processEvent(.beginOAuthFlow(service: "", scopes: actualScopes, entrypoint: entrypoint))
            let result: Result<URL, Error>
            if case let .authenticating(oauthUrl, _) = self.state, let url = URL(string: oauthUrl) {
                result = .success(url)
            } else {
                result = .failure(FxaError.Other(message: "beginAuthentication: unexpected state \(self.state)"))
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
        completionHandler: @Sendable @MainActor @escaping (Result<URL, Error>) -> Void
    ) {
        fxaFsmQueue.async {
            let actualScopes = scopes.isEmpty ? self.applicationScopes : scopes
            self.processEvent(.beginPairingFlow(pairingUrl: pairingUrl, service: "", scopes: actualScopes, entrypoint: entrypoint))
            let result: Result<URL, Error>
            if case let .authenticating(oauthUrl, _) = self.state, let url = URL(string: oauthUrl) {
                result = .success(url)
            } else {
                result = .failure(FxaError.Other(message: "beginPairingAuthentication: unexpected state \(self.state)"))
            }
            DispatchQueue.main.async { completionHandler(result) }
        }
    }

    /// Finish an authentication flow.
    ///
    /// If it succeeds, a `.accountAuthenticated` notification will get fired.
    public func finishAuthentication(
        authData: FxaAuthData,
        completionHandler: @escaping @MainActor @Sendable (Result<Void, Error>) -> Void
    ) {
        fxaFsmQueue.async {
            self.pendingAuthType = authData.authType
            let event = FxaEvent.completeOAuthFlow(code: authData.code, state: authData.state)
            do {
                self.state = try self.requireAccount().processEvent(event: event)
            } catch {
                // Reset state machine back to .disconnected before reporting failure.
                self.processEvent(.cancelOAuthFlow)
                DispatchQueue.main.async { completionHandler(.failure(error)) }
                return
            }
            self.accountStateSideEffects(forState: self.state, via: event)
            let result: Result<Void, Error>
            if case .connected = self.state {
                result = .success(())
            } else {
                result = .failure(FxaError.Other(message: "finishAuthentication: unexpected state \(self.state)"))
            }
            DispatchQueue.main.async { completionHandler(result) }
        }
    }

    /// Try to get an OAuth access token.
    public func getAccessToken(
        scope: String,
        useCache: Bool = true,
        completionHandler: @MainActor @Sendable @escaping (Result<AccessTokenInfo, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            do {
                let tokenInfo = try self.requireAccount().getAccessToken(scope: scope, useCache: useCache)
                DispatchQueue.main.async { completionHandler(.success(tokenInfo)) }
            } catch {
                DispatchQueue.main.async { completionHandler(.failure(error)) }
            }
        }
    }

    /// Get the device ID registered for this account.
    /// The device is registered synchronously during `finishAuthentication`, so this is available
    /// immediately after login without waiting for `DeviceConstellation.refreshState()`.
    public func getCurrentDeviceId() -> Result<String, Error> {
        do {
            return try .success(requireAccount().getCurrentDeviceId())
        } catch {
            return .failure(error)
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

    /// Clear the access token cache for reauthentication.
    public func clearAccessTokenCache() {
        account?.clearAccessTokenCache()
    }

    /// Get a list of the attached OAuth clients.
    public func getAttachedClients() -> Result<[AttachedClient], Error> {
        do {
            return try .success(requireAccount().getAttachedClients())
        } catch {
            return .failure(error)
        }
    }

    /// The account password has been changed locally and a new session token has been sent to us through WebChannel.
    public func handlePasswordChanged(
        newSessionToken: String,
        completionHandler: @escaping @MainActor @Sendable () -> Void
    ) {
        fxaFsmQueue.async {
            do {
                try self.requireAccount().handleSessionTokenChange(sessionToken: newSessionToken)
                // handleSessionTokenChange invalidates the old refresh token so the device
                // record on the server is stale. Re-register the device.
                self.requireConstellation().initDevice(
                    name: self.deviceConfig.name,
                    type: self.deviceConfig.deviceType,
                    capabilities: self.deviceConfig.capabilities
                )
                self.postAuthenticated(authType: .existingAccount)
                self.refreshProfileAsync(ignoreCache: false)
            } catch {
                FxALog.error("Error handling the session token change: \(error)")
            }
            DispatchQueue.main.async { completionHandler() }
        }
    }

    /// Get the account management URL.
    public func getManageAccountURL(
        entrypoint: String,
        completionHandler: @MainActor @Sendable @escaping (Result<URL, Error>) -> Void
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
        completionHandler: @escaping @MainActor @Sendable (Result<URL, Error>) -> Void
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
        completionHandler: @escaping @MainActor @Sendable (Result<URL, Error>) -> Void
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
        refreshProfileAsync(ignoreCache: ignoreCache)
    }

    /// Get the user profile synchronously. It could be empty
    /// because of network or authentication problems.
    public func accountProfile() -> Profile? {
        if state == .connected || state == .authIssues {
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
    public func logout(completionHandler: @escaping @MainActor @Sendable (Result<Void, Error>) -> Void) {
        fxaFsmQueue.async {
            self.processEvent(.disconnect)
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

    /// Runs the Rust state machine with the given event and runs side effects for the new state.
    /// Must be called on `fxaFsmQueue`.
    func processEvent(_ fxaEvent: FxaEvent) {
        FxALog.debug("processEvent: event '\(fxaEvent)'")
        do {
            state = try requireAccount().processEvent(event: fxaEvent)
        } catch {
            FxALog.error("processEvent: Error in processEvent: \(error)")
            return
        }
        FxALog.debug("processEvent: new FxaState '\(state)'")
        accountStateSideEffects(forState: state, via: fxaEvent)
    }

    func accountStateSideEffects(forState: FxaState, via: FxaEvent) {
        switch forState {
        case .disconnected:
            switch via {
            case .disconnect:
                onDisconnected()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .accountLoggedOut, object: nil)
                }
            case .beginOAuthFlow, .beginPairingFlow:
                onDisconnected()
                // Failed to begin auth, caller receives an error from the nil URL check
            case .completeOAuthFlow:
                onDisconnected()
                pendingAuthType = nil
                // Failed to complete auth, app will detect via accountNeedsReauth()
            default: break
            }

        case .authenticating:
            break // No side effects; URL is extracted by the beginAuthentication caller

        case .connected:
            requireAccount().registerPersistCallback(statePersistenceCallback)
            let authType: FxaAuthType
            let ignoreCache: Bool
            switch via {
            case .initialize:
                authType = .existingAccount
                ignoreCache = false
            case .completeOAuthFlow:
                authType = pendingAuthType ?? .existingAccount
                pendingAuthType = nil
                ignoreCache = true
            case .checkAuthorizationStatus:
                // Recovered from auth problem
                authType = .recovered
                ignoreCache = true
            default:
                return
            }
            postAuthenticated(authType: authType)
            refreshProfileAsync(ignoreCache: ignoreCache)

        case .authIssues:
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountAuthProblems, object: nil)
            }

        case .uninitialized:
            break
        }
    }

    // swiftlint:enable function_body_length
    private func refreshProfileAsync(ignoreCache: Bool) {
        DispatchQueue.global().async {
            do {
                let profile = try self.requireAccount().getProfile(ignoreCache: ignoreCache)
                // Write back on fxaFsmQueue so we don't race with onDisconnected(), which clears
                // self.profile on that same queue. Drop the result if the account was reset
                // (e.g. logout) while in flight.
                self.fxaFsmQueue.async {
                    guard self.state == .connected || self.state == .authIssues else { return }
                    self.profile = profile
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .accountProfileUpdate,
                            object: nil,
                            userInfo: ["profile": profile]
                        )
                    }
                }
            } catch {
                FxALog.error("Failed to fetch profile: \(error)")
            }
        }
    }

    private func onDisconnected() {
        profile = nil
        constellation = nil
        accountStorage.clear()
        // Replace the persisted account with a fresh one. A freshly created PersistedFirefoxAccount
        // starts in .uninitialized. Without this call,
        // subsequent events like .beginOAuthFlow would be rejected by the FSM.
        account = createAccount()
        let newDeviceConfig = DeviceConfig(
            name: deviceConfig.name,
            deviceType: deviceConfig.deviceType,
            capabilities: deviceConfig.capabilities
        )
        processEvent(.initialize(deviceConfig: newDeviceConfig))
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
            self.fxaFsmQueue.async {
                self.processEvent(.checkAuthorizationStatus)
            }
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
                        deviceType: self.deviceConfig.deviceType,
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

public enum FxaAuthType: Sendable {
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

public struct FxaAuthData: Sendable {
    public let code: String
    public let state: String
    public let authType: FxaAuthType

    /// These constructor parameters shall be extracted from the OAuth final redirection URL query
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
