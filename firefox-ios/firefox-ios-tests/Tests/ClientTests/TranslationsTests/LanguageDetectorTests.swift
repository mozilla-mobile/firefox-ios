// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class LanguageDetectorTests: XCTestCase {
    var mockLanguageSampleSource = MockLanguageSampleSource()
    var mockRecognizer = MockLanguageRecognizer()

    // MARK: - Signal reconciliation

    func test_detectLanguage_whenTextIsConfident_overridesHTMLTag() async throws {
        mockLanguageSampleSource.htmlLangResult = "de"
        mockLanguageSampleSource.mockResult = "sample text"
        mockRecognizer.result = (languageCode: "en", confidence: 0.95)
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "en")
    }

    func test_detectLanguage_whenTextIsConfidentAndHTMLLangMissing_returnsText() async throws {
        mockLanguageSampleSource.htmlLangResult = nil
        mockLanguageSampleSource.mockResult = "sample text"
        mockRecognizer.result = (languageCode: "fr", confidence: 0.92)
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "fr")
    }

    func test_detectLanguage_whenTextIsNotConfident_fallsBackToHTMLTag() async throws {
        mockLanguageSampleSource.htmlLangResult = "es"
        mockLanguageSampleSource.mockResult = "sample text"
        mockRecognizer.result = (languageCode: "en", confidence: 0.40)
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "es")
    }

    func test_detectLanguage_whenTextIsNotConfidentAndHTMLLangMissing_returnsNil() async throws {
        mockLanguageSampleSource.htmlLangResult = nil
        mockLanguageSampleSource.mockResult = "sample text"
        mockRecognizer.result = (languageCode: "en", confidence: 0.40)
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    func test_detectLanguage_whenRecognizerReturnsNil_fallsBackToHTMLTag() async throws {
        mockLanguageSampleSource.htmlLangResult = "es"
        mockLanguageSampleSource.mockResult = "sample text"
        mockRecognizer.result = nil
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "es")
    }

    func test_detectLanguage_whenOnlyHTMLLangAvailable_returnsHTMLLang() async throws {
        mockLanguageSampleSource.htmlLangResult = "es"
        mockLanguageSampleSource.mockResult = nil
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "es")
    }

    // MARK: - Confidence threshold

    func test_detectLanguage_acceptsConfidenceAtThreshold() async throws {
        mockLanguageSampleSource.mockResult = "sample text"
        mockRecognizer.result = (languageCode: "en", confidence: 0.85)
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "en")
    }

    func test_detectLanguage_rejectsConfidenceBelowThreshold() async throws {
        mockLanguageSampleSource.mockResult = "sample text"
        mockRecognizer.result = (languageCode: "en", confidence: 0.84)
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    // MARK: - HTML lang attribute

    func test_detectLanguage_normalizesUppercaseHTMLLang() async throws {
        mockLanguageSampleSource.htmlLangResult = "EN-US"
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "en")
    }

    func test_detectLanguage_ignoresEmptyHTMLLang() async throws {
        mockLanguageSampleSource.htmlLangResult = ""
        mockLanguageSampleSource.mockResult = "sample text"
        mockRecognizer.result = (languageCode: "fr", confidence: 0.95)
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "fr")
    }

    // MARK: - Sample handling

    func test_detectLanguage_withEmptyString_returnsNil() async throws {
        mockLanguageSampleSource.mockResult = ""
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    func test_detectLanguage_withWhitespaces_returnsNil() async throws {
        mockLanguageSampleSource.mockResult = " \n\t "
        mockRecognizer.result = (languageCode: "en", confidence: 0.99)
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    func test_detectLanguage_returnsNilForNonString() async throws {
        mockLanguageSampleSource.mockResult = 42
        let result = try await createSubject().detectLanguage(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    func test_detectLanguage_propagatesError() async {
        enum FakeError: Error, Equatable { case foo }
        mockLanguageSampleSource.mockError = FakeError.foo

        await assertAsyncThrowsEqual(FakeError.foo) {
            _ = try await self.createSubject().detectLanguage(from: self.mockLanguageSampleSource)
        }
    }

    // MARK: - NaturalLanguageRecognizer integration

    func test_detectLanguage_withRealRecognizer_identifiesConfidentText() async throws {
        mockLanguageSampleSource.htmlLangResult = nil
        mockLanguageSampleSource.mockResult = "Hello world, this is clearly an English sentence."
        let subject = createSubject(recognizer: NaturalLanguageRecognizer())
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "en")
    }

    func test_detectLanguage_withRealRecognizer_rejectsUnidentifiableText() async throws {
        mockLanguageSampleSource.htmlLangResult = nil
        mockLanguageSampleSource.mockResult = ":: == >>> ### @@@ {} [] () <> //"
        let subject = createSubject(recognizer: NaturalLanguageRecognizer())
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    // MARK: - normalizeLanguageCode

    func test_normalizeLanguageCode_simpleCode() {
        XCTAssertEqual(LanguageDetector.normalizeLanguageCode("en"), "en")
    }

    func test_normalizeLanguageCode_regionCode() {
        XCTAssertEqual(LanguageDetector.normalizeLanguageCode("en-US"), "en")
    }

    func test_normalizeLanguageCode_scriptCode() {
        XCTAssertEqual(LanguageDetector.normalizeLanguageCode("zh-Hans"), "zh-Hans")
    }

    func test_normalizeLanguageCode_scriptAndRegion() {
        XCTAssertEqual(LanguageDetector.normalizeLanguageCode("zh-Hans-CN"), "zh-Hans")
    }

    func test_normalizeLanguageCode_invalidCode() {
        XCTAssertNil(LanguageDetector.normalizeLanguageCode(""))
    }

    // MARK: - Helpers

    private func createSubject(recognizer: LanguageRecognizing? = nil) -> LanguageDetector {
        LanguageDetector(recognizer: recognizer ?? mockRecognizer)
    }
}

/// Test double for `LanguageRecognizing` that returns a preconfigured result regardless of input,
/// so reconciliation and threshold logic can be exercised with deterministic confidence values.
final class MockLanguageRecognizer: LanguageRecognizing, @unchecked Sendable {
    var result: (languageCode: String, confidence: Double)?

    func dominantLanguage(in text: String) -> (languageCode: String, confidence: Double)? {
        result
    }
}
