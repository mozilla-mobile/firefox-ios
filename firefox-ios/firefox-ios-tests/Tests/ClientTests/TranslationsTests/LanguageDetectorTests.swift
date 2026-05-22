// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class LanguageDetectorTests: XCTestCase {
    var mockLanguageSampleSource = MockLanguageSampleSource()

    // MARK: - HTML lang attribute

    func test_detectLanguage_prefersHTMLLangOverTextAnalysis() async throws {
        mockLanguageSampleSource.htmlLangResult = "de"
        mockLanguageSampleSource.mockResult = "Hello world, this is clearly an English sentence."
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "de")
    }

    func test_detectLanguage_normalizesHTMLLangWithRegion() async throws {
        mockLanguageSampleSource.htmlLangResult = "en-US"
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "en")
    }

    func test_detectLanguage_preservesScriptSubtag() async throws {
        mockLanguageSampleSource.htmlLangResult = "zh-Hans-CN"
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "zh-Hans")
    }

    func test_detectLanguage_fallsBackToTextWhenHTMLLangMissing() async throws {
        mockLanguageSampleSource.htmlLangResult = nil
        mockLanguageSampleSource.mockResult = "Bonjour le monde"
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "fr")
    }

    func test_detectLanguage_ignoresEmptyHTMLLang() async throws {
        mockLanguageSampleSource.htmlLangResult = ""
        mockLanguageSampleSource.mockResult = "Bonjour le monde"
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "fr")
    }

    // MARK: - NLLanguageRecognizer text analysis

    func test_detectLanguage_withFrench_returnsProperLanguageCode() async throws {
        mockLanguageSampleSource.mockResult = "Bonjour le monde"
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "fr")
    }

    func test_detectLanguage_withEnglish_returnsProperLanguageCode() async throws {
        mockLanguageSampleSource.mockResult = "Hello world"
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "en")
    }

    func test_detectLanguage_withSpanish_returnsProperLanguageCode() async throws {
        mockLanguageSampleSource.mockResult = "Hola mundo"
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "es")
    }

    func test_detectLanguage_withJapanese_returnsProperLanguageCode() async throws {
        mockLanguageSampleSource.mockResult = "こんにちは世界"
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "ja")
    }

    func test_detectLanguage_withKorean_returnsProperLanguageCode() async throws {
        mockLanguageSampleSource.mockResult = "안녕하세요 세계"
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "ko")
    }

    func test_detectLanguage_withEmptyString_returnsNil() async throws {
        mockLanguageSampleSource.mockResult = ""
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    func test_detectLanguage_withWhitespaces_returnsNil() async throws {
        mockLanguageSampleSource.mockResult = " \n\t "
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    func test_detectLanguage_returnsNilForNonString() async throws {
        mockLanguageSampleSource.mockResult = 42
        let subject = createSubject()
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    func test_detectLanguage_propagatesError() async {
        enum FakeError: Error, Equatable { case foo }
        mockLanguageSampleSource.mockError = FakeError.foo
        let subject = createSubject()

        await assertAsyncThrowsEqual(FakeError.foo) {
            _ = try await subject.detectLanguage(from: mockLanguageSampleSource)
        }
    }

    func test_detectLanguage_prefersDominantLanguage() async throws {
        let subject = createSubject()
        mockLanguageSampleSource.mockResult = "Hello! This is an English sentence. A common word in French is Bonjour."
        let result = try await subject.detectLanguage(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "en")
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

    private func createSubject() -> LanguageDetector {
        LanguageDetector()
    }
}
