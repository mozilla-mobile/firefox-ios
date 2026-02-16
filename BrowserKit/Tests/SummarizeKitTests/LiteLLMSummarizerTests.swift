// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SummarizeKit

final class LiteLLMSummarizerTests: XCTestCase {
    func testSummarizeNonStreamingSucceeds() async throws {
        let subject = createSubject(respondWith: ["hello", "world"])
        let result = try await subject.summarize("t")
        XCTAssertEqual(result, "hello world")
    }

    @MainActor
    func testSummarizeNonStreamingMapsRateLimited() async throws {
        let rateLimitError = LiteLLMClientError.invalidResponse(statusCode: 429)
        let subject = createSubject(respondWithError: rateLimitError)

        await assertAsyncThrows(ofType: SummarizerError.self) {
            _ = try await subject.summarize("t")
        } verify: { err in
            guard case .rateLimited = err else {
                XCTFail("Should not have been a different error")
                return
            }
            XCTAssertEqual(err.shouldRetrySummarizing, .close)
            XCTAssertEqual(err.telemetryDescription, "rateLimited")
        }
    }

    @MainActor
    func testSummarizeNonStreamingMapsInvalidResponse() async throws {
        let rateLimitError = LiteLLMClientError.invalidResponse(statusCode: 502)
        let subject = createSubject(respondWithError: rateLimitError)

        await assertAsyncThrows(ofType: SummarizerError.self) {
            _ = try await subject.summarize("t")
        } verify: { err in
            guard case .invalidResponse(let statusCode) = err else {
                XCTFail("Should not have been a different error")
                return
            }
            XCTAssertEqual(statusCode, 502)
            XCTAssertEqual(err.shouldRetrySummarizing, .retry)
            XCTAssertEqual(err.telemetryDescription, "invalidResponse(statusCode: 502)")
        }
    }

    @MainActor
    func testSummarizeNonStreamingMapsUnknownError() async throws {
        let randomError = NSError(domain: "Random error", code: 1)
        let subject = createSubject(respondWithError: randomError)

        await assertAsyncThrows(ofType: SummarizerError.self) {
            _ = try await subject.summarize("t")
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

    func testSummarizeStreamedSucceeds() async throws {
        let chunks = ["a", "b", "c"]
        let subject = createSubject(respondWith: chunks)

        var received = ""
        let stream = try await subject.summarizeStreamed("t")
        for try await chunk in stream {
            received = chunk
        }
        XCTAssertEqual(received, chunks.joined())
    }

    @MainActor
    func testSummarizeStreamedMapsRateLimited() async throws {
        let rateLimitError = LiteLLMClientError.invalidResponse(statusCode: 429)
        let subject = createSubject(respondWithError: rateLimitError)
        let stream = try await subject.summarizeStreamed("t")

        await assertAsyncThrows(ofType: SummarizerError.self) {
            for try await _ in stream { }
        } verify: { err in
            guard case .rateLimited = err else {
                XCTFail("Should not have been a different error")
                return
            }
            XCTAssertEqual(err.shouldRetrySummarizing, .close)
            XCTAssertEqual(err.telemetryDescription, "rateLimited")
        }
    }

    @MainActor
    func testSummarizeStreamedMapsInvalidResponse() async throws {
        let rateLimitError = LiteLLMClientError.invalidResponse(statusCode: 567)
        let subject = createSubject(respondWithError: rateLimitError)
        let stream = try await subject.summarizeStreamed("t")

        await assertAsyncThrows(ofType: SummarizerError.self) {
            for try await _ in stream { }
        } verify: { err in
            guard case .invalidResponse(let statusCode) = err else {
                XCTFail("Should not have been a different error")
                return
            }
            XCTAssertEqual(statusCode, 567)
            XCTAssertEqual(err.shouldRetrySummarizing, .retry)
            XCTAssertEqual(err.telemetryDescription, "invalidResponse(statusCode: 567)")
        }
    }

    @MainActor
    func testSummarizeStreamedMapsUnknownError() async throws {
        let randomError = NSError(domain: "Random error", code: 1)
        let subject = createSubject(respondWithError: randomError)
        let stream = try await subject.summarizeStreamed("t")

        await assertAsyncThrows(ofType: SummarizerError.self) {
            for try await _ in stream { }
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

    // MARK: - Helpers

    private func createSubject(
        respondWith responses: [String]? = nil,
        respondWithError error: Error? = nil
    ) -> LiteLLMSummarizer {
        let mockClient = MockLiteLLMClient()
        if let responses {
            mockClient.respondWith = responses
        }
        if let error {
            mockClient.respondWithError = error
        }
        return LiteLLMSummarizer(client: mockClient, config: SummarizerConfig(instructions: "instructions", options: [:]))
    }
}
