// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

// TODO: - FXIOS-16678 remove migration struct after enough release cycles (i.e 157.x)
/// Moves the summarizer language preference onto its namespaced key.
struct SummarizerPrefsMigration {
    private let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    /// Copies the saved language onto `PrefsKeys.Summarizer.selectedLanguage` and drops the legacy key.
    /// No-ops once the legacy key is gone, so it is safe to run on every launch.
    func migrateSelectedLanguage() {
        guard let savedLanguage = prefs.stringForKey(PrefsKeys.Summarizer.legacySelectedLanguage) else { return }

        if prefs.stringForKey(PrefsKeys.Summarizer.selectedLanguage) == nil {
            prefs.setString(savedLanguage, forKey: PrefsKeys.Summarizer.selectedLanguage)
        }
        prefs.removeObjectForKey(PrefsKeys.Summarizer.legacySelectedLanguage)
    }
}
