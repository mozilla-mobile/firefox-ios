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
    func test_saveSession_withFlagOn_setsLatestSession() {
        let subject = createSubject(isReturnToAnswerEnabled: true)

        subject.saveSession(makeSnapshot(question: "Question"))

        #expect(subject.latestSession?.question == "Question")
        #expect(sessionStorage.latestSession?.question == "Question")
    }

    @Test
    func test_saveSession_withFlagOff_doesNotSave() {
        let subject = createSubject(isReturnToAnswerEnabled: false)

        subject.saveSession(makeSnapshot(question: "Question"))

        #expect(subject.latestSession == nil)
        #expect(sessionStorage.latestSession == nil)
    }

    @Test
    func test_latestSession_withFlagOff_returnsNil() {
        sessionStorage.latestSession = makeSnapshot(question: "Question")
        let subject = createSubject(isReturnToAnswerEnabled: false)

        #expect(subject.latestSession == nil)
    }

    @Test
    func test_restoredSession_returningWithFlagOn_returnsLatestSession() {
        sessionStorage.latestSession = makeSnapshot(question: "Question")
        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)

        #expect(subject.restoredSession?.question == "Question")
    }

    @Test
    func test_restoredSession_notReturning_returnsNil() {
        sessionStorage.latestSession = makeSnapshot(question: "Question")
        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: false)

        #expect(subject.restoredSession == nil)
    }

    @Test
    func test_restoredSession_returningWithFlagOff_returnsNil() {
        sessionStorage.latestSession = makeSnapshot(question: "Question")
        let subject = createSubject(isReturnToAnswerEnabled: false, isReturningToAnswer: true)

        #expect(subject.restoredSession == nil)
    }

    @Test
    func test_removeAllSessions_clearsLatestSession() {
        let subject = createSubject(isReturnToAnswerEnabled: true)
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

    private func createSubject(
        isReturnToAnswerEnabled: Bool = false,
        isReturningToAnswer: Bool = false
    ) -> Store {
        let subject = Store(
            prefs: prefs,
            sessionStorage: sessionStorage,
            feature: QuickAnswersFeature(
                model: .exa,
                isOptInRedesignEnabled: false,
                isFollowUpEnabled: false,
                isReturnToAnswerEnabled: isReturnToAnswerEnabled
            ),
            isReturningToAnswer: isReturningToAnswer
        )
        return subject
    }
}
