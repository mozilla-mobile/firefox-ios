// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import SummarizeKit
import XCTest
import Common

@MainActor
final class SummarizerServiceTests: XCTestCase {
    static let mockResponse = ["Summarized", "content"]
    static let maxWords = 100
    static let maxWordCount = 50
    private var mockWebView: MockWebView!

    override func setUp() async throws {
        try await super.setUp()
        mockWebView = MockWebView(URL(string: "https://foo.com")!)
    }

    override func tearDown() async throws {
        mockWebView = nil
        try await super.tearDown()
    }

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

        await assertAsyncThrows(ofType: SummarizerError.self) {
            _ = try await subject.summarize(from: self.mockWebView)
        } verify: { err in
            guard case .tooLong = err else {
                XCTFail("Should not have been a different error")
                return
            }
            XCTAssertEqual(err.shouldRetrySummarizing, .close)
            XCTAssertEqual(err.telemetryDescription, "tooLong")
        }
    }

    @MainActor
    func testSummarizerServiceReturnsStreamedSummary() async throws {
        let subject = createSubject()
        var streamedChunks: [String] = []

        for try await chunk in subject.summarizeStreamed(from: mockWebView) {
            streamedChunks.append(chunk)
        }

        XCTAssertEqual(streamedChunks, ["Summarized", "content"] )
    }

    @MainActor
    func testSummarizerServiceThrowsWhenSummarizerFails() async {
        let summarizer = MockSummarizer(
            shouldRespond: [],
            shouldThrowError: SummarizerError.safetyBlocked
        )
        let subject = createSubject(summarizer: summarizer)

        await assertAsyncThrows(ofType: SummarizerError.self) {
            for try await _ in subject.summarizeStreamed(from: self.mockWebView) { }
        } verify: { err in
            guard case .safetyBlocked = err else {
                XCTFail("Should not have been a different error")
                return
            }
            XCTAssertEqual(err.shouldRetrySummarizing, .close)
            XCTAssertEqual(err.telemetryDescription, "safetyBlocked")
        }
    }

    func testRandomErrorBecomesUnknownSummarizerError() async {
        let randomError = NSError(domain: "Random error", code: 1)

        let summarizer = MockSummarizer(
            shouldRespond: [],
            shouldThrowError: randomError
        )

        let subject = createSubject(summarizer: summarizer)

        await assertAsyncThrows(ofType: SummarizerError.self) {
            _ = try await subject.summarize(from: self.mockWebView)
        } verify: { err in
            guard case .unknown(let randomError) = err else {
                XCTFail("Should not have been a different error")
                return
            }
            XCTAssertEqual(randomError.localizedDescription, "The operation couldn’t be completed. (Random error error 1.)")
            XCTAssertEqual(err.shouldRetrySummarizing, .close)
            XCTAssertEqual(err.telemetryDescription, "unknown(domain: Random error, code: 1)")
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
}
