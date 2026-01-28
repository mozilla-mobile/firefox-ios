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

        // Only migrate if TermsOfServiceAccepted exists and is true
        guard hasAcceptedToS else { return }

        migrateTermsOfServicePrefs()
        migrateLegacyToSAcceptance()
    }

    private func migrateTermsOfServicePrefs() {
        // Migrate TermsOfServiceAccepted
        prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        
        // Migrate TermsOfServiceAcceptedDate
        if let acceptedDate = prefs.timestampForKey(PrefsKeys.TermsOfServiceAcceptedDate) {
            prefs.setTimestamp(acceptedDate, forKey: PrefsKeys.TermsOfUseAcceptedDate)
        }

        // Migrate TermsOfServiceAcceptedVersion
        if let acceptedVersion = prefs.stringForKey(PrefsKeys.TermsOfServiceAcceptedVersion) {
            prefs.setString(acceptedVersion, forKey: PrefsKeys.TermsOfUseAcceptedVersion)
        }

        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAccepted)
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAcceptedDate)
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAcceptedVersion)
    }

    private func migrateLegacyToSAcceptance() {
        let hasVersion = prefs.stringForKey(PrefsKeys.TermsOfUseAcceptedVersion)
        let hasDate = prefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate)

        guard hasDate == nil || hasVersion == nil else { return }

        // Use terms of use version 4 as convention,
        // since cannot be determined the exact version that was accepted
        let pastVersion = 4
        prefs.setString(String(pastVersion), forKey: PrefsKeys.TermsOfUseAcceptedVersion)

        // Use installation date as accepted date
        let installationDate = InstallationUtils.inferredDateInstalledOn ?? Date()
        prefs.setTimestamp(installationDate.toTimestamp(), forKey: PrefsKeys.TermsOfUseAcceptedDate)

        // Record date and version telemetry for legacy users who just got migrated
        TermsOfServiceTelemetry().recordDateAndVersion(acceptedDate: installationDate)
    }
}
