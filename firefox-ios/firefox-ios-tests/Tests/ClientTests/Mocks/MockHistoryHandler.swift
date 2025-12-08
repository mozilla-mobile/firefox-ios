// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

final class MockHistoryHandler: HistoryHandler {
    var applied: [VisitObservation] = []
    var applyObservationCallCount = 0
    var nextResult: Result<Void, Error> = .success(())
    var onApply: (() -> Void)?

    // MARK: History Metadata
    var getMostRecentSearchHistoryMetadataCallCount = 0
    var noteHistoryMetadataCallCount = 0
    var deleteSearchHistoryMetadataCallCount = 0
    var result: Result<[MozillaAppServices.HistoryMetadata], Error> = .success(
        [
            HistoryMetadata(
                url: "https://example.com",
                title: nil,
                previewImageUrl: nil,
                createdAt: 1,
                updatedAt: 1,
                totalViewTime: 1,
                searchTerm: "search term 1",
                documentType: .regular,
                referrerUrl: nil
            ),
            HistoryMetadata(
                url: "https://example.com",
                title: nil,
                previewImageUrl: nil,
                createdAt: 2,
                updatedAt: 2,
                totalViewTime: 2,
                searchTerm: "search term 2",
                documentType: .regular,
                referrerUrl: nil
            )
        ]
    )
    let clearResult: Result<(), Error>
    var searchTermList: [String] = []

    init(clearResult: Result<(), Error> = .success(())) {
        self.clearResult = clearResult
    }

    func applyObservation(visitObservation: VisitObservation, completion: (Result<Void, any Error>) -> Void) {
        applyObservationCallCount += 1
        applied.append(visitObservation)
        completion(nextResult)
        onApply?()
    }

    func getMostRecentSearchHistoryMetadata(
        limit: Int32,
        completion: @escaping @Sendable (Result<[MozillaAppServices.HistoryMetadata], any Error>) -> Void
    ) {
        getMostRecentSearchHistoryMetadataCallCount += 1
        completion(result)
    }

    func noteHistoryMetadata(
        for searchTerm: String,
        and urlString: String,
        completion: @escaping @Sendable (Result<(), any Error>) -> Void
    ) {
        noteHistoryMetadataCallCount += 1
        searchTermList.append(searchTerm)
    }

    func deleteSearchHistoryMetadata(completion: @escaping @Sendable (Result<(), any Error>) -> Void) {
        deleteSearchHistoryMetadataCallCount += 1
        completion(clearResult)
    }
}
