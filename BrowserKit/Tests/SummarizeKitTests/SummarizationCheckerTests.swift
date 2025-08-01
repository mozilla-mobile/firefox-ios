// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import SummarizeKit
import XCTest

final class SummarizationCheckerTests: XCTestCase {
    func jsStubBuilder(
        canSummarize: Bool,
        reason: String? = nil,
        wordCount: Int? = nil
    ) -> [String: Any] {
        var stub: [String: Any] = ["canSummarize": canSummarize]
        if let reason = reason { stub["reason"] = reason }
        if let wordCount = wordCount { stub["wordCount"] = wordCount }
        return stub
    }

    func testSummarizationCheckerCanSummarizeTrue() throws {
        let subject = createSubject()
        let result = try subject.parse(
            jsStubBuilder(canSummarize: true, wordCount: 42))
        XCTAssertTrue(result.canSummarize)
        XCTAssertNil(result.reason)
        XCTAssertEqual(result.wordCount, 42)
    }

    /// JS stub for a page that is in an unsupported language.
    func testSummarizationCheckerCanSummarizeFalseSocumentLanguageUnsupported() throws {
        let subject = createSubject()
        let result = try subject.parse(
            jsStubBuilder(canSummarize: false, reason: "documentLanguageUnsupported", wordCount: 0))
        XCTAssertFalse(result.canSummarize)
        XCTAssertEqual(result.reason, .documentLanguageUnsupported)
        XCTAssertEqual(result.wordCount, 0)
    }

    /// JS stub for a page that is not reader‑readable.
    func testSummarizationCheckerCanSummarizeFalseNotReadable() throws {
        let subject = createSubject()
        let result = try subject.parse(
            jsStubBuilder(canSummarize: false, reason: "documentNotReadable", wordCount: 0))
        XCTAssertFalse(result.canSummarize)
        XCTAssertEqual(result.reason, .documentNotReadable)
        XCTAssertEqual(result.wordCount, 0)
    }

    /// JS stub for a page that is too long to summarize.
    func testSummarizationCheckerCanSummarizeFalseContentTooLong() throws {
        let subject = createSubject()
        let result = try subject.parse(
            jsStubBuilder(canSummarize: false, reason: "contentTooLong", wordCount: 9001))
        XCTAssertFalse(result.canSummarize)
        XCTAssertEqual(result.reason, .contentTooLong)
        XCTAssertEqual(result.wordCount, 9001)
    }

    /// When a required key is missing, decoding should throw `.decodingFailed`.
    func testSummarizationCheckerMissingField() {
        let subject = createSubject()
        XCTAssertThrowsError(try subject.parse(jsStubBuilder(canSummarize: true))) { error in
            guard case .decodingFailed = error as? SummarizationCheckError else {
                return XCTFail("Expected .decodingFailed, got \(error)")
            }
        }
    }

    /// When the `reason` value doesn’t map to any enum case, decoding should throw `.decodingFailed`.
    func testSummarizationCheckerUnknownReason() {
        let subject = createSubject()
        XCTAssertThrowsError(
            try subject.parse(
                jsStubBuilder(canSummarize: false, reason: "fooReason", wordCount: 0))
        ) { error in
            guard case .decodingFailed = error as? SummarizationCheckError else {
                return XCTFail("Expected .decodingFailed, got \(error)")
            }
        }
    }

    private func createSubject() -> SummarizationChecker {
        let subject = SummarizationChecker()
        trackForMemoryLeaks(subject)
        return subject
    }
}
