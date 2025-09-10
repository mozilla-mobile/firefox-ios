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

    func testSummarizeNonStreamingMapsRateLimited() async throws {
        let rateLimitError = LiteLLMClientError.invalidResponse(statusCode: 429)
        let subject = createSubject(respondWithError: rateLimitError)
        await assertSummarizeThrows(.rateLimited) {
            _ = try await subject.summarize("t")
        }
    }

    func testSummarizeNonStreamingMapsInvalidResponse() async throws {
        let rateLimitError = LiteLLMClientError.invalidResponse(statusCode: 502)
        let subject = createSubject(respondWithError: rateLimitError)
        await assertSummarizeThrows(.invalidResponse(statusCode: 502)) {
            _ = try await subject.summarize("t")
        }
    }

    func testSummarizeNonStreamingMapsUnknownError() async throws {
        let randomError = NSError(domain: "Random error", code: 1)
        let subject = createSubject(respondWithError: randomError)
        await assertSummarizeThrows(.unknown(randomError)) {
            _ = try await subject.summarize("t")
        }
    }

    func testSummarizeStreamedSucceeds() async throws {
        let chunks = ["a", "b", "c"]
        let subject = createSubject(respondWith: chunks)

        var received = ""
        let stream = subject.summarizeStreamed("t")
        for try await chunk in stream {
            received = chunk
        }
        XCTAssertEqual(received, chunks.joined())
    }

    func testSummarizeStreamedMapsRateLimited() async throws {
        let rateLimitError = LiteLLMClientError.invalidResponse(statusCode: 429)
        let subject = createSubject(respondWithError: rateLimitError)
        let stream = subject.summarizeStreamed("t")
        await assertSummarizeThrows(.rateLimited) {
            for try await _ in stream { }
        }
    }

    func testSummarizeStreamedMapsInvalidResponse() async throws {
        let rateLimitError = LiteLLMClientError.invalidResponse(statusCode: 567)
        let subject = createSubject(respondWithError: rateLimitError)
        let stream = subject.summarizeStreamed("t")
        await assertSummarizeThrows(.invalidResponse(statusCode: 567)) {
            for try await _ in stream { }
        }
    }

    func testSummarizeStreamedMapsUnknownError() async throws {
        let randomError = NSError(domain: "Random error", code: 1)
        let subject = createSubject(respondWithError: randomError)
        let stream = subject.summarizeStreamed("t")
        await assertSummarizeThrows(.unknown(randomError)) {
            for try await _ in stream { }
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
