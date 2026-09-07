// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit

final class MockResultsService: ResultsService, @unchecked Sendable {
    var fetchResultsCallCount = 0
    var resultsToYield: [SearchResult] = [.empty()]
    var errorToThrow: Error?

    func fetchResults(for transcription: String) -> AsyncThrowingStream<SearchResult, Error> {
        fetchResultsCallCount += 1
        return AsyncThrowingStream { continuation in
            if let errorToThrow {
                continuation.finish(throwing: errorToThrow)
                return
            }
            for result in resultsToYield {
                continuation.yield(result)
            }
            continuation.finish()
        }
    }
}
