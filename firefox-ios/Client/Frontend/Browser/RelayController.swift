// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Account
import Shared

// NOTE: This is a WIP as part of the Relay Phase 1 MVP. This code will be restructured
// soon; unit tests are also forthcoming. For now, tracking that here: FXIOS-14222. -MR

typealias RelayPopulateCompletion = @MainActor  (RelayMaskGenerationResult) -> Void

/// Describes public protocol for Relay component to track state and facilitate
/// messaging between the BVC, keyboard accessory, and A~S Relay APIs.
protocol RelayControllerProtocol {
    /// Returns whether Relay Settings should be available. For Phase 1 this is true if the
    /// user is logged into Mozilla sync and already has Relay enabled on their account.
    @MainActor
    func shouldDisplayRelaySettings() -> Bool

    /// Whether to present the UI for a Relay mask after focusing on an email field.
    /// This should account for all logic necessary for Relay display, which includes:
    ///    - User account status (signed into Mozilla / Relay active)
    ///    - Allow and Block lists
    /// - Parameter String: The website URL.
    /// - Returns: `true` if the website is valid for Relay, after checking block/allow lists.
    @MainActor
    func emailFocusShouldDisplayRelayPrompt(url: URL) -> Bool

    /// Requests the RelayController to populate the email tab for the actively focused field
    /// in the given tab. A safety check is performed internally to make sure this tab is the
    /// same one that was focused originally in `emailFieldFocused`. If the two differ, the
    /// operation is cancelled.
    /// - Parameter tab: the tab to populate. The email field is expected to be focused, otherwise a JS error will be logged.
    /// - Parameter completion: the completion block called once the action is resolved.
    @MainActor
    func populateEmailFieldWithRelayMask(for tab: Tab,
                                         completion: @escaping RelayPopulateCompletion)

    /// Notifies the RelayController which tab is currently focused for the purposes of generating a Relay mask.
    /// - Parameter tab: the current tab.
    @MainActor
    func emailFieldFocused(in tab: Tab)

    @MainActor
    var telemetry: RelayMaskTelemetry { get }
}

protocol RelayAccountStatusProvider {
    @MainActor
    var accountStatus: RelayAccountStatus { get set }
}

/// Describes the result of an attempt to generate a Relay mask for an email field.
enum RelayMaskGenerationResult {
    /// A new mask was generated successfully.
    case newMaskGenerated
    /// User is on a free plan and their limit has been reached.
    /// For Phase 1, one of the user's existing masks will be randomly picked.
    case freeTierLimitReached
    /// Generation failed due to expired OAuth token.
    case expiredToken
    /// A problem occurred.
    case error
}

/// Describes the general state of Relay availability on the user's existing Mozilla account.
/// This begins with a state of `unknown`. For Phase 1 it is checked periodically and then
/// cached, due to the required APIs being slow to return, we cannot hit it on-demand on the MT.
enum RelayAccountStatus {
    /// Relay is available.
    case available
    /// Relay is not available on this user's Mozilla account.
    case unavailable
    /// Account status is unknown.
    case unknown
    /// The account status is actively being updated.
    case updating
}

@MainActor
final class RelayAccountStatusProviderImplementation: RelayAccountStatusProvider {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    internal var accountStatus: RelayAccountStatus = .unknown {
        didSet {
            logger.log("Updated Relay account status from \(oldValue) to: \(accountStatus)", level: .info, category: .relay)
        }
    }
}

@MainActor
final class RelayController: RelayControllerProtocol, Notifiable {
    private enum RelayOAuthClientID: String {
        case release = "9ebfe2c2f9ea3c58"
        case stage = "41b4363ae36440a9"
    }

    enum RelayClientConfiguration {
        case prod
        case staging

        var serverURL: String {
            switch self {
            case .prod: return "https://relay.firefox.com"
            case .staging: return "https://relay.allizom.org"
            }
        }

        var scope: String { OAuthScope.relay }
    }

    // MARK: - Properties

    let telemetry: RelayMaskTelemetry

    static let isFeatureEnabled = {
        if AppConstants.isRunningUnitTest { return true }
#if targetEnvironment(simulator) && MOZ_CHANNEL_developer
        return true
#else
        return LegacyFeatureFlagsManager.shared.isFeatureEnabled(.relayIntegration, checking: .buildOnly)
#endif
    }()

