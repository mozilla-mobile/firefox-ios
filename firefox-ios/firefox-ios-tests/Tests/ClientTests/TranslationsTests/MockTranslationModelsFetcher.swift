// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import XCTest

/// Minimal mock  for TranslationModelsFetcherProtocol tests. This avoids going through remote settings.
final class MockTranslationModelsFetcher: TranslationModelsFetcherProtocol, @unchecked Sendable {
    var resetStorageWasCalledExpectation: XCTestExpectation?
    var resetStorageWasCalled = false
    var translatorWASMResult: Data?
    var modelsResult: Data?
    var modelBufferResult: Data?
    var supportedTargetLanguages: [String] = []
    var fetchModelsHandler: ((String, String) -> Data?)?

    func fetchTranslatorWASM() -> Data? {
        return translatorWASMResult
    }

    func fetchModels(from sourceLang: String, to targetLang: String) -> Data? {
        return fetchModelsHandler?(sourceLang, targetLang) ?? modelsResult
    }

    func fetchModelBuffer(recordId: String) -> Data? {
        return modelBufferResult
    }

    func prewarmResources(for sourceLang: String, to targetLang: String) {
        // no-op for now
    }

    func fetchSupportedTargetLanguages() async -> [String] {
        return supportedTargetLanguages
    }

    func resetStorage() async {
        resetStorageWasCalledExpectation?.fulfill()
        resetStorageWasCalled = true
    }
}
