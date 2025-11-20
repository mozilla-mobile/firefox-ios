// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Account
import Shared

/// Describes public protocol for Relay component to track state and facilitate
/// messaging between the BVC, keyboard accessory, and A~S Relay APIs.
protocol RelayControllerProtocol {
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
    @MainActor
    func populateEmailFieldWithRelayMask(for tab: Tab,
                                         completion: @Sendable @MainActor @escaping (RelayMaskGenerationResult) -> Void)

    /// Notifies the RelayController which tab is currently focused for the purposes of generating a Relay mask.
    /// - Parameter tab: the current tab.
    @MainActor
    func emailFieldFocused(in tab: Tab)
}

/// Describes the result of an attempt to generate a Relay mask for an email field.
enum RelayMaskGenerationResult {
    /// A new mask was generated successfully.
    case newMaskGenerated
    /// User is on a free plan and their limit has been reached.
    /// For Phase 1, one of the user's existing masks will be randomly picked.
    case freeTierLimitReached
    /// A problem occurred.
    case error
}

@MainActor
final class RelayController: RelayControllerProtocol, Notifiable {
    private enum RelayOAuthClientID: String {
        case release = "9ebfe2c2f9ea3c58"
        case stage = "41b4363ae36440a9"
    }

    private enum RelayClientConfiguration {
        case prod
        case staging

        var serverURL: String {
            switch self {
            case .prod: return "https://relay.firefox.com"
            case .staging: return "https://relay.allizom.org"
            }
        }

        var scope: String {
            "profile"
        }
    }

    // MARK: - Properties

    static let shared = RelayController()

    static let isFeatureEnabled = {
#if targetEnvironment(simulator) && MOZ_CHANNEL_developer
        return true
#else
        return LegacyFeatureFlagsManager.shared.isFeatureEnabled(.relayIntegration, checking: .buildOnly)
#endif
    }()

    private let logger: Logger
    private let profile: Profile
    private let config: RelayClientConfiguration
    private var relayRSClient: RelayRemoteSettingsClient?
    private var client: RelayClient?
    private var isCreatingClient = false
    private let notificationCenter: NotificationProtocol
    private weak var focusedTab: Tab?

    // MARK: - Init

    private init(logger: Logger = DefaultLogger.shared,
                 profile: Profile = AppContainer.shared.resolve(),
                 config: RelayClientConfiguration = .prod,
                 notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.logger = logger
        self.profile = profile
        self.config = config
        self.notificationCenter = notificationCenter

        configureRelayRSClient()
        beginObserving()
    }

    // MARK: - RelayControllerProtocol

    func emailFocusShouldDisplayRelayPrompt(url: URL) -> Bool {
        guard Self.isFeatureEnabled, let relayRSClient, hasRelayAccount() else { return false }
        guard let domain = url.baseDomain, let host = url.normalizedHost else { return false }
        let shouldShow = relayRSClient.shouldShowRelay(host: host, domain: domain, isRelayUser: true)
        return shouldShow
    }

    func populateEmailFieldWithRelayMask(for tab: Tab,
                                         completion: @escaping @MainActor @Sendable (RelayMaskGenerationResult) -> Void) {
        guard focusedTab == nil || focusedTab === tab else {
            logger.log("[RELAY] Attempting to populate Relay mask after tab has changed. Bailing.",
                       level: .warning,
                       category: .autofill)
            focusedTab = nil
            // Note: this is an edge case error and in this scenario we will not call the completion at
            // all, given that we're no longer on the correct tab.
            return
        }

        guard let webView = tab.webView else { return }
        let (email, result) = generateRelayMask(for: tab.url?.baseDomain ?? "")
        guard result != .error else { completion(.error); return }

        guard let jsonData = try? JSONEncoder().encode(email),
              let encodedEmailStr = String(data: jsonData, encoding: .utf8) else {
            logger.log("[RELAY] Couldn't encode string for Relay JS injection.", level: .warning, category: .autofill)
            completion(.error)
            return
        }

        let jsFunctionCall = "window.__firefox__.logins.fillRelayEmail(\(encodedEmailStr))"
        let closureLogger = logger
        webView.evaluateJavascriptInDefaultContentWorld(jsFunctionCall) { (result, error) in
            guard error == nil else {
                closureLogger.log("[RELAY] Javascript error: \(error!)", level: .warning, category: .autofill)
                return
            }
        }

        completion(result)
    }

