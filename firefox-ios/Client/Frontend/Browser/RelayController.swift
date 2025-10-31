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
    func emailFocusShouldDisplayRelayPrompt(origin: String) -> Bool
}

@MainActor
final class RelayController: RelayControllerProtocol {
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
            case .staging: assertionFailure("ToDo."); return "<invalid>"  // TBD.
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
    private var client: RelayClient?

    // MARK: - Init

    private init(logger: Logger = DefaultLogger.shared,
                 profile: Profile = AppContainer.shared.resolve(),
                 config: RelayClientConfiguration = .prod) {
        self.logger = logger
        self.profile = profile
        self.config = config
    }

    // MARK: - RelayControllerProtocol

    func emailFocusShouldDisplayRelayPrompt(origin: String) -> Bool {
        guard Self.isFeatureEnabled else { return false }

        // Phase 1: we only show Relay for existing signed-in accounts with Relay service
        guard hasRelayAccount() else { return false }

        // TODO: [FXIOS-13625] Check allow-list via RelayRemoteSettingsClient
        // https://github.com/mozilla/application-services/pull/7039/files
        return true
    }

    // MARK: - Private Utilities

    private func createRelayClient() {
        guard client == nil else { return }
        guard let acctManager = RustFirefoxAccounts.shared.accountManager else {
            logger.log("[RELAY] Couldn't create client, no account manager.", level: .debug, category: .autofill)
            return
        }

        let closureLogger = logger
        Task {
            acctManager.getAccessToken(scope: config.scope) { [config] result in
                switch result {
                case .failure(let error):
                    closureLogger.log("[RELAY] Error getting access token for Relay: \(error)", level: .warning, category: .autofill)
                case .success(let tokenInfo):
                    do {
                        let clientResult = try RelayClient(serverUrl: config.serverURL, authToken: tokenInfo.token)
                        Task { @MainActor in self.handleRelayClientCreated(clientResult) }
                    } catch {
                        closureLogger.log("[RELAY] Error creating Relay client: \(error)", level: .warning, category: .autofill)
                    }
                }
            }
        }
    }

    private func handleRelayClientCreated(_ client: RelayClient) {
        self.client = client
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
            let hasRelay = clients.contains(where: { $0.clientId == OAuthID })
            if hasRelay { createRelayClient() /* TEMP. Added here for early testing. */ }

            return hasRelay
        case .failure(let error):
            logger.log("Error fetching OAuth clients for Relay: \(error)", level: .warning, category: .autofill)
            return false
        }
    }
}
