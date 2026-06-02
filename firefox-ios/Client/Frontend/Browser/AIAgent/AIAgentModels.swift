// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct PageRect: Codable, Hashable, Sendable {
    let x: Int
    let y: Int
    let w: Int
    let h: Int
}

struct AgentElement: Codable, Identifiable, Hashable, Sendable {
    let index: Int
    let agentId: Int
    let tag: String
    let role: String?
    let action: String
    let label: String
    let placeholder: String?
    let ariaLabel: String?
    let name: String?
    let htmlId: String?
    let selector: String
    let visible: Bool
    let inViewport: Bool
    let covered: Bool
    let rect: PageRect?
    let reason: String?
    let context: String

    var id: Int { index }

    enum CodingKeys: String, CodingKey {
        case index, agentId, tag, role, action, label, placeholder, ariaLabel
        case name
        case htmlId = "id"
        case selector, visible, inViewport, covered, rect, reason, context
    }
}

struct PageSummary: Codable, Hashable, Sendable {
    let url: String
    let title: String?
    let total: Int
    let visible: Int
    let typeable: Int
    let clickable: Int
    let selectable: Int
    let scrollY: Int
    let atTop: Bool
    let atBottom: Bool
    let belowFoldCount: Int
}

struct AgentPageMap: Codable, Hashable, Sendable {
    let pageText: String
    let summary: PageSummary
    let elements: [AgentElement]
}

struct AgentDecision: Codable, Sendable {
    let thought: String
    let action: String
    let index: Int?
    let text: String?
    let url: String?
    let answer: String?
    let goalComplete: Bool?
}

/// One entry in the compact step history passed to the LLM each turn.
struct AgentStepEntry: Sendable {
    let stepIndex: Int
    let url: String
    let action: String
    let detail: String   // query/url/label/index — what was acted on
    let result: String   // actionLog from the executor
}

extension AgentPageMap {
    var agentText: String {
        var lines: [String] = []
        lines.append("PAGE: \(summary.title ?? "(no title)")")
        lines.append("URL: \(summary.url)")
        lines.append("ELEMENTS: \(summary.total) total, \(summary.visible) visible")
        let pos = summary.atTop ? "TOP" : (summary.atBottom ? "BOTTOM" : "MIDDLE")
        lines.append("SCROLL: at \(pos) (y=\(summary.scrollY)), " +
                     "\(summary.belowFoldCount) more interactive elements exist below the fold")
        lines.append("")
        for e in elements where e.visible {
            let ctx = e.context.isEmpty ? "" : "  ctx=\"\(e.context)\""
            let action = e.action.padding(toLength: 6, withPad: " ", startingAt: 0)
            lines.append("[\(e.index)] \(action) <\(e.tag)> \"\(e.label)\"\(ctx)")
        }
        if !pageText.isEmpty {
            lines.append("")
            lines.append("VISIBLE PAGE TEXT (for reading/answering, not clicking):")
            lines.append(pageText)
        }
        return lines.joined(separator: "\n")
    }
}
