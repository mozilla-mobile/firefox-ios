// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Testing
import TestKit

@testable import QuickAnswersKit

@MainActor
struct StoreTests {
    let prefs = MockProfilePrefs()

    @Test
    func test_isOptInCompleted_whenNoValueStored_returnsFalse() {
        let subject = createSubject()

        #expect(subject.isOptInCompleted == false)
    }

    @Test
    func test_setOptInCompleted_persistsTrue() {
        let subject = createSubject()

        subject.setOptInCompleted()

        #expect(subject.isOptInCompleted == true)
        #expect(prefs.boolForKey(PrefsKeys.QuickAnswers.optInCompleted) == true)
    }

    // MARK: - Helper
    private func createSubject() -> Store {
        let subject = Store(prefs: prefs)
        return subject
    }
}
