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

    static let badSSEPayload = Data([0xFF, 0xFF, 0xFF])

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

    func testBadPayloadThrows() throws {
        let subject = createSubject()
        XCTAssertThrowsError(try subject.parse(Self.badSSEPayload) as [EventExampleType]) { error in
            XCTAssertEqual(error as? SSEDataParserError, .invalidDataEncoding)
        }
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
