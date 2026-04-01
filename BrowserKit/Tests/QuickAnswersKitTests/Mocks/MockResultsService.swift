// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit

final class MockResultsService: ResultsService, @unchecked Sendable {
    var fetchResultsCallCount = 0
    var lastTranscription: String?
    var resultToReturn: SearchResult = .empty()
    var errorToThrow: Error?

    func fetchResults(for transcription: String) async throws -> SearchResult {
        fetchResultsCallCount += 1
        lastTranscription = transcription

        if let error = errorToThrow {
            throw error
        }

        return resultToReturn
    }
}
