// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client

final class MockAgentLLM: AgentLLM, @unchecked Sendable {
    private let lock = NSLock()
    private var callIndex = 0
    let responses: [(raw: String, decision: AgentDecision?)]
    private(set) var recordedHistories: [[AgentStepEntry]] = []

    init(responses: [(raw: String, decision: AgentDecision?)]) {
        self.responses = responses
    }

    func decide(goal: String, history: [AgentStepEntry], pageText: String) async throws -> (raw: String, decision: AgentDecision?) {
        lock.lock()
        defer { lock.unlock() }
        recordedHistories.append(history)
        guard callIndex < responses.count else { throw AgentLLMError.network }
        let response = responses[callIndex]
        callIndex += 1
        return response
    }
}

@MainActor
final class AIAgentServiceTests: XCTestCase {
    func testParseDecision_goalComplete() {
        let raw = """
        Here is the plan:
        {"thought": "Found it", "goalComplete": true, "action": "done", "answer": "Paris"}
        """
        let decision = parseDecision(raw)
        XCTAssertEqual(decision?.goalComplete, true)
        XCTAssertEqual(decision?.action, "done")
        XCTAssertEqual(decision?.answer, "Paris")
    }

    func testIsWebPage() {
        XCTAssertTrue(AIAgentService.isWebPage(URL(string: "https://example.com")))
        XCTAssertFalse(AIAgentService.isWebPage(URL(string: "internal://local")))
        XCTAssertFalse(AIAgentService.isWebPage(nil))
    }

    func testEmptyPageMap_skipsInternalHome() {
        let map = AIAgentService.emptyPageMap(for: URL(string: "internal://local"))
        XCTAssertEqual(map.summary.title, "Firefox Home")
        XCTAssertEqual(map.summary.total, 0)
        XCTAssertTrue(map.pageText.contains("No web page is loaded"))
    }

    func testRun_stopsOnGoalComplete() async throws {
        let done = AgentDecision(thought: "done", action: "done", index: nil, text: nil,
                                 url: nil, answer: "ok", goalComplete: true)
        let mock = MockAgentLLM(responses: [(raw: "{}", decision: done)])
        let service = AIAgentService(groqAPIKey: "test", maxSteps: 5, llm: mock)
        let webView = WKWebView()
        webView.load(URLRequest(url: URL(string: "internal://local")!))

        let result = try await service.run(goal: "test goal", on: webView)

        XCTAssertEqual(result.decision?.goalComplete, true)
        XCTAssertEqual(mock.recordedHistories.count, 1)
        XCTAssertTrue(mock.recordedHistories[0].isEmpty)
    }

    func testRun_passesHistoryToNextLLMCall() async throws {
        let step0 = AgentDecision(thought: "search", action: "search", index: nil, text: "cats",
                                  url: nil, answer: nil, goalComplete: false)
        let step1 = AgentDecision(thought: "finish", action: "done", index: nil, text: nil,
                                  url: nil, answer: "done", goalComplete: true)
        let mock = MockAgentLLM(responses: [
            (raw: "{}", decision: step0),
            (raw: "{}", decision: step1)
        ])
        let service = AIAgentService(groqAPIKey: "test", maxSteps: 5, llm: mock)
        service.onSearch = { _ in }
        let webView = WKWebView()
        webView.load(URLRequest(url: URL(string: "internal://local")!))

        _ = try await service.run(goal: "find cats", on: webView)

        XCTAssertEqual(mock.recordedHistories.count, 2)
        XCTAssertTrue(mock.recordedHistories[0].isEmpty)
        XCTAssertEqual(mock.recordedHistories[1].count, 1)
        XCTAssertEqual(mock.recordedHistories[1][0].action, "search")
    }
}
