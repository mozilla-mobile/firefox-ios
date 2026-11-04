// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Persists the opt-in of the Quick Answers feature, and keeps the parked session in memory.
@MainActor
struct Store {
    private let prefs: Prefs
    private let sessionStorage: QuickAnswersSessionStorage

    init(prefs: Prefs, sessionStorage: QuickAnswersSessionStorage) {
        self.prefs = prefs
        self.sessionStorage = sessionStorage
    }

    /// Whether the user has accepted the Quick Answers opt-in.
    var isOptInCompleted: Bool {
        return prefs.boolForKey(PrefsKeys.QuickAnswers.optInCompleted) ?? false
    }

    /// The session parked for the user to return to, if any.
    var latestSession: QuickAnswersSessionSnapshot? {
        return sessionStorage.latestSession
    }

    /// Marks the Quick Answers opt-in as completed.
    func setOptInCompleted() {
        prefs.setBool(true, forKey: PrefsKeys.QuickAnswers.optInCompleted)
    }

    func saveSession(_ session: QuickAnswersSessionSnapshot) {
        sessionStorage.latestSession = session
    }

    func removeAllSessions() {
        sessionStorage.removeAll()
    }
}
