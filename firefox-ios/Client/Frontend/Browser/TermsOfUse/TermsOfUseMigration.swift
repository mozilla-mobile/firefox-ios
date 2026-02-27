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
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAccepted)

        // Migrate TermsOfServiceAcceptedDate
        if let acceptedDate = prefs.timestampForKey(PrefsKeys.TermsOfServiceAcceptedDate) {
            prefs.setTimestamp(acceptedDate, forKey: PrefsKeys.TermsOfUseAcceptedDate)
            prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAcceptedDate)
        }
    }

    private func migrateLegacyToSAcceptance() {
        let hasDate = prefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate)

        guard hasDate == nil else { return }

        // Use installation date as accepted date
        let installationDate = InstallationUtils.inferredDateInstalledOn ?? Date()
        prefs.setTimestamp(installationDate.toTimestamp(), forKey: PrefsKeys.TermsOfUseAcceptedDate)

        // Record date metric for legacy users who just got migrated
        TermsOfServiceTelemetry().recordToUAcceptDate(acceptedDate: installationDate)
    }
}
