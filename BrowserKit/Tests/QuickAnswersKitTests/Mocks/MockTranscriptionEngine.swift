// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit

// MARK: - Test Errors
enum TestError: Error, Equatable {
    case prepareFailed
    case startFailed
    case stopFailed
}

// MARK: - Mock Engine

final class MockTranscriptionEngine: TranscriptionEngine, @unchecked Sendable {
    var prepareCallCount = 0
    var startCallCount = 0
    var stopCallCount = 0

    var prepareError: Error?
    var startError: Error?
    var stopError: Error?

    /// Used to emit results when calling engine `start`.
    var resultsToYield: [SpeechResult] = []
    var finishAfterYielding = true

    func prepare() async throws {
        prepareCallCount += 1
        if let prepareError { throw prepareError }
    }

    func start(
        continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation
    ) async throws {
        startCallCount += 1

        if let startError { throw startError }

        for r in resultsToYield {
            continuation.yield(r)
        }

        if finishAfterYielding {
            continuation.finish()
        }
    }

    func stop() async throws {
        stopCallCount += 1
        if let stopError { throw stopError }
    }
}