    func emailFieldFocused(in tab: Tab) {
        focusedTab = tab
    }

    // MARK: - Private Utilities

    private func generateRelayMask(for websiteDomain: String) -> (mask: String?, result: RelayMaskGenerationResult) {
        guard let client else { return (nil, .error) }
        do {
            let relayAddress = try client.createAddress(description: "", generatedFor: websiteDomain, usedOn: "")
            return (relayAddress.fullAddress, .newMaskGenerated)
        } catch {
            // Certain errors we need to custom-handle
            if case let RelayApiError.Api(_, code, _) = error, code == "free_tier_limit" {
                // For Phase 1, we return a random email from the user's list
                logger.log("[RELAY] Free tier limit reached. Using random mask.", level: .info, category: .autofill)
                do {
                    let fullList = try client.fetchAddresses()
                    if let relayMask = fullList.randomElement() {
                        return (relayMask.fullAddress, .freeTierLimitReached)
                    } else {
                        logger.log("[RELAY] Couldn't fetch random mask", level: .warning, category: .autofill)
                    }
                } catch {
                    logger.log("[RELAY] Error fetching address list: \(error)", level: .warning, category: .autofill)
                }
            } else {
                logger.log("[RELAY] API error creating Relay address: \(error)", level: .warning, category: .autofill)
            }
        }
        return (nil, .error)
    }

    private func configureRelayRSClient() {
        relayRSClient = RelayRemoteSettingsClient(rsService: profile.remoteSettingsService)
    }

    private func beginObserving() {
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [Notification.Name.ProfileDidStartSyncing,
                        Notification.Name.ProfileDidFinishSyncing,
                        Notification.Name.FirefoxAccountChanged]
        )
    }

    func handleNotifications(_ notification: Notification) {
        logger.log("[RELAY] Received notification '\(notification.name.rawValue)'.", level: .info, category: .autofill)
        Task { @MainActor in
            guard Self.isFeatureEnabled else { return }
            if hasRelayAccount() {
                createRelayClient()
            }
        }
    }

    /// Creates the Relay client, if needed. This is safe to call redundantly.
    private func createRelayClient() {
        guard client == nil, !isCreatingClient else { return }
        guard let acctManager = RustFirefoxAccounts.shared.accountManager else {
            logger.log("[RELAY] Couldn't create client, no account manager.", level: .debug, category: .autofill)
            return
        }

        acctManager.getAccessToken(scope: config.scope) { [config, weak self] result in
            switch result {
            case .failure(let error):
                self?.logger.log("[RELAY] Error getting access token for Relay: \(error)", level: .warning, category: .autofill)
            case .success(let tokenInfo):
                do {
                    let clientResult = try RelayClient(serverUrl: config.serverURL, authToken: tokenInfo.token)
                    self?.handleRelayClientCreated(clientResult)
                } catch {
                    self?.logger.log("[RELAY] Error creating Relay client: \(error)", level: .warning, category: .autofill)
                    self?.isCreatingClient = false
                }
            }
        }
    }

    private func handleRelayClientCreated(_ client: RelayClient) {
        self.client = client
        isCreatingClient = false
        logger.log("[RELAY] Relay client created.", level: .info, category: .autofill)
    }

    private func isFxAStaging() -> Bool {
        let prefs = profile.prefs
        return prefs.boolForKey(PrefsKeys.UseStageServer) ?? false
    }

    private func hasRelayAccount() -> Bool {
        guard profile.hasAccount() else { return false }
        guard let result = RustFirefoxAccounts.shared.accountManager?.getAttachedClients() else { return false }

        switch result {
        case .success(let clients):
            let OAuthID = isFxAStaging() ? RelayOAuthClientID.stage.rawValue : RelayOAuthClientID.release.rawValue
            return clients.contains(where: { $0.clientId == OAuthID })
        case .failure(let error):
            logger.log("Error fetching OAuth clients for Relay: \(error)", level: .warning, category: .autofill)
            return false
        }
    }
}
