// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

struct TermsOfUseMigration {
    private let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    /// Migrate TermsOfService prefs to TermsOfUse
    /// and add missing ToU date/version if needed
    func migrateTermsOfService() {
        let hasAcceptedToS = prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == 1

        // Only migrate if TermsOfServiceAccepted exists and is true.
        guard hasAcceptedToS else { return }

        // Migrate TermsOfServiceAccepted
        prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)

        let tosAcceptedDate = prefs.timestampForKey(PrefsKeys.TermsOfServiceAcceptedDate)
        let tosAcceptedVersion = prefs.stringForKey(PrefsKeys.TermsOfServiceAcceptedVersion)

        // Migrate TermsOfServiceAcceptedDate
        let acceptedTimestamp: Timestamp = {
            if let tosAcceptedDate {
                return tosAcceptedDate
            }
            // Use installation date as accepted date
            let installationDate = InstallationUtils.inferredDateInstalledOn ?? Date()
            return installationDate.toTimestamp()
        }()
        prefs.setTimestamp(acceptedTimestamp, forKey: PrefsKeys.TermsOfUseAcceptedDate)

        // Migrate TermsOfServiceAcceptedVersion
        let acceptedVersion: String = {
            if let tosAcceptedVersion {
                return tosAcceptedVersion
            }
            /// Use terms of use version 4 as convention,
            /// since cannot be determined the exact version that was accepted
            return "4"
        }()
        prefs.setString(acceptedVersion, forKey: PrefsKeys.TermsOfUseAcceptedVersion)

        // Remove old TermsOfService prefs
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAccepted)
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAcceptedDate)
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAcceptedVersion)
        
        // Record date and version telemetry if were missing
        if tosAcceptedDate == nil || tosAcceptedVersion == nil {
            let acceptedDate = Date.fromTimestamp(acceptedTimestamp)
            TermsOfServiceTelemetry().recordDateAndVersion(acceptedDate: acceptedDate)
        }
    }
}
