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
    let sessionStorage = QuickAnswersSessionStorage()

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

    @Test
    func test_saveSession_setsLatestSession() {
        let subject = createSubject()

        subject.saveSession(makeSnapshot(question: "Question"))

        #expect(subject.latestSession?.question == "Question")
        #expect(sessionStorage.latestSession?.question == "Question")
    }

    @Test
    func test_removeAllSessions_clearsLatestSession() {
        let subject = createSubject()
        subject.saveSession(makeSnapshot(question: "Question"))

        subject.removeAllSessions()

        #expect(subject.latestSession == nil)
    }

    // MARK: - Helper
    private func makeSnapshot(question: String) -> QuickAnswersSessionSnapshot {
        return QuickAnswersSessionSnapshot(
            question: question,
            result: .empty(),
            conversation: MockQuickAnswersConversation()
        )
    }

    private func createSubject() -> Store {
        let subject = Store(prefs: prefs, sessionStorage: sessionStorage)
        return subject
    }
}
