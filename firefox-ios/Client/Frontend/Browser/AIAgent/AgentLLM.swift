// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol AgentLLM: Sendable {
    func decide(
        goal: String,
        history: [AgentStepEntry],
        pageText: String
    ) async throws -> (raw: String, decision: AgentDecision?)
}

enum AgentLLMError: LocalizedError {
    case network
    case http(Int, String)
    case noKey

    var errorDescription: String? {
        switch self {
        case .network: return "Network error"
        case .http(let code, let msg): return "HTTP \(code): \(msg)"
        case .noKey: return "No Groq API key set. Add it in Settings → AI Controls."
        }
    }
}

enum AgentPrompt {
    static let system = """
    You are a browser agent. Each turn you receive:
      1. GOAL — the user's original goal (never changes).
      2. HISTORY — compact record of every step taken so far (empty on step 0).
      3. CURRENT PAGE — visible interactive elements and page text, OR a notice that no \
    page is loaded yet.

    First decide: is the goal already satisfied by what you see / what history shows? \
    If yes, set "goalComplete": true and "action": "done" with "answer". \
    If no, choose exactly ONE next action and set "goalComplete": false.

    Respond with ONLY a JSON object, no markdown, no prose:
    {"thought": "...", "goalComplete": true|false, \
    "action": "navigate|search|click|type|select|scroll|done", \
    "index": <int or null>, "text": "<text or null>", \
    "url": "<url or null>", "answer": "<final answer or null>"}

    "thought" MUST be one short sentence, 20 words MAX — it is shown live in a one-line UI.

    Action rules:
    - type: use [index] + "text" to fill a field.
    - click: use [index] to press a button or link.
    - search: use "text" to search the web (preferred when no exact URL known).
    - navigate: use "url" only for a known exact URL.
    - scroll: no extra fields; reveals more elements below the fold.
    - done: put a clear final reply in "answer" (see FINAL ANSWER below).
    - Pick indexes ONLY from the CURRENT PAGE list.

    SCROLLING: page list shows ONLY on-screen elements. If needed element missing:
    - If SCROLL shows not at BOTTOM, scroll to reveal more.
    - If at BOTTOM and still not found, search or navigate elsewhere.
    - Stop scrolling if no new relevant elements appear.

    NO PAGE LOADED: If CURRENT PAGE says no web page is loaded, use search, navigate, \
    or done. Do not click or type.

    HISTORY: trust it — don't repeat an action that already failed or produced a result.

    FINISH EARLY: If the VISIBLE PAGE TEXT already contains the information the goal asks \
    for, STOP immediately — set "goalComplete": true and "action": "done". Do not keep \
    reading, scrolling, or navigating once the answer is on the page. Never loop.

    FINAL ANSWER: When stopping with "done", "answer" is shown full-screen to the user (not \
    the one-line "thought"). Write 2–5 sentences: directly address the GOAL, include the key \
    facts or outcome, and briefly note how you found them (e.g. which page or search). Be \
    helpful and complete, not a single word or bare fact. "thought" stays short; "answer" \
    is the real explanation.
    """

    static func user(goal: String, history: [AgentStepEntry], pageText: String) -> String {
        var parts: [String] = []
        parts.append("GOAL: \(goal)")

        if history.isEmpty {
            parts.append("HISTORY: (none — this is step 0)")
        } else {
            var lines = ["HISTORY:"]
            for entry in history {
                lines.append("  step \(entry.stepIndex): [\(entry.url)] \(entry.action)(\(entry.detail)) → \(entry.result)")
            }
            parts.append(lines.joined(separator: "\n"))
        }

        parts.append("CURRENT PAGE:\n\(pageText)")
        return parts.joined(separator: "\n\n")
    }

    static let emptyPageText = """
    No web page is loaded. The browser is showing Firefox Home or an internal browser page.
    There are no page elements to click, type into, select, or scroll.
    Choose a first action: search (to query the web), navigate (to go to a known URL), or done.
    """
}

func parseDecision(_ raw: String) -> AgentDecision? {
    guard let start = raw.firstIndex(of: "{"),
          let end = raw.lastIndex(of: "}") else { return nil }
    let slice = String(raw[start...end])
    return try? JSONDecoder().decode(AgentDecision.self, from: Data(slice.utf8))
}

struct GroqClient: AgentLLM, Sendable {
    let apiKey: String
    let model = "meta-llama/llama-4-scout-17b-16e-instruct"
    private let logger: Logger

    init(apiKey: String, logger: Logger = DefaultLogger.shared) {
        self.apiKey = apiKey
        self.logger = logger
    }

    func decide(
        goal: String,
        history: [AgentStepEntry],
        pageText: String
    ) async throws -> (raw: String, decision: AgentDecision?) {
        guard !apiKey.isEmpty else { throw AgentLLMError.noKey }

        let userContent = AgentPrompt.user(goal: goal, history: history, pageText: pageText)
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "temperature": 0,
            "messages": [
                ["role": "system", "content": AgentPrompt.system],
                ["role": "user", "content": userContent]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw AgentLLMError.network }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "no body"
            logger.log("Groq API HTTP \(http.statusCode)", level: .warning, category: .webview)
            throw AgentLLMError.http(http.statusCode, msg)
        }
        let parsed = try JSONDecoder().decode(GroqResponse.self, from: data)
        let content = parsed.choices.first?.message.content ?? ""
        return (content, parseDecision(content))
    }

    private struct GroqResponse: Codable {
        struct Choice: Codable { let message: Message }
        struct Message: Codable { let content: String }
        let choices: [Choice]
    }
}
