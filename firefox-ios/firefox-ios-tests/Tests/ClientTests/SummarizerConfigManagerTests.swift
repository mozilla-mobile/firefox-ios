// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SummarizeKit
@testable import Client

@MainActor
final class SummarizerConfigManagerTests: XCTestCase {
    func testReturnsEmptyConfigWhenNoSourcesProvided() async {
        let subject = createSubject(sources: [])
        let config = subject.getConfig(.appleSummarizer, contentType: .generic)
        XCTAssertEqual(config.instructions, "")
        XCTAssertTrue(config.options.isEmpty)
    }

    func testReturnsEmptyConfigWhenAllSourcesAreEmpty() async {
        let mockSources = [
            MockSummarizerConfigSource(configToReturn: SummarizerConfig(
                instructions: "",
                options: [:]
            )),
            MockSummarizerConfigSource(configToReturn: SummarizerConfig(
                instructions: "",
                options: [:]
            ))
        ]

        let subject = createSubject(sources: mockSources)
        let config = subject.getConfig(.appleSummarizer, contentType: .generic)
        XCTAssertEqual(config.instructions, "")
        XCTAssertTrue(config.options.isEmpty)
    }

    func testUsesFirstNonEmptyInstructions() async {
        let mockSources = [
            MockSummarizerConfigSource(configToReturn: SummarizerConfig(
                instructions: "",
                options: [:]
            )),
            MockSummarizerConfigSource(configToReturn: SummarizerConfig(
                instructions: "Instructions",
                options: [:]
            ))
        ]

        let subject = createSubject(sources: mockSources)
        let config = subject.getConfig(.liteLLMSummarizer, contentType: .recipe)
        XCTAssertEqual(config.instructions, "Instructions")
        XCTAssertTrue(config.options.isEmpty)
    }

    func testMergesConfigsWithCorrectPriority() async {
        let mockSources = [
            MockSummarizerConfigSource(configToReturn: SummarizerConfig(
                instructions: "Instructions 1",
                options: ["temperature": 0.1]
            )),
            MockSummarizerConfigSource(configToReturn: SummarizerConfig(
                instructions: "Instructions 2",
                options: ["temperature": 0.2, "maxTokens": 200]
            )),
            MockSummarizerConfigSource(configToReturn: SummarizerConfig(
                instructions: "Instructions 3",
                options: ["temperature": 0.3, "maxTokens": 300, "topP": 0.3]
            ))
        ]

        let subject = createSubject(sources: mockSources)
        let config = subject.getConfig(.appleSummarizer, contentType: .generic)

        // Highest priority instructions
        XCTAssertEqual(config.instructions, "Instructions 1")
        // Highest priority for temperature
        XCTAssertEqual(config.options["temperature"] as? Double, 0.1)
        // Second priority for maxTokens
        XCTAssertEqual(config.options["maxTokens"] as? Int, 200)
        // Third priority for topP (only the last sourtce has it)
        XCTAssertEqual(config.options["topP"] as? Double, 0.3)
    }

    func testMergesOptionsWithDifferentTypes() async {
        let mockSources = [
            MockSummarizerConfigSource(configToReturn: SummarizerConfig(
                instructions: "",
                options: ["topP": 2, "stream": true]
            )),
            MockSummarizerConfigSource(configToReturn: SummarizerConfig(
                instructions: "Instructions 2",
                options: ["penalty": 4, "model": "foo"]
            ))
        ]

        let subject = createSubject(sources: mockSources)
        let config = subject.getConfig(.liteLLMSummarizer, contentType: .recipe)

        XCTAssertEqual(config.instructions, "Instructions 2")
        XCTAssertEqual(config.options["topP"] as? Int, 2)
        XCTAssertEqual(config.options["stream"] as? Bool, true)
        XCTAssertEqual(config.options["penalty"] as? Int, 4)
        XCTAssertEqual(config.options["model"] as? String, "foo")
    }

    private func createSubject(sources: [SummarizerConfigSourceProtocol] = []) -> SummarizerConfigManager {
        let subject = SummarizerConfigManager(sources: sources)
        trackForMemoryLeaks(subject)
        return subject
    }
}
