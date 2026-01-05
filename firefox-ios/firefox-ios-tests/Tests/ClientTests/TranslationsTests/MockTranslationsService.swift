// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import Common

/// Test helper that simulates the translations service.
final class MockTranslationsService: TranslationsServiceProtocol {
    // MARK: - Results
    private let shouldOfferTranslationResult: Result<Bool, Error>
    private let translateResult: Result<Void, Error>
    private let firstResponseReceivedResult: Result<Void, Error>
    private let discardResult: Result<Void, Error>

    // MARK: - Init
    init(
        shouldOfferTranslationResult: Result<Bool, Error> = .success(false),
        translateResult: Result<Void, Error> = .success(()),
        firstResponseReceivedResult: Result<Void, Error> = .success(()),
        discardResult: Result<Void, Error> = .success(())
    ) {
        self.shouldOfferTranslationResult = shouldOfferTranslationResult
        self.translateResult = translateResult
        self.firstResponseReceivedResult = firstResponseReceivedResult
        self.discardResult = discardResult
    }

    // MARK: - TranslationsServiceProtocol
    func shouldOfferTranslation(for windowUUID: WindowUUID) async throws -> Bool {
        return try shouldOfferTranslationResult.get()
    }

    func translateCurrentPage(
        for windowUUID: WindowUUID,
        onLanguageIdentified: ((String, String) -> Void)?
    ) async throws {
        try translateResult.get()
        onLanguageIdentified?("en", "de")
    }

    func firstResponseReceived(for windowUUID: WindowUUID) async throws {
        try firstResponseReceivedResult.get()
    }

    func discardTranslations(for windowUUID: WindowUUID) async throws {
        try discardResult.get()
    }
}