    private let logger: Logger
    private let profile: Profile
    private let config: RelayClientConfiguration
    private var relayRSClient: RelayRemoteSettingsClientProtocol?
    private var client: RelayClientProtocol?
    private var isCreatingClient = false
    private var isGeneratingMask = false
    private let notificationCenter: NotificationProtocol
    private weak var focusedTab: Tab?
    private var accountStatusProvider: RelayAccountStatusProvider
    private var accountStatus: RelayAccountStatus {
        get { accountStatusProvider.accountStatus }
        set { accountStatusProvider.accountStatus = newValue }
    }

    // MARK: - Init

    init(logger: Logger = DefaultLogger.shared,
         profile: Profile = AppContainer.shared.resolve(),
         relayClient: RelayClientProtocol? = nil,
         relayRSClient: RelayRemoteSettingsClientProtocol? = nil,
         relayAccountStatusProvider: RelayAccountStatusProvider? = nil,
         gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
         config: RelayClientConfiguration = .prod,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.logger = logger
        self.profile = profile
        let isStaging = profile.prefs.boolForKey(PrefsKeys.UseStageServer) ?? false
        logger.log("Relay server: \(isStaging ? "staging" : "prod")", level: .info, category: .relay)
        self.config = isStaging ? .staging : .prod
        self.notificationCenter = notificationCenter
        self.telemetry = RelayMaskTelemetry(gleanWrapper: gleanWrapper)

        if let relayClient {
            self.client = relayClient
        }

        self.accountStatusProvider = if let relayAccountStatusProvider { relayAccountStatusProvider } else {
            RelayAccountStatusProviderImplementation(logger: logger)
        }

        self.relayRSClient = if let relayRSClient { relayRSClient } else {
            RelayRemoteSettingsClient(rsService: profile.remoteSettingsService)
        }
        beginObserving()
        performPostLaunchUpdate()
    }

    // MARK: - RelayControllerProtocol

    func emailFocusShouldDisplayRelayPrompt(url: URL) -> Bool {
        // Note: the prefs key defaults to On. No value (nil) should be treated as true.
        guard Self.isFeatureEnabled else {
            logger.log("Display Relay: false. Feature disabled.", level: .info, category: .relay)
            return false
        }
        guard profile.prefs.boolForKey(PrefsKeys.ShowRelayMaskSuggestions) ?? true else {
            logger.log("Display Relay: false. Local setting disabled.", level: .info, category: .relay)
            return false
        }
        guard client != nil else {
            logger.log("Display Relay: false. No Relay client.", level: .info, category: .relay)
            return false
        }
        guard let relayRSClient, hasRelayAccount() else {
            logger.log("Display Relay: false. (No client / Relay acct)", level: .info, category: .relay)
            return false
        }
        guard let domain = url.baseDomain, let host = url.normalizedHost else {
            logger.log("Display Relay: false. (Invalid domain/host.)", level: .info, category: .relay)
            return false
        }
        let shouldShow = relayRSClient.shouldShowRelay(host: host, domain: domain, isRelayUser: true)
        logger.log("Display Relay: \(shouldShow). (Allow-list check.)", level: .info, category: .relay)
        return shouldShow
    }

    func populateEmailFieldWithRelayMask(for tab: Tab,
                                         completion: @escaping RelayPopulateCompletion) {
        populateEmailFieldWithRelayMask(for: tab, isRetry: false, completion: completion)
    }

