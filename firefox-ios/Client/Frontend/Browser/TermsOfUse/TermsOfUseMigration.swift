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

    /// Migrates TermsOfService prefs  to TermsOfUse if needed and deletes old prefs data
    func migrateTermsOfServicePrefs() {
        let hasAcceptedToU = prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false
        let hasAcceptedToS = prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == 1
        
        /// Only migrate if TermsOfUseAccepted doesn't exist but TermsOfServiceAccepted does
        guard hasAcceptedToS && !hasAcceptedToU else { return }
        
        prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        
        if let acceptedDate = prefs.timestampForKey(PrefsKeys.TermsOfServiceAcceptedDate) {
            prefs.setTimestamp(acceptedDate, forKey: PrefsKeys.TermsOfUseAcceptedDate)
        }
        
        if let acceptedVersion = prefs.stringForKey(PrefsKeys.TermsOfServiceAcceptedVersion) {
            prefs.setString(acceptedVersion, forKey: PrefsKeys.TermsOfUseAcceptedVersion)
        }
        
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAccepted)
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAcceptedDate)
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAcceptedVersion)
    }
}

