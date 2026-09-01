// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Testing

@testable import QuickAnswersKit

struct SpotlightResultsServiceTests {
    private let swiftURL = URL(string: "https://example.com/swift") ?? URL(fileURLWithPath: "/")

    @Test
    func test_fetchResults_returnsAnswerAndSources() async throws {
        let session = MockSpotlightAnswerSession()
        session.answerToReturn = SpotlightAnswer(
            text: "You bookmarked the Swift concurrency guide.",
            sources: [source(title: "Swift concurrency", url: swiftURL)]
        )
        let subject = createSubject(session: session)

        let result = try await subject.fetchResults(for: "Which page did I bookmark about concurrency?")

        #expect(result.resultText == "You bookmarked the Swift concurrency guide.")
        #expect(result.sources.count == 1)
        #expect(result.sources.first?.title == "Swift concurrency")
        #expect(result.sources.first?.url == swiftURL)
        #expect(session.answerCallCount == 1)
    }

    @Test
    func test_fetchResults_passesQuestionAndConfigInstructionsToSession() async throws {
        let session = MockSpotlightAnswerSession()
        session.answerToReturn = SpotlightAnswer(text: "Answer", sources: [])
        let instructions = "Search the index before answering."
        let configFetcher = MockQuickAnswersConfigFetcher(
            configToReturn: QuickAnswersConfig(model: .spotlight, instructions: instructions)
        )
        let subject = createSubject(session: session, configFetcher: configFetcher)

        _ = try await subject.fetchResults(for: "What are my open tabs about?")

        #expect(session.lastQuestion == "What are my open tabs about?")
        #expect(session.lastInstructions == instructions)
        #expect(configFetcher.fetchCallCount == 1)
    }

    @Test
    func test_fetchResults_limitsSourcesToTwo() async throws {
        let session = MockSpotlightAnswerSession()
        session.answerToReturn = SpotlightAnswer(
            text: "Answer",
            sources: [
                source(title: "First", url: URL(fileURLWithPath: "/1")),
                source(title: "Second", url: URL(fileURLWithPath: "/2")),
                source(title: "Third", url: URL(fileURLWithPath: "/3"))
            ]
        )
        let subject = createSubject(session: session)

        let result = try await subject.fetchResults(for: "Question")

        #expect(result.sources.count == 2)
        #expect(result.sources.map { $0.title } == ["First", "Second"])
    }

    @Test
    func test_fetchResults_withBlankAnswer_throwsNoMessage() async throws {
        let session = MockSpotlightAnswerSession()
        session.answerToReturn = SpotlightAnswer(text: "  \n ", sources: [])
        let subject = createSubject(session: session)

        await #expect(throws: ResultsServiceError.noMessage) {
            try await subject.fetchResults(for: "Question")
        }
    }

    @Test
    func test_fetchResults_whenSessionThrowsServiceError_rethrowsIt() async throws {
        let session = MockSpotlightAnswerSession()
        session.errorToThrow = ResultsServiceError.modelUnavailable
        let subject = createSubject(session: session)

        await #expect(throws: ResultsServiceError.modelUnavailable) {
            try await subject.fetchResults(for: "Question")
        }
    }

    @Test
    func test_fetchResults_whenSessionThrowsOtherError_mapsToUnknown() async throws {
        let session = MockSpotlightAnswerSession()
        session.errorToThrow = TestError.any
        let subject = createSubject(session: session)

        let error = await #expect(throws: ResultsServiceError.self) {
            try await subject.fetchResults(for: "Question")
        }
        #expect(error?.telemetryLabel == "unknown")
    }

    @Test
    func test_fetchResults_whenQuestionIsNotAboutBrowserItems_answersWithFallback() async throws {
        let session = MockSpotlightAnswerSession()
        session.isAboutBrowserItemsToReturn = false
        let fallbackService = MockResultsService()
        fallbackService.resultToReturn = SearchResult(resultText: "Paris.", sources: [])
        let subject = createSubject(session: session, fallbackService: fallbackService)

        let result = try await subject.fetchResults(for: "What is the capital of France?")

        #expect(result.resultText == "Paris.")
        #expect(fallbackService.fetchResultsCallCount == 1)
        #expect(fallbackService.lastTranscription == "What is the capital of France?")
        #expect(session.answerCallCount == 0, "Spotlight should be skipped for a question about the world")
    }

    @Test
    func test_fetchResults_whenQuestionIsAboutBrowserItems_answersOnDevice() async throws {
        let session = MockSpotlightAnswerSession()
        session.isAboutBrowserItemsToReturn = true
        session.answerToReturn = SpotlightAnswer(text: "You have 3 tabs open.", sources: [])
        let fallbackService = MockResultsService()
        let subject = createSubject(session: session, fallbackService: fallbackService)

        let result = try await subject.fetchResults(for: "How many tabs do I have open?")

        #expect(result.resultText == "You have 3 tabs open.")
        #expect(session.answerCallCount == 1)
        #expect(session.lastClassifiedQuestion == "How many tabs do I have open?")
        #expect(fallbackService.fetchResultsCallCount == 0, "Fallback should be left alone")
    }

    @Test
    func test_fetchResults_whenFallbackThrows_propagatesItsError() async throws {
        let session = MockSpotlightAnswerSession()
        session.isAboutBrowserItemsToReturn = false
        let fallbackService = MockResultsService()
        fallbackService.errorToThrow = ResultsServiceError.rateLimited
        let subject = createSubject(session: session, fallbackService: fallbackService)

        await #expect(throws: ResultsServiceError.rateLimited) {
            try await subject.fetchResults(for: "How tall is the Eiffel tower?")
        }
    }

    @Test
    func test_fetchResults_withoutFallback_skipsClassificationAndAnswersOnDevice() async throws {
        let session = MockSpotlightAnswerSession()
        session.isAboutBrowserItemsToReturn = false
        session.answerToReturn = SpotlightAnswer(text: "Answer", sources: [])
        let subject = createSubject(session: session)

        let result = try await subject.fetchResults(for: "What is the capital of France?")

        #expect(result.resultText == "Answer")
        #expect(session.answerCallCount == 1)
        #expect(session.isAboutBrowserItemsCallCount == 0, "Nothing to route to, so nothing to classify")
    }

    // MARK: - Helpers
    private enum TestError: Error {
        case any
    }

    private func source(title: String, url: URL) -> SpotlightAnswerSource {
        return SpotlightAnswerSource(title: title, url: url)
    }

    private func createSubject(
        session: SpotlightAnswerSession = MockSpotlightAnswerSession(),
        configFetcher: QuickAnswersConfigFetcher = MockQuickAnswersConfigFetcher(),
        fallbackService: ResultsService? = nil
    ) -> SpotlightResultsService {
        return SpotlightResultsService(
            session: session,
            configFetcher: configFetcher,
            fallbackService: fallbackService
        )
    }
}
