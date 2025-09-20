// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import SummarizeKit
import XCTest

final class SummarizerServiceTests: XCTestCase {
    static let mockResponse = ["Summarized", "content"]
    static let maxWords = 100
    static let maxWordCount = 50
    var mockWebView = MockWebView(URL(string: "https://foo.com")!)

    func testSummarizerServiceReturnsSummary() async throws {
        let subject = createSubject()
        let result = try await subject.summarize(from: mockWebView)
        XCTAssertEqual(result, "Summarized content")
    }

    func testSummarizerServiceThrowsWhenContentTooLong() async {
        let checker = MockSummarizationChecker(
            canSummarize: false,
            reason: .contentTooLong,
            wordCount: Self.maxWordCount,
            textContent: nil
        )

        let subject = createSubject(checker: checker)

        await assertSummarizeThrows(.tooLong) {
            _ = try await subject.summarize(from: self.mockWebView)
        }
    }

    func testSummarizerServiceReturnsStreamedSummary() async throws {
        let subject = createSubject()
        var streamedChunks: [String] = []

        for try await chunk in subject.summarizeStreamed(from: mockWebView) {
            streamedChunks.append(chunk)
        }

        XCTAssertEqual(streamedChunks, ["Summarized", "content"] )
    }

    func testSummarizerServiceThrowsWhenSummarizerFails() async {
        let summarizer = MockSummarizer(
            shouldRespond: [],
            shouldThrowError: SummarizerError.safetyBlocked
        )
        let subject = createSubject(summarizer: summarizer)

        await assertSummarizeThrows(.safetyBlocked) {
            for try await _ in subject.summarizeStreamed(from: self.mockWebView) { }
        }
    }

    func testRandomErrorBecomesUnknownSummarizerError() async {
        let randomError = NSError(domain: "Random error", code: 1)

        let summarizer = MockSummarizer(
            shouldRespond: [],
            shouldThrowError: randomError
        )

        let subject = createSubject(summarizer: summarizer)

        await assertSummarizeThrows(.unknown(randomError)) {
            _ = try await subject.summarize(from: self.mockWebView)
        }
    }

    private func createSubject(
        checker: MockSummarizationChecker = .init(
            canSummarize: true,
            reason: nil,
            wordCount: maxWordCount,
            textContent: "This is test content"
        ),
        summarizer: MockSummarizer = .init(
            shouldRespond: mockResponse,
            shouldThrowError: nil
        ),
        maxWords: Int = maxWords
    ) -> DefaultSummarizerService {
        DefaultSummarizerService(
            summarizer: summarizer,
            lifecycleDelegate: nil,
            checker: checker,
            maxWords: maxWords
        )
    }

    /// Convenience method to simplify error checking in the test cases
    private func assertSummarizeThrows(
        _ expected: SummarizerError,
        when running: @escaping () async throws -> Void
    ) async {
        do {
            try await running()
            XCTFail("Expected summarize to throw, but it returned normally")
        } catch let error as SummarizerError {
            if error != expected {
                XCTFail("Expected \(expected) to be thrown, but got \(error) instead")
            }
        } catch {
            XCTFail("Expected SummarizerError, but got non SummarizerError: \(error)")
        }
    }
}
