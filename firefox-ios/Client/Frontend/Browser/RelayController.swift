// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Account
import Shared
import WebKit

/// Default RelayControllerProtocol implementation.
/// Handles account status updates and logic for Relay.
@MainActor
final class RelayController: RelayControllerProtocol, Notifiable {
    private enum RelayOAuthClientID: String {
        case release = "9ebfe2c2f9ea3c58"
        case stage = "41b4363ae36440a9"
    }

    private enum RelayAPIErrorCode {
        static let freeTierLimitReached = "free_tier_limit"
        static let invalidToken = "invalid_token"
        static let unknown = "unknown"
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

    struct RelayUpdateConfiguration {
        let postLaunchUpdateDelay: TimeInterval
        static func `default`() -> RelayUpdateConfiguration {
            return RelayUpdateConfiguration(postLaunchUpdateDelay: 5.0)
        }
    }

    // MARK: - Properties

    let telemetry: RelayMaskTelemetry

    static let isFeatureEnabled = {
        if AppConstants.isRunningUnitTest { return true }
#if targetEnvironment(simulator) && MOZ_CHANNEL_developer
        return true
#else
        return (AppContainer.shared.resolve() as FeatureFlagProviding).isEnabled(.relayIntegration)
#endif
    }()

    private let logger: Logger
    private let profile: Profile
    private let clientConfig: RelayClientConfiguration
    private let updateConfig: RelayUpdateConfiguration
    private let jsEvaluator: RelayJavascriptEvaluator
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
         clientConfig: RelayClientConfiguration = .prod,
         updateConfig: RelayUpdateConfiguration = RelayUpdateConfiguration.default(),
         javascriptEvaluator: RelayJavascriptEvaluator = DefaultRelayJavascriptEvaluator(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.logger = logger
        self.profile = profile
        let isStaging = profile.prefs.boolForKey(PrefsKeys.UseStageServer) ?? false
        logger.log("Relay server: \(isStaging ? "staging" : "prod")", level: .info, category: .relay)
        self.clientConfig = isStaging ? .staging : .prod
        self.notificationCenter = notificationCenter
        self.updateConfig = updateConfig
        self.jsEvaluator = javascriptEvaluator
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
        func bail(_ message: String) -> Bool {
            logger.log("Display Relay: false. \(message)", level: .info, category: .relay); return false
        }

        guard Self.isFeatureEnabled else { return bail("Feature disabled.") }
        let prefKey = PrefsKeys.ShowRelayMaskSuggestions
        guard profile.prefs.boolForKey(prefKey) ?? true else { return bail("Local setting disabled.") }
        guard client != nil else { return bail("No Relay client.") }
        guard let relayRSClient, hasRelayAccount() else { return bail("No client / Relay account") }
        guard let domain = url.baseDomain, let host = url.normalizedHost else { return bail("Invalid domain/host.") }

        let shouldShow = relayRSClient.shouldShowRelay(host: host, domain: domain, isRelayUser: true)
        logger.log("Display Relay: \(shouldShow). (Allow-list check.)", level: .info, category: .relay)
        return shouldShow
    }

    func populateEmailFieldWithRelayMask(for tab: Tab, completion: @escaping RelayPopulateCompletion) {
        populateEmailFieldWithRelayMask(for: tab, isRetry: false, completion: completion)
    }

    func emailFieldFocused(in tab: Tab) {
        focusedTab = tab
    }

    func shouldDisplayRelaySettings() -> Bool {
        return Self.isFeatureEnabled && hasRelayAccount()
    }

    // MARK: - Private Utilities

    private func populateEmailFieldWithRelayMask(for tab: Tab,
                                                 isRetry: Bool,
                                                 completion: @escaping RelayPopulateCompletion) {
        guard !isGeneratingMask || isRetry else {
            logger.log("Duplicate generate mask actions. Bailing.", level: .info, category: .relay)
            return
        }
        guard focusedTab == nil || focusedTab === tab else {
            logger.log("Attempting to populate Relay mask after changing tab. Bailing.", level: .warning, category: .relay)
            focusedTab = nil
            // Note: this is an edge case error and in this scenario we will not call the completion at
            // all, given that we're no longer on the correct tab.
            return
        }

        guard let client else {
            logger.log("Nil client. Won't populate Relay email.", level: .warning, category: .relay)
            completion(.error)
            return
        }
        logger.log("Will generate Relay mask.", level: .info, category: .relay)
        generateEmailAndPopulateField(for: tab, isRetry: isRetry, client: client, completion: completion)
    }

    private func generateEmailAndPopulateField(for tab: Tab,
                                               isRetry: Bool,
                                               client: RelayClientProtocol,
                                               completion: @escaping RelayPopulateCompletion) {
        isGeneratingMask = true
        Task {
            defer { isGeneratingMask = false }
            let (email, result) = await generateRelayMask(for: tab.url?.baseDomain ?? "", client: client)
            if result == .expiredToken && !isRetry {
                attemptOAuthTokenRefresh(tab: tab, completion: completion) // Attempt a single retry of OAuth refresh
                return
            }

            // If an error occurred, or our OAuth token refresh attempt failed, complete with error.
            guard result != .error && result != .expiredToken else { completion(.error); return }

            let populateSuccess = await populateWebViewForm(for: tab, email: email)
            completion(populateSuccess ? result : .error)
        }
    }

