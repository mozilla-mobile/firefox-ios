// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import LLMKit

/// The exchanges made with the model in a Quick Answers session, replayed so follow up questions are answered
/// in context.
actor QuickAnswersConversation {
    private struct Turn {
        let question: String
        let answer: String
    }

    private struct Constants {
        /// How many past exchanges are carried over by the providers that answer the last message only.
        static let maxContextTurns = 10
        /// Past answers are trimmed so they don't drown the actual question in the query being searched.
        static let maxContextAnswerLength = 200
    }

    private var turns: [Turn] = []

    func append(question: String, answer: String) {
        turns.append(Turn(question: question, answer: answer))
    }

    /// Appends the past exchanges and the new `question` to `messages`. When the provider doesn't support
    /// `assistant` messages the exchanges are inlined into the question instead.
    func applyHistory(
        to messages: [QuickAnswersMessage],
        question: String,
        supportsAssistantRole: Bool
    ) -> [QuickAnswersMessage] {
        guard supportsAssistantRole else {
            return messages + [QuickAnswersMessage(role: .user, content: contextualizedQuestion(question))]
        }
        let history = turns.flatMap {
            [
                QuickAnswersMessage(role: .user, content: $0.question),
                QuickAnswersMessage(role: .assistant, content: $0.answer)
            ]
        }
        return messages + history + [QuickAnswersMessage(role: .user, content: question)]
    }

    /// The question with the last exchanges inlined, so a follow up like "and tomorrow?" still carries the
    /// terms needed to search for an answer.
    private func contextualizedQuestion(_ question: String) -> String {
        let context = turns.suffix(Constants.maxContextTurns).map {
            "The user asked \"\($0.question)\" and was told \"\(trimmedAnswer($0.answer))\"."
        }
        guard !context.isEmpty else { return question }
        return (context + ["Considering that, answer: \(question)"]).joined(separator: " ")
    }

    private func trimmedAnswer(_ answer: String) -> String {
        return answer
        guard answer.count > Constants.maxContextAnswerLength else { return answer }
        let prefix = answer.prefix(Constants.maxContextAnswerLength)
        return prefix.trimmingCharacters(in: .whitespacesAndNewlines) + "\u{2026}"
    }
}