    private func populateEmailFieldWithRelayMask(for tab: Tab,
                                                 isRetry: Bool,
                                                 completion: @escaping RelayPopulateCompletion) {
        guard !isGeneratingMask || isRetry else {
            logger.log("Duplicate generate mask actions. Bailing.", level: .info, category: .relay)
            return
        }
        guard focusedTab == nil || focusedTab === tab else {
            logger.log("Attempting to populate Relay mask after tab has changed. Bailing.",
                       level: .warning,
                       category: .relay)
            focusedTab = nil
            // Note: this is an edge case error and in this scenario we will not call the completion at
            // all, given that we're no longer on the correct tab.
            return
        }

        guard let webView = tab.webView, let client else {
            logger.log("No tab webview available, or client is nil. Will not populate email field.",
                       level: .warning,
                       category: .relay)
            completion(.error)
            return
        }
        logger.log("Will generate Relay mask.", level: .info, category: .relay)
        isGeneratingMask = true
        Task {
            defer { isGeneratingMask = false }
            let (email, result) = await generateRelayMask(for: tab.url?.baseDomain ?? "", client: client)
            if result == .expiredToken && !isRetry {
                // Attempt a single retry of OAuth refresh
                attemptOAuthTokenRefresh(tab: tab, completion: completion)
                return
            }

            // If an error occurred, or our OAuth token refresh attempt failed, complete with error.
            guard result != .error && result != .expiredToken else { completion(.error); return }

            guard let jsonData = try? JSONEncoder().encode(email),
                  let encodedEmailStr = String(data: jsonData, encoding: .utf8) else {
                logger.log("Couldn't encode string for Relay JS injection.", level: .warning, category: .relay)
                completion(.error)
                return
            }

            logger.log("Will send payload to WKWebView", level: .info, category: .relay)

            let jsFunctionCall = "window.__firefox__.logins.fillRelayEmail(\(encodedEmailStr))"
            let closureLogger = logger
            webView.evaluateJavascriptInDefaultContentWorld(jsFunctionCall) { (result, error) in
                guard error == nil else {
                    closureLogger.log("Javascript error: \(error!)", level: .warning, category: .relay)
                    return
                }
            }

            completion(result)
        }
    }

    func emailFieldFocused(in tab: Tab) {
        focusedTab = tab
    }

    func shouldDisplayRelaySettings() -> Bool {
        return Self.isFeatureEnabled && hasRelayAccount()
    }

    // MARK: - Private Utilities

    private func performPostLaunchUpdate() {
        let postLaunchDelay: TimeInterval = 5.0
        Timer.scheduledTimer(withTimeInterval: postLaunchDelay, repeats: false) { [weak self] _ in
            self?.logger.log("Will perform Relay post-launch refresh.", level: .info, category: .relay)
            Task { @MainActor in
                self?.updateRelayAccountStatus()
            }
        }
    }

    private func invalidateClient() {
        client = nil
    }

    private func attemptOAuthTokenRefresh(tab: Tab, completion: @escaping RelayPopulateCompletion) {
        // Attempt to refresh OAuth token and retry.
        logger.log("Attempting OAuth refresh. Will re-create Relay client.", level: .info, category: .relay)
        invalidateClient()
        createRelayClientIfNeeded(isRefresh: true) { [weak self] in
            // This completion will be called async after we attempt to re-create a new RelayClient
            // with a fresh OAuth token. At this point we can re-try to populate.
            self?.populateEmailFieldWithRelayMask(for: tab, isRetry: true, completion: completion)
        }
    }

    nonisolated private func generateRelayMask(for websiteDomain: String,
                                               client: RelayClientProtocol) async -> (mask: String?,
                                                                                      result: RelayMaskGenerationResult) {
        do {
            logger.log("Relay: createAddress()", level: .info, category: .relay)
            let relayAddress = try client.createAddress(description: "", generatedFor: websiteDomain, usedOn: "")
            telemetry.autofilled(newMask: true)
            return (relayAddress.fullAddress, .newMaskGenerated)
        } catch {
            // Certain errors we need to custom-handle

            if case let RelayApiError.Api(status, code, _) = error,
               status == 401,
               code == "invalid_token" || code == "unknown" {
                // Invalid OAuth token
                logger.log("OAuth token expired.", level: .info, category: .relay)
                return (nil, .expiredToken)
            } else if case let RelayApiError.Api(_, code, _) = error, code == "free_tier_limit" {
                // For Phase 1, we return a random email from the user's list
                logger.log("Free tier limit reached. Using random mask.", level: .info, category: .relay)
                do {
                    let fullList = try client.fetchAddresses()
                    if let relayMask = fullList.randomElement() {
                        telemetry.autofilled(newMask: false)
                        return (relayMask.fullAddress, .freeTierLimitReached)
                    } else {
                        logger.log("Couldn't fetch random mask", level: .warning, category: .relay)
                    }
                } catch {
                    telemetry.autofillFailed(error: error.localizedDescription)
                    logger.log("Error fetching address list: \(error)", level: .warning, category: .relay)
                }
            } else {
                telemetry.autofillFailed(error: error.localizedDescription)
                logger.log("API error creating Relay address: \(error)", level: .warning, category: .relay)
            }
        }
        return (nil, .error)
    }

