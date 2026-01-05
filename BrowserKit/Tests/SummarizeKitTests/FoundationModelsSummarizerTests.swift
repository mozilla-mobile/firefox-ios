// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import SummarizeKit
import XCTest
import Common

/// These compile-time checks ensure the app can still be built with pre–iOS 26 SDKs.
/// The `@available` attribute only guards *runtime execution*; it doesn’t prevent XCTest
/// from compiling or discovering the test class. As a result, tests would still be run
/// (and crash) on lower iOS versions.
///
/// To avoid that, we moved the runtime check into `setUpWithError()` using
/// `guard #available(iOS 26, *)` to skip all tests on unsupported OS versions.
/// The `@available(iOS 26, *)` annotation is now applied only to individual test
/// methods where needed, so the compiler can validate iOS 26-only APIs without
/// blocking the entire class on older SDKs.
#if canImport(FoundationModels)
import FoundationModels
import Foundation

final class FoundationModelsSummarizerTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()

        // Skip the entire test run if device < iOS 26
        guard #available(iOS 26, *) else {
            throw XCTSkip("Skipping iOS 26-only tests on earlier OS versions")
        }
    }

    @available(iOS 26, *)
    func testSummarizerRespondNonStreaming() async throws {
        let subject = createSubject(respondWith: ["hello", "world"])
        let result = try await subject.summarize("t")
        XCTAssertEqual(result, "hello world")
    }

    @MainActor
    @available(iOS 26, *)
    func testSummarizerRespondNonStreamingThrowsRateLimited() async throws {
        let rateLimitError = LanguageModelSession.GenerationError.rateLimited(.init(debugDescription: "context"))
        let subject = createSubject(respondWithError: rateLimitError)

        await assertAsyncThrows(ofType: SummarizerError.self) {
            // Consume the stream but do nothing
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
    @available(iOS 26, *)
    func testSummarizerRespondNonStreamingThrowsUnknown() async throws {
        let randomError = NSError(domain: "Random error", code: 1)
        let subject = createSubject(respondWithError: randomError)

        await assertAsyncThrows(ofType: SummarizerError.self) {
            // Consume the stream but do nothing
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

    @available(iOS 26, *)
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

    @MainActor
    @available(iOS 26, *)
    func testSummarizerRespondStreamingThrowsGuardViolation() async throws {
        let guardViolationError = LanguageModelSession.GenerationError.guardrailViolation(.init(debugDescription: "context"))
        let subject = createSubject(respondWithError: guardViolationError)
        let stream = subject.summarizeStreamed("t")

        await assertAsyncThrows(ofType: SummarizerError.self) {
            // Consume the stream but do nothing
            for try await _ in stream { }
        } verify: { err in
            guard case .safetyBlocked = err else {
                XCTFail("Should not have been a different error")
                return
            }
            XCTAssertEqual(err.shouldRetrySummarizing, .close)
            XCTAssertEqual(err.telemetryDescription, "safetyBlocked")
        }
    }

    @MainActor
    @available(iOS 26, *)
    func testSummarizerRespondStreamingThrowsUnknown() async throws {
        let randomError = NSError(domain: "Random error", code: 1)
        let subject = createSubject(respondWithError: randomError)
        let stream = subject.summarizeStreamed("t")

        await assertAsyncThrows(ofType: SummarizerError.self) {
            // Consume the stream but do nothing
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

    @available(iOS 26, *)
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
}
#endif
