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
    private let detectPageLanguageResult: Result<String, Error>

    // MARK: - Call records
    var shouldOfferTranslationCallCount = 0

    /// Parks `firstResponseReceived` until `releaseFirstResponse()` is called.
    private var firstResponseGate: CheckedContinuation<Void, Never>?
    private let gatesFirstResponse: Bool

    // MARK: - Init
    init(
        shouldOfferTranslationResult: Result<Bool, Error> = .success(false),
        translateResult: Result<Void, Error> = .success(()),
        firstResponseReceivedResult: Result<Void, Error> = .success(()),
        detectPageLanguageResult: Result<String, Error> = .success("en"),
        gatesFirstResponse: Bool = false
    ) {
        self.shouldOfferTranslationResult = shouldOfferTranslationResult
        self.translateResult = translateResult
        self.firstResponseReceivedResult = firstResponseReceivedResult
        self.detectPageLanguageResult = detectPageLanguageResult
        self.gatesFirstResponse = gatesFirstResponse
    }

    func releaseFirstResponse() {
        firstResponseGate?.resume()
        firstResponseGate = nil
    }

    // MARK: - TranslationsServiceProtocol
    func shouldOfferTranslation(for windowUUID: WindowUUID, using preferredLanguages: [String]) async throws -> Bool {
        shouldOfferTranslationCallCount += 1
        return try shouldOfferTranslationResult.get()
    }

    func translateCurrentPage(
        for windowUUID: WindowUUID,
        from sourceLanguage: String? = nil,
        to targetLanguage: String,
        onLanguageIdentified: ((String, String) -> Void)?
    ) async throws {
        // Production identifies the language before it can fail, so a thrown error must not
        // swallow the callback — that is what emits `translationRequested` telemetry.
        onLanguageIdentified?(sourceLanguage ?? "en", targetLanguage)
        try translateResult.get()
    }

    func firstResponseReceived(for windowUUID: WindowUUID) async throws {
        if gatesFirstResponse {
            await withCheckedContinuation { continuation in
                firstResponseGate = continuation
            }
        }
        try firstResponseReceivedResult.get()
    }

    func fetchSupportedTargetLanguages() async -> [String] {
        return []
    }

    func detectPageLanguage(for windowUUID: WindowUUID) async throws -> String {
        return try detectPageLanguageResult.get()
    }
}
