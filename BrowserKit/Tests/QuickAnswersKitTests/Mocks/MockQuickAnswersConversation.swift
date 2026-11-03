// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
@testable import QuickAnswersKit

final class MockQuickAnswersConversation: QuickAnswersConversation, @unchecked Sendable {
    var messagesToReturn: [QuickAnswersMessage]?
    var appendCallCount = 0
    var lastAppendedQuestion: String?
    var lastAppendedAnswer: String?
    var applyHistoryCallCount = 0
    var lastAppliedMessages: [QuickAnswersMessage]?
    var lastAppliedQuestion: String?
    var lastSupportsAssistantRole: Bool?

    func append(question: String, answer: String) async {
        appendCallCount += 1
        lastAppendedQuestion = question
        lastAppendedAnswer = answer
    }

    func applyHistory(
        to messages: [QuickAnswersMessage],
        question: String,
        supportsAssistantRole: Bool
    ) async -> [QuickAnswersMessage] {
        applyHistoryCallCount += 1
        lastAppliedMessages = messages
        lastAppliedQuestion = question
        lastSupportsAssistantRole = supportsAssistantRole
        return messagesToReturn ?? messages + [QuickAnswersMessage(role: .user, content: question)]
    }
}
