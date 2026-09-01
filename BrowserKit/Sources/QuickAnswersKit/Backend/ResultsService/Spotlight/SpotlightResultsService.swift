// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A `ResultsService` that answers from the items the app indexed in Spotlight, the open tabs and the bookmarks,
/// running entirely on device instead of sending the question to a remote provider.
final class SpotlightResultsService: ResultsService {
    private struct Constants {
        static let maxSourcesCount = 2
    }

    private let session: SpotlightAnswerSession
    private let configFetcher: QuickAnswersConfigFetcher
    private let fallbackService: ResultsService?

    /// - Parameter fallbackService: answers the questions that aren't about the pages the user has in the browser,
    /// which the Spotlight index has nothing to say about. When nil every question is answered on device.
    init(
        session: SpotlightAnswerSession,
        configFetcher: QuickAnswersConfigFetcher,
        fallbackService: ResultsService? = nil
    ) {
        self.session = session
        self.configFetcher = configFetcher
        self.fallbackService = fallbackService
    }

    func fetchResults(for transcription: String) async throws -> SearchResult {
        if let result = try await fallbackResult(for: transcription) { return result }

        do {
            let config = try await configFetcher.fetch()
            let answer = try await session.answer(question: transcription, instructions: config.instructions)
            let text = answer.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw ResultsServiceError.noMessage }

            return SearchResult(resultText: text, sources: sources(from: answer))
        } catch {
            throw (error as? ResultsServiceError) ?? ResultsServiceError.unknown(error.localizedDescription)
        }
    }

    /// The remote answer for a question that isn't about the user's own pages, or nil when the on-device path is the
    /// one that should answer it.
    private func fallbackResult(for transcription: String) async throws -> SearchResult? {
        guard let fallbackService else { return nil }

        let isAboutBrowserItems = await session.isAboutBrowserItems(question: transcription)
        guard !isAboutBrowserItems else { return nil }

        return try await fallbackService.fetchResults(for: transcription)
    }

    /// Thumbnail and favicon are left out: the source view falls back to the page url for both.
    private func sources(from answer: SpotlightAnswer) -> [SearchResult.Source] {
        return answer.sources.prefix(Constants.maxSourcesCount).map { source in
            SearchResult.Source(title: source.title, url: source.url, thumbnailURL: nil, faviconURL: nil)
        }
    }
}