    /// Populates the webview of the supplied tab with the final email result
    /// - Parameters:
    ///   - tab: the tab with the webview form
    ///   - email: the Relay email
    /// - Returns: true if successful
    private func populateWebViewForm(for tab: Tab, email: String?) async -> Bool {
        guard let webView = tab.webView, let email else {
            logger.log("No tab webview. Won't populate Relay email.", level: .warning, category: .relay)
            return false
        }
        guard let jsonData = try? JSONEncoder().encode(email),
              let encodedEmailStr = String(data: jsonData, encoding: .utf8) else {
            logger.log("Couldn't encode string for Relay JS injection.", level: .warning, category: .relay)
            return false
        }

        logger.log("Will send payload to WKWebView", level: .info, category: .relay)
        let closureLogger = logger

        let javascriptFunc = "window.__firefox__.logins.fillRelayEmail(\(encodedEmailStr))"
        var didFailJS = false
        do {
            _ = try await jsEvaluator.evaluateJavaScript(javascriptFunc,
                                                         for: webView,
                                                         in: nil,
                                                         contentWorld: WKContentWorld.defaultClient)
        } catch {
            closureLogger.log("Javascript error: \(error)", level: .warning, category: .relay)
            didFailJS = true
        }
        return !didFailJS
    }

    private func attemptOAuthTokenRefresh(tab: Tab, completion: @escaping RelayPopulateCompletion) {
        // Attempt to refresh OAuth token and retry.
        logger.log("Attempting OAuth refresh. Will re-create Relay client.", level: .info, category: .relay)
        client = nil
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
            let relayAddress = try client.createAddress(description: websiteDomain, generatedFor: websiteDomain, usedOn: "")
            telemetry.autofilled(newMask: true)
            return (relayAddress.fullAddress, .newMaskGenerated)
        } catch {
            // Certain errors we need to custom-handle

            if case let RelayApiError.Api(status, code, _) = error,
               status == 401,
               code == RelayAPIErrorCode.invalidToken || code == RelayAPIErrorCode.unknown {
                // Invalid OAuth token
                logger.log("OAuth token expired.", level: .info, category: .relay)
                return (nil, .expiredToken)
            } else if case let RelayApiError.Api(_, code, _) = error, code == RelayAPIErrorCode.freeTierLimitReached {
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
        let isStaging = clientConfig == .staging
        // Fetch the account status (async)
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
        acctManager.getAccessToken(scope: clientConfig.scope, useCache: useCache) { [weak self] result in
            self?.handleRelayCreateClientResult(result, completion: completion)
        }
    }

    private func handleRelayCreateClientResult(_ result: Result<AccessTokenInfo, Error>,
                                               completion: (() -> Void)? = nil) {
        switch result {
        case .failure(let error):
            logger.log("Error getting access token for Relay: \(error)", level: .warning, category: .relay)
            isCreatingClient = false
            completion?()
        case .success(let tokenInfo):
            do {
                let clientResult = try RelayClient(serverUrl: clientConfig.serverURL, authToken: tokenInfo.token)
                didCreateRelayClient(clientResult)
            } catch {
                logger.log("Error creating Relay client: \(error)", level: .warning, category: .relay)
            }
            isCreatingClient = false
            completion?()
        }
    }

    private func didCreateRelayClient(_ client: RelayClient) {
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
        let status: RelayAccountStatus = {
            switch result {
            case .success(let clients):
                let oAuthID: RelayOAuthClientID = isStaging ? RelayOAuthClientID.stage : RelayOAuthClientID.release
                let hasRelayID = clients.contains(where: { $0.clientId == oAuthID.rawValue })
                if !hasRelayID {
                    logger.log("No Relay service on this account.", level: .info, category: .relay)
                }
                return hasRelayID ? .available : .unavailable
            case .failure(let error):
                logger.log("Error fetching OAuth clients for Relay: \(error)", level: .warning, category: .relay)
                return .unavailable
            }
        }()
        Task { @MainActor in
            accountStatus = status
        }
    }

    // MARK: - Notifications

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

    private func performPostLaunchUpdate() {
        let delay = updateConfig.postLaunchUpdateDelay
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.logger.log("Will perform Relay post-launch refresh.", level: .info, category: .relay)
            Task { @MainActor in
                self?.updateRelayAccountStatus()
            }
        }
    }
}

protocol RelayJavascriptEvaluator {
    @MainActor func evaluateJavaScript(_ javaScript: String,
                                       for: WKWebView,
                                       in frame: WKFrameInfo?,
                                       contentWorld: WKContentWorld) async throws -> Any?
}

final class DefaultRelayJavascriptEvaluator: RelayJavascriptEvaluator {
    @MainActor func evaluateJavaScript(_ javaScript: String,
                                       for webView: WKWebView,
                                       in frame: WKFrameInfo?,
                                       contentWorld: WKContentWorld) async throws -> Any? {
        return try await webView.evaluateJavaScript(javaScript, in: frame, contentWorld: contentWorld)
    }
}