    private func beginObserving() {
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [Notification.Name.ProfileDidStartSyncing,
                        Notification.Name.FirefoxAccountChanged]
        )
    }

    func handleNotifications(_ notification: Notification) {
        logger.log("Received notification '\(notification.name.rawValue)'.", level: .info, category: .relay)
        Task { @MainActor in
            updateRelayAccountStatus()
        }
    }

    private func updateRelayAccountStatus() {
        guard Self.isFeatureEnabled else { return }
        guard profile.hasAccount() else {
            logger.log("No sync account. Relay disabled.", level: .info, category: .relay)
            accountStatus = .unavailable
            return
        }
        guard accountStatus != .updating else {
            logger.log("Already updating account. Will skip redundant update.", level: .info, category: .relay)
            return
        }
        accountStatus = .updating
        let isStaging = config == .staging
        // Fetch the account status (off the main thread)
        Task {
            await fetchRelayAccountAvailability(isStaging: isStaging)
            if hasRelayAccount() {
                createRelayClientIfNeeded()
            } else {
                client = nil
            }
        }
    }

    /// Creates the Relay client, if needed. This is safe to call redundantly.
    /// - Parameters:
    ///   - isRefresh: true if we are refreshing an expired token. If so we want to avoid the use of the OAuth cache.
    ///   - completion: completion to be called upon success/failure.
    private func createRelayClientIfNeeded(isRefresh: Bool = false, completion: (() -> Void)? = nil) {
        guard client == nil, !isCreatingClient else { return }
        guard let acctManager = RustFirefoxAccounts.shared.accountManager else {
            logger.log("Couldn't create client, no account manager.", level: .debug, category: .relay)
            return
        }
        isCreatingClient = true
        let useCache = !isRefresh
        acctManager.getAccessToken(scope: config.scope, useCache: useCache) { [config, weak self] result in
            switch result {
            case .failure(let error):
                self?.logger.log("Error getting access token for Relay: \(error)", level: .warning, category: .relay)
                self?.isCreatingClient = false
                completion?()
            case .success(let tokenInfo):
                do {
                    let clientResult = try RelayClient(serverUrl: config.serverURL, authToken: tokenInfo.token)
                    self?.handleRelayClientCreated(clientResult)
                } catch {
                    self?.logger.log("Error creating Relay client: \(error)", level: .warning, category: .relay)
                }
                self?.isCreatingClient = false
                completion?()
            }
        }
    }

    private func handleRelayClientCreated(_ client: RelayClient) {
        self.client = client
        isCreatingClient = false
        logger.log("Relay client created.", level: .info, category: .relay)
    }

    private func hasRelayAccount() -> Bool {
        return accountStatus == .available
    }

    /// Checks the current OAuth client status to determine Relay availability, and then updates the internal
    /// account status back on the main actor.
    /// - Parameter isStaging: whether we should use Staging servers.
    nonisolated private func fetchRelayAccountAvailability(isStaging: Bool) async {
        guard let result = RustFirefoxAccounts.shared.accountManager?.getAttachedClients() else { return }

        logger.log("Will check OAuth clients.", level: .info, category: .relay)
        let hasRelayOAuth = {
            switch result {
            case .success(let clients):
                let OAuthID = isStaging ? RelayOAuthClientID.stage.rawValue : RelayOAuthClientID.release.rawValue
                let hasRelayID = clients.contains(where: { $0.clientId == OAuthID })
                if !hasRelayID {
                    logger.log("No Relay service on this account.", level: .info, category: .relay)
                }
                return hasRelayID
            case .failure(let error):
                logger.log("Error fetching OAuth clients for Relay: \(error)", level: .warning, category: .relay)
                return false
            }
        }()
        Task { @MainActor in
            accountStatus = hasRelayOAuth ? .available : .unavailable
        }
    }
}
