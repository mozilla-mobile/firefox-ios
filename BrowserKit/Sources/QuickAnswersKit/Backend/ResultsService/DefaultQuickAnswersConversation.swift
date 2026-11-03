// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import LLMKit

// MARK: - Protocol
/// The exchanges made with the model in a Quick Answers session, replayed so follow up questions are answered
/// in context.
protocol QuickAnswersConversation: Sendable {
    func append(question: String, answer: String) async

    /// Appends the past exchanges and the new `question` to `messages`. When the provider doesn't support
    /// `assistant` messages only the new `question` is appended.
    func applyHistory(
        to messages: [QuickAnswersMessage],
        question: String,
        supportsAssistantRole: Bool
    ) async -> [QuickAnswersMessage]
}

actor DefaultQuickAnswersConversation: QuickAnswersConversation {
    private struct Turn {
        let question: String
        let answer: String
    }

    private var turns: [Turn] = []

    func append(question: String, answer: String) {
        turns.append(Turn(question: question, answer: answer))
    }

    func applyHistory(
        to messages: [QuickAnswersMessage],
        question: String,
        supportsAssistantRole: Bool
    ) -> [QuickAnswersMessage] {
        let questionMessage = QuickAnswersMessage(role: .user, content: question)
        guard supportsAssistantRole else { return messages + [questionMessage] }
        let history = turns.flatMap {
            [
                QuickAnswersMessage(role: .user, content: $0.question),
                QuickAnswersMessage(role: .assistant, content: $0.answer)
            ]
        }
        return messages + history + [questionMessage]
    }
}
