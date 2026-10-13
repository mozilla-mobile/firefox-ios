// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import Testing

@testable import QuickAnswersKit

struct QuickAnswersConversationTests {
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
    func test_applyHistory_withoutAssistantRole_inlinesTurnsInQuestion() async {
        let subject = createSubject()
        await subject.append(question: "What is the weather?", answer: "Sunny")

        let messages = await subject.applyHistory(
            to: [systemMessage],
            question: "And tomorrow?",
            supportsAssistantRole: false
        )

        #expect(messages.map(\.role) == [.system, .user])
        #expect(
            messages.last?.content
                == "The user asked \"What is the weather?\" and was told \"Sunny\". Considering that, answer: And tomorrow?"
        )
    }

    @Test
    func test_applyHistory_withoutAssistantRole_inlinesLastTwoTurnsOnly() async {
        let subject = createSubject()
        await subject.append(question: "Q1", answer: "A1")
        await subject.append(question: "Q2", answer: "A2")
        await subject.append(question: "Q3", answer: "A3")

        let messages = await subject.applyHistory(to: [], question: "Q4", supportsAssistantRole: false)

        #expect(
            messages.first?.content
                == "The user asked \"Q2\" and was told \"A2\". The user asked \"Q3\" and was told \"A3\". "
                + "Considering that, answer: Q4"
        )
    }

    @Test
    func test_applyHistory_withoutAssistantRole_trimsLongAnswers() async {
        let subject = createSubject()
        await subject.append(question: "Q1", answer: String(repeating: "a", count: 300))

        let messages = await subject.applyHistory(to: [], question: "Q2", supportsAssistantRole: false)

        let trimmedAnswer = String(repeating: "a", count: 200) + "\u{2026}"
        #expect(
            messages.first?.content == "The user asked \"Q1\" and was told \"\(trimmedAnswer)\". Considering that, answer: Q2"
        )
    }

    // MARK: - Helper
    private func createSubject() -> QuickAnswersConversation {
        return QuickAnswersConversation()
    }
}
