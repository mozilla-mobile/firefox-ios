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
    func emailFocusShouldDisplayRelayPrompt(url: String) -> Bool
}

final class RelayController: RelayControllerProtocol {
    private enum RelayOAuthClientID: String {
        case release = "7f1a38400a0df47b"
        case stage = "41b4363ae36440a9"
    }

    // MARK: - Properties

    static let shared = RelayController()

    static let isFeatureEnabled = {
        LegacyFeatureFlagsManager.shared.isFeatureEnabled(.relayIntegration, checking: .buildOnly)
    }()

    private let logger: Logger
    private let profile: Profile

    // MARK: - Init

    private init(logger: Logger = DefaultLogger.shared, profile: Profile = AppContainer.shared.resolve()) {
        self.logger = logger
        self.profile = profile
    }

    // MARK: - RelayControllerProtocol

    func emailFocusShouldDisplayRelayPrompt(url: String) -> Bool {
        guard Self.isFeatureEnabled else { return false }

        // TODO: Check for Relay OAuth attached client. Forthcoming.
        guard profile.hasAccount() else { return false }

        // TODO: [FXIOS-13625] Forthcoming.
        return true
    }

    // MARK: - Private Utilities

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
