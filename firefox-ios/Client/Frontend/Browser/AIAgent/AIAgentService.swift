// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Common

struct AgentStepResult: Sendable {
    let map: AgentPageMap
    let raw: String
    let decision: AgentDecision?
    let actionLog: String
    let stepIndex: Int
}

@MainActor
final class AIAgentService {
    private let perception: WebAgentPerception
    private let actor: WebAgentActor
    private let llm: AgentLLM
    private let maxSteps: Int
    private let logger: Logger

    var onNavigate: ((URL) -> Void)?
    var onSearch: ((String) -> Void)?
    var onStep: ((AgentStepResult) -> Void)?

    init(groqAPIKey: String,
         maxSteps: Int = 15,
         llm: AgentLLM? = nil,
         logger: Logger = DefaultLogger.shared) {
        self.llm = llm ?? GroqClient(apiKey: groqAPIKey, logger: logger)
        self.maxSteps = maxSteps
        self.logger = logger
        self.perception = WebAgentPerception(logger: logger)
        self.actor = WebAgentActor(logger: logger)
    }

    @discardableResult
    func run(goal: String, on webView: WKWebView) async throws -> AgentStepResult {
        var history: [AgentStepEntry] = []
        var last: AgentStepResult?
        var skipPerception = !AIAgentService.isWebPage(webView.url)

        for stepIndex in 0..<maxSteps {
            try Task.checkCancellation()
            let pageText: String
            let map: AgentPageMap
            let currentURL = webView.url?.absoluteString ?? "(none)"

            if skipPerception {
                map = AIAgentService.emptyPageMap(for: webView.url)
                pageText = AgentPrompt.emptyPageText
                skipPerception = false
            } else {
                map = try await perception.extract(on: webView)
                pageText = map.agentText
            }

            var (raw, decision) = try await llm.decide(goal: goal, history: history, pageText: pageText)

            if decision == nil {
                (raw, decision) = try await llm.decide(goal: goal, history: history, pageText: pageText)
                if decision == nil {
                    let result = AgentStepResult(map: map, raw: raw, decision: nil,
                                                 actionLog: "parse failed", stepIndex: stepIndex)
                    onStep?(result)
                    return result
                }
            }

            guard let d = decision else { break }

            try Task.checkCancellation()
            let actionLog = try await perform(d, on: webView)

            history.append(AgentStepEntry(stepIndex: stepIndex, url: currentURL,
                                          action: d.action, detail: actionDetail(d), result: actionLog))

            let result = AgentStepResult(map: map, raw: raw, decision: d,
                                         actionLog: actionLog, stepIndex: stepIndex)
            onStep?(result)
            last = result

            if d.goalComplete == true || d.action == "done" {
                break
            }

            try? await Task.sleep(nanoseconds: 1_200_000_000)
        }

        guard let final = last else {
            logger.log("AI agent loop produced no steps", level: .warning, category: .webview)
            throw AgentLLMError.network
        }
        return final
    }

    private func perform(_ d: AgentDecision, on webView: WKWebView) async throws -> String {
        switch d.action {
        case "navigate":
            guard let urlString = d.url, let url = URL(string: urlString) else {
                return "navigate: bad url"
            }
            onNavigate?(url)
            await waitForPageReady(webView)
            return "navigating to \(urlString)"
        case "search":
            guard let query = d.text, !query.isEmpty else { return "search: no query" }
            onSearch?(query)
            await waitForPageReady(webView)
            return "searching"
        case "done":
            return "done: \(d.answer ?? "")"
        default:
            return (try? await actor.execute(d, on: webView)) ?? "action failed"
        }
    }

    /// Waits until the page has actually finished loading (load state + DOM
    /// readyState) before the next perception, with a hard cap so a never-idle
    /// page (ads/trackers) can't stall the agent. A short settle delay lets
    /// client-rendered (SPA) content paint after readyState reports complete.
    private func waitForPageReady(_ webView: WKWebView,
                                  timeout: TimeInterval = 8,
                                  settle: UInt64 = 400_000_000) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if Task.isCancelled { return }
            let readyState = (try? await webView.evaluateJavaScript("document.readyState")) as? String
            if !webView.isLoading && readyState == "complete" { break }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        try? await Task.sleep(nanoseconds: settle)
    }

    private func actionDetail(_ d: AgentDecision) -> String {
        switch d.action {
        case "navigate": return d.url ?? ""
        case "search": return d.text ?? ""
        case "type": return "[\(d.index ?? -1)] \"\(d.text ?? "")\""
        case "click", "select": return "[\(d.index ?? -1)]"
        case "scroll": return "scroll"
        case "done": return d.answer ?? ""
        default: return ""
        }
    }

    static func isWebPage(_ url: URL?) -> Bool {
        guard let scheme = url?.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    static func emptyPageMap(for url: URL?) -> AgentPageMap {
        let urlStr = url?.absoluteString ?? "(none)"
        let summary = PageSummary(url: urlStr, title: "Firefox Home", total: 0, visible: 0,
                                  typeable: 0, clickable: 0, selectable: 0,
                                  scrollY: 0, atTop: true, atBottom: true, belowFoldCount: 0)
        return AgentPageMap(pageText: AgentPrompt.emptyPageText, summary: summary, elements: [])
    }
}
