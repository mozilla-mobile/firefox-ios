// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Persists the opt-in of the Quick Answers feature, and keeps the latest answered session in memory.
@MainActor
struct Store {
    private let prefs: Prefs
    private let sessionStorage: QuickAnswersSessionStorage
    private let feature: QuickAnswersFeature
    private let isReturningToAnswer: Bool

    init(
        prefs: Prefs,
        sessionStorage: QuickAnswersSessionStorage,
        feature: QuickAnswersFeature,
        isReturningToAnswer: Bool
    ) {
        self.prefs = prefs
        self.sessionStorage = sessionStorage
        self.feature = feature
        self.isReturningToAnswer = isReturningToAnswer
        if !isReturningToAnswer {
            // Only a return to answer may read a stored session, so any other start drops it.
            sessionStorage.removeAll()
        }
    }

    /// Whether the user has accepted the Quick Answers opt-in.
    var isOptInCompleted: Bool {
        return prefs.boolForKey(PrefsKeys.QuickAnswers.optInCompleted) ?? false
    }

    /// The session the user is returning to, if any. Always nil when not returning or when return to answer is disabled.
    var restoredSession: QuickAnswersSessionSnapshot? {
        return isReturningToAnswer ? latestSession : nil
    }

    /// The latest answered session the user can return to, if any. Always nil when return to answer is disabled.
    var latestSession: QuickAnswersSessionSnapshot? {
        guard feature.isReturnToAnswerEnabled else { return nil }
        return sessionStorage.latestSession
    }

    /// Marks the Quick Answers opt-in as completed.
    func setOptInCompleted() {
        prefs.setBool(true, forKey: PrefsKeys.QuickAnswers.optInCompleted)
    }

    func saveSession(_ session: QuickAnswersSessionSnapshot) {
        guard feature.isReturnToAnswerEnabled else { return }
        sessionStorage.latestSession = session
    }
}
