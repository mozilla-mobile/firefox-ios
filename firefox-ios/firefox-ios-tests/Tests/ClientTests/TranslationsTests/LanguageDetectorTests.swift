// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class LanguageDetectorTests: XCTestCase {
    var mockLanguageSampleSource = MockLanguageSampleSource()

    func testExtractSampleReturnsTextSample() async throws {
        mockLanguageSampleSource.mockResult = "Bonjour le monde"
        let subject = createSubject()
        let result = try await subject.extractSample(from: mockLanguageSampleSource)
        XCTAssertEqual(result, "Bonjour le monde")
    }

    func testExtractSampleReturnsNilForEmptyString() async throws {
        mockLanguageSampleSource.mockResult = ""
        let subject = createSubject()
        let result = try await subject.extractSample(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    func testExtractSampleReturnsNilForNonString() async throws {
        mockLanguageSampleSource.mockResult = 42
        let subject = createSubject()
        let result = try await subject.extractSample(from: mockLanguageSampleSource)
        XCTAssertNil(result)
    }

    func testExtractSamplePropagatesError() async {
        enum FakeError: Error { case foo }
        mockLanguageSampleSource.mockError = FakeError.foo
        let subject = createSubject()

        do {
            _ = try await subject.extractSample(from: mockLanguageSampleSource)
            XCTFail("expected error")
        } catch { }
    }
    
    func testDetectLanguageReturnsLanguageCode() {
        let subject = createSubject()
        
        XCTAssertEqual(subject.detectLanguage(of: "Hello world"), "en")
        XCTAssertEqual(subject.detectLanguage(of: "Bonjour le monde"), "fr")
        XCTAssertEqual(subject.detectLanguage(of: "Hola mundo"), "es")
        XCTAssertEqual(subject.detectLanguage(of: "こんにちは世界"), "ja")
        XCTAssertEqual(subject.detectLanguage(of: "안녕하세요 세계"), "ko")
    }


    func testDetectLanguageReturnsNilForEmptyOrWhitespace() {
        let subject = createSubject()

        XCTAssertNil(subject.detectLanguage(of: ""))
        XCTAssertNil(subject.detectLanguage(of: " \n\t "))
    }

    func testDetectLanguagePrefersDominantLanguage() {
        let subject = createSubject()
        let text = "Hello, bonjour, hello, hello"
        XCTAssertEqual(subject.detectLanguage(of: text), "en")
    }

    private func createSubject() -> LanguageDetector {
        LanguageDetector()
    }
}
