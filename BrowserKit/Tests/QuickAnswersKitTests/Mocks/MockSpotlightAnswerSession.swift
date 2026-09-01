// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit

final class MockSpotlightAnswerSession: SpotlightAnswerSession, @unchecked Sendable {
    var answerToReturn: SpotlightAnswer = .empty()
    var errorToThrow: Error?
    var isAboutBrowserItemsToReturn = true
    var answerCallCount = 0
    var isAboutBrowserItemsCallCount = 0
    var lastQuestion: String?
    var lastInstructions: String?
    var lastClassifiedQuestion: String?

    func answer(question: String, instructions: String) async throws -> SpotlightAnswer {
        answerCallCount += 1
        lastQuestion = question
        lastInstructions = instructions

        if let errorToThrow {
            throw errorToThrow
        }
        return answerToReturn
    }

    func isAboutBrowserItems(question: String) async -> Bool {
        isAboutBrowserItemsCallCount += 1
        lastClassifiedQuestion = question

        return isAboutBrowserItemsToReturn
    }
}
