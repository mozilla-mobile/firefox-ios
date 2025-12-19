// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import OSLog

/// Utility for integrating native authentication with browser data clearing operations
/// Ensures authentication state remains consistent when user data is cleared
public enum DataClearingIntegration {

    /// Handles native logout when cookies are cleared through browser settings
    /// Should be called whenever cookies are cleared to maintain auth state consistency
    public static func handleEcosiaAuthCookieClearing() async {
        guard EcosiaAuthenticationService.shared.isLoggedIn else {
            EcosiaLogger.auth.info("User not logged in - skipping logout on cookie clearing")
            return
        }

        EcosiaLogger.auth.info("Triggering native logout due to cookie clearing")

        do {
            // Perform logout without triggering web logout since cookies are already being cleared
            try await EcosiaAuthenticationService.shared.logout(triggerWebLogout: false)
            EcosiaLogger.auth.info("Native logout completed successfully during cookie clearing")
        } catch {
            EcosiaLogger.auth.error("Failed to perform native logout during cookie clearing: \(error)")
        }
    }
}
