// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import Common

/// Test helper that simulates the translations service.
final class MockTranslationsService: TranslationsServiceProtocol {
    private let shouldOfferTranslationResult: Bool
    private let shouldOfferTranslationError: Error?

    private let translateError: Error?

    private let firstResponseReceivedResult: Bool
    private let firstResponseReceivedError: Error?

    private let discardError: Error?

    private(set) var shouldOfferTranslationCalledWith: WindowUUID?
    private(set) var translateCalledWith: WindowUUID?
    private(set) var firstResponseReceivedCalledWith: WindowUUID?
    private(set) var discardCalledWith: WindowUUID?

    init(
        shouldOfferTranslationResult: Bool = false,
        shouldOfferTranslationError: Error? = nil,
        translateError: Error? = nil,
        firstResponseReceivedResult: Bool = true,
        firstResponseReceivedError: Error? = nil,
        discardError: Error? = nil
    ) {
        self.shouldOfferTranslationResult = shouldOfferTranslationResult
        self.shouldOfferTranslationError = shouldOfferTranslationError
        self.translateError = translateError
        self.firstResponseReceivedResult = firstResponseReceivedResult
        self.firstResponseReceivedError = firstResponseReceivedError
        self.discardError = discardError
    }

    func shouldOfferTranslation(for windowUUID: WindowUUID) async throws -> Bool {
        shouldOfferTranslationCalledWith = windowUUID
        if let error = shouldOfferTranslationError { throw error }
        return shouldOfferTranslationResult
    }

    func translateCurrentPage(
        for windowUUID: WindowUUID,
        onLanguageIdentified: ((String, String) -> Void)?
    ) async throws {
        translateCalledWith = windowUUID
        if let error = translateError { throw error }
    }

    func firstResponseReceived(for windowUUID: WindowUUID) async throws {
        firstResponseReceivedCalledWith = windowUUID
        if let error = firstResponseReceivedError { throw error }
    }

    func discardTranslations(for windowUUID: WindowUUID) async throws {
        discardCalledWith = windowUUID
        if let error = discardError { throw error }
    }
}
