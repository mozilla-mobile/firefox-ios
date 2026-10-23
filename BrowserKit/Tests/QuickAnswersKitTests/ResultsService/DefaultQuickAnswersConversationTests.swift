// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import Testing

@testable import QuickAnswersKit

struct DefaultQuickAnswersConversationTests {
    private let systemMessage = QuickAnswersMessage(role: .system, content: "Instructions")

    @Test
    func test_applyHistory_withoutTurns_appendsQuestion() async {
        let subject = createSubject()

        let messages = await subject.applyHistory(
            to: [systemMessage],
            question: "What is the weather?",
            supportsAssistantRole: true
        )

        #expect(messages.map(\.role) == [.system, .user])
        #expect(messages.map(\.content) == ["Instructions", "What is the weather?"])
    }

    @Test
    func test_applyHistory_withAssistantRole_appendsTurnsAsMessages() async {
        let subject = createSubject()
        await subject.append(question: "What is the weather?", answer: "Sunny")

        let messages = await subject.applyHistory(
            to: [systemMessage],
            question: "And tomorrow?",
            supportsAssistantRole: true
        )

        #expect(messages.map(\.role) == [.system, .user, .assistant, .user])
        #expect(messages.map(\.content) == ["Instructions", "What is the weather?", "Sunny", "And tomorrow?"])
    }

    @Test
    func test_applyHistory_withoutAssistantRole_appendsQuestionOnly() async {
        let subject = createSubject()
        await subject.append(question: "What is the weather?", answer: "Sunny")

        let messages = await subject.applyHistory(
            to: [systemMessage],
            question: "And tomorrow?",
            supportsAssistantRole: false
        )

        #expect(messages.map(\.role) == [.system, .user])
        #expect(messages.map(\.content) == ["Instructions", "And tomorrow?"])
    }

    // MARK: - Helper
    private func createSubject() -> DefaultQuickAnswersConversation {
        return DefaultQuickAnswersConversation()
    }
}
