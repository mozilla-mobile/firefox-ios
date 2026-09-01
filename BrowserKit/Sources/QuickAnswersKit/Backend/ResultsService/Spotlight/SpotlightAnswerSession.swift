// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A page from the Spotlight index the on-device model looked at while answering.
struct SpotlightAnswerSource: Equatable, Sendable {
    let title: String
    let url: URL
}

struct SpotlightAnswer: Equatable, Sendable {
    let text: String
    let sources: [SpotlightAnswerSource]

    static func empty() -> Self {
        return SpotlightAnswer(text: "", sources: [])
    }
}

/// Answers a question with the on-device language model, which searches the Spotlight index for the items the app
/// indexed, meaning the open tabs and the bookmarks.
///
/// Implementations map platform failures to `ResultsServiceError` so that `SpotlightResultsService` doesn't have to
/// be gated on the availability of the model APIs.
protocol SpotlightAnswerSession: Sendable {
    func answer(question: String, instructions: String) async throws -> SpotlightAnswer

    /// Whether the question is about the pages the user has in the browser, meaning the Spotlight index is the right
    /// place to answer it from. Implementations answer `true` when the check itself fails, so that a hiccup in the
    /// classification never diverts a question away from the on-device path.
    func isAboutBrowserItems(question: String) async -> Bool
}
