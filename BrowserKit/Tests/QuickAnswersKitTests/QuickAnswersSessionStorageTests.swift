// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

@testable import QuickAnswersKit

@MainActor
struct QuickAnswersSessionStorageTests {
    @Test
    func test_removeAll_clearsLatestSession() {
        let subject = createSubject()
        subject.latestSession = QuickAnswersSessionSnapshot(
            question: "Question",
            result: .empty(),
            conversation: MockQuickAnswersConversation()
        )

        subject.removeAll()

        #expect(subject.latestSession == nil)
    }

    // MARK: - Helper
    private func createSubject() -> QuickAnswersSessionStorage {
        return QuickAnswersSessionStorage()
    }
}
