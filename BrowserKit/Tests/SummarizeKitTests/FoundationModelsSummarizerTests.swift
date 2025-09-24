// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import SummarizeKit
import XCTest
import Common

/// We need these compile time checks so the app can be built with pre‑iOS 26 SDKs.
/// Once our BR workflow switches to 26, we can remove them,
/// as the runtime @available checks will be enough.
#if canImport(FoundationModels)
import FoundationModels
import Foundation

@available(iOS 26, *)
final class FoundationModelsSummarizerTests: XCTestCase {
    func testSummarizerRespondNonStreaming() async throws {
        let subject = createSubject(respondWith: ["hello", "world"])
        let result = try await subject.summarize("t")
        XCTAssertEqual(result, "hello world")
    }

    func testSummarizerRespondNonStreamingThrowsRateLimited() async throws {
        let rateLimitError = LanguageModelSession.GenerationError.rateLimited(.init(debugDescription: "context"))
        let subject = createSubject(respondWithError: rateLimitError)

        await assertSummarizeThrows(.rateLimited) {
            _ = try await subject.summarize("t")
        }
    }

    func testSummarizerRespondNonStreamingThrowsUnknown() async throws {
        let randomError = NSError(domain: "Random error", code: 1)
        let subject = createSubject(respondWithError: randomError)

        await assertSummarizeThrows(.unknown(randomError)) {
            _ = try await subject.summarize("t")
        }
    }

    func testSummarizerRespondStreaming() async throws {
        let expectedResponse = ["a", "b", "c"]
        let subject = createSubject(respondWith: expectedResponse)

        var receivedChunks: [String] = []
        var index = 0
        let stream = subject.summarizeStreamed("t")
        for try await chunk in  stream {
            XCTAssertEqual(
                chunk,
                expectedResponse[index],
                "chunk[\(index)] should be “\(expectedResponse[index])”"
            )
            receivedChunks.append(chunk)
            index += 1
        }

        XCTAssertEqual(receivedChunks, expectedResponse)
    }

    func testSummarizerRespondStreamingThrowsGuardViolation() async throws {
        let guardViolationError = LanguageModelSession.GenerationError.guardrailViolation(.init(debugDescription: "context"))
        let subject = createSubject(respondWithError: guardViolationError)
        let stream = subject.summarizeStreamed("t")

        await assertSummarizeThrows(.safetyBlocked) {
            // Consume the stream but do nothing
            for try await _ in stream { }
        }
    }

    func testSummarizerRespondStreamingThrowsUnknown() async throws {
        let randomError = NSError(domain: "Random error", code: 1)
        let subject = createSubject(respondWithError: randomError)
        let stream = subject.summarizeStreamed("t")

        await assertSummarizeThrows(.unknown(randomError)) {
            // Consume the stream but do nothing
            for try await _ in stream { }
        }
    }

    private func createSubject(
        respondWith responses: [String]? = nil,
        respondWithError error: Error? = nil
    ) -> FoundationModelsSummarizer {
        let mockSession = MockLanguageModelSession()
        if let responses {
            mockSession.respondWith = responses
        }
        if let error {
            mockSession.respondWithError = error
        }
        return FoundationModelsSummarizer(
            makeSession: { _ in mockSession },
            config: SummarizerConfig(instructions: "instructions", options: [:])
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

#endif
