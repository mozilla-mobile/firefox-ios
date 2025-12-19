// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Wrapper for AccountsProvider that adds error simulation capability for hidden settings.
/// This keeps the Ecosia framework clean while allowing Client module to inject simulation behavior.
///
/// This wrapper is configured in AppDelegate and used throughout the app via dependency injection.
final class AccountsProviderWrapper: AccountsProviderProtocol {

    private let wrapped: AccountsProviderProtocol

    init(wrapped: AccountsProviderProtocol = AccountsProvider()) {
        self.wrapped = wrapped
    }

    func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        // Debug: Simulate impact API error if enabled
        if UserDefaults.standard.bool(forKey: SimulateImpactAPIErrorSetting.debugKey) {
            EcosiaLogger.accounts.info("🐛 [DEBUG] Simulating impact API error")
            throw NSError(domain: "EcosiaDebug", code: -1, userInfo: [NSLocalizedDescriptionKey: "Debug: Simulated impact API error"])
        }

        return try await wrapped.registerVisit(accessToken: accessToken)
    }
}
