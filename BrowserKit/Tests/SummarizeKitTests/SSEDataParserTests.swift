// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SummarizeKit

final class SSEDataParserTests: XCTestCase {
    private struct EventExampleType: Decodable, Equatable {
        let id: Int
        let content: String
        let tags: [String]?
    }

    static let onelineSSEPayload = """
    data: { "id": 42, "content": "Foo", "tags": ["tag1", "tag2"]}


    """.data(using: .utf8)!

    static let multilineSSEPayload = """
    data: { "id": 42, "content": "Foo", "tags": ["tag1", "tag2"]}

    data: { "id": 43, "content": "Bar", "tags": ["tag3", "tag4"]}

    data: [DONE]


    """.data(using: .utf8)!

    static let mixedSSEPayload = """
    data: { "id": 42, "content": "Foo", "tags": ["tag1", "tag2"]}

    data: { "id": 43, "content": "Bar", "tags": ["tag3", "tag4"]}

    data: [DONE]

    data: { "id": 43, "content": "Baz", "tags": ["tag5", "tag6"]}
    """.data(using: .utf8)!

    static let incompleteSSEPayload = Data([0xFF, 0xFF, 0xFF])

    static let invalidSSEPayload = """
    data: { "id": "notAnInt", "content": "Foo" }


    """.data(using: .utf8)!

    static let partialSSEChunk1 = """
    data: {
    """.data(using: .utf8)!

    static let partialSSEChunk2 = """
    "id": 44,
    """.data(using: .utf8)!

    static let partialSSEChunk3 = """
    "content": "Qux", "tags": ["tag7", "tag8"]}


    """.data(using: .utf8)!

    static let emojiOnelineSSEPayload = """
    data: { "id": 45, "content": "Hello 🥕", "tags": null}


    """.data(using: .utf8)!

    static let emojiPartialChunk1 = Data("data: { \"id\": 46, \"content\": \"Hi ".utf8)
    // First byte of 🥕 (U+1F955)
    static let emojiPartialChunk2 = Data([0xF0])
    // Remaining bytes of 🥕 + rest of payload
    static let emojiPartialChunk3: Data = Data([0x9F, 0xA5, 0x95]) + Data("\", \"tags\": null}\n\n".utf8)

    static let crlfOnelineSSEPayload = """
    data: { \"id\": 50, \"content\": \"CRLF\", \"tags\": null}\r\n\r\n"
    """.data(using: .utf8)!

    func testOnelinePayloadParsesSuccessfully() throws {
        let subject = createSubject()
        let results: [EventExampleType] = try subject.parse(Self.onelineSSEPayload)
        XCTAssertEqual(results, [
            EventExampleType(id: 42, content: "Foo", tags: ["tag1", "tag2"])
        ])
    }

    func testMultilinePayloadParsesSuccessfullyAndStopsAtDone() async throws {
        let subject = createSubject()
        let results: [EventExampleType] = try subject.parse(Self.multilineSSEPayload)
        XCTAssertEqual(results, [
            EventExampleType(id: 42, content: "Foo", tags: ["tag1", "tag2"]),
            EventExampleType(id: 43, content: "Bar", tags: ["tag3", "tag4"])
        ])
    }

    func testIncompleteUtf8DoesNotEmit() throws {
        let subject = createSubject()
        let results: [EventExampleType] = try subject.parse(Self.incompleteSSEPayload)
        XCTAssertEqual(results, [])
    }

    func testInvalidPayloadThrows() throws {
        let subject = createSubject()
        XCTAssertThrowsError(try subject.parse(Self.invalidSSEPayload) as [EventExampleType]) { error in
            XCTAssertEqual(error as? SSEDataParserError, .invalidDataEncoding)
        }
    }

    func testParsingStopsAtDoneInMiddle() async throws {
        let subject = createSubject()
        let results: [EventExampleType] = try subject.parse(Self.mixedSSEPayload)
        XCTAssertEqual(results, [
            EventExampleType(id: 42, content: "Foo", tags: ["tag1", "tag2"]),
            EventExampleType(id: 43, content: "Bar", tags: ["tag3", "tag4"])
        ])
    }

    func testParsingChunkedInput() async throws {
        let subject = createSubject()
        var results: [EventExampleType] = []
        results = try subject.parse(Self.partialSSEChunk1)
        XCTAssertEqual(results, [])
        results = try subject.parse(Self.partialSSEChunk2)
        XCTAssertEqual(results, [])
        results = try subject.parse(Self.partialSSEChunk3)
        XCTAssertEqual(results, [
            EventExampleType(id: 44, content: "Qux", tags: ["tag7", "tag8"])
        ])
    }

    func testEmojiInSingleChunkParsesSuccessfully() throws {
        let subject = createSubject()
        let results: [EventExampleType] = try subject.parse(Self.emojiOnelineSSEPayload)
        XCTAssertEqual(results, [
            EventExampleType(id: 45, content: "Hello 🥕", tags: nil)
        ])
    }

    func testEmojiSplitAcrossChunksParsesSuccessfully() throws {
        let subject = createSubject()
        var results: [EventExampleType] = []

        results = try subject.parse(Self.emojiPartialChunk1)
        XCTAssertEqual(results, [])

        results = try subject.parse(Self.emojiPartialChunk2)
        XCTAssertEqual(results, [])

        results = try subject.parse(Self.emojiPartialChunk3)
        XCTAssertEqual(results, [
            EventExampleType(id: 46, content: "Hi 🥕", tags: nil)
        ])
    }

    func testCRLFDelimiterParsesSuccessfully() throws {
        let subject = createSubject()
        let results: [EventExampleType] = try subject.parse(Self.crlfOnelineSSEPayload)
        XCTAssertEqual(results, [EventExampleType(id: 50, content: "CRLF", tags: nil)])
    }

    func testFlushClearsBuffer() throws {
        let subject = createSubject()
        var results: [EventExampleType] = []
        results = try subject.parse(Self.partialSSEChunk1)
        XCTAssertEqual(results, [])
        results = try subject.parse(Self.partialSSEChunk2)
        XCTAssertEqual(results, [])
        // Before we parse the last chunk flush the buffer
        subject.flush()
        results = try subject.parse(Self.partialSSEChunk3)
        XCTAssertEqual(results, [])
    }

    private func createSubject() -> SSEDataParser {
        let subject = SSEDataParser()
        trackForMemoryLeaks(subject)
        return subject
    }
}
