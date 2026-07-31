// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// What the screen renders. The Client maps Redux state and collected device data onto this,
/// keeping Redux out of the package. Labels and values are the raw Glean `broken_site_report`
/// keys and their JSON rendering. Plain-language copy comes later.
public struct WebCompatReportPreviewViewModel: Equatable, Sendable {
    /// Typed rather than pre-formatted, so the view decides how to render it. `.null` is a
    /// field we don't collect yet.
    public enum PreviewValue: Hashable, Sendable {
        case string(String)
        case list([String])
        case bool(Bool)
        case quantity(Int)
        case null

        public var displayText: String {
            switch self {
            case .string(let value):
                return "\"\(value)\""
            case .list(let values):
                return "[" + values.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
            case .bool(let value):
                return value ? "true" : "false"
            case .quantity(let value):
                return String(value)
            case .null:
                return "null"
            }
        }
    }

    /// One line in a section, e.g. label "breakage_category", value `.string("media")`.
    public struct PreviewRow: Hashable, Sendable {
        public let id: String
        public let label: String
        public let value: PreviewValue

        public init(id: String, label: String, value: PreviewValue) {
            self.id = id
            self.label = label
            self.value = value
        }
    }

    /// A collapsible group, named after its payload group: "basic", "tabInfo", etc.
    public struct PreviewSection: Hashable, Sendable {
        public let id: String
        public let title: String
        /// Goes on the header cell, which is what the user taps to expand.
        public let a11yIdentifier: String
        /// Goes on the card the header reveals. Supplied rather than derived, so the Client
        /// stays the single source of identifiers.
        public let contentA11yIdentifier: String
        public let rows: [PreviewRow]

        public init(
            id: String,
            title: String,
            a11yIdentifier: String,
            contentA11yIdentifier: String,
            rows: [PreviewRow]
        ) {
            self.id = id
            self.title = title
            self.a11yIdentifier = a11yIdentifier
            self.contentA11yIdentifier = contentA11yIdentifier
            self.rows = rows
        }
    }

    public let title: String
    public let closeAccessibilityLabel: String
    public let closeA11yIdentifier: String
    public let sections: [PreviewSection]

    public init(
        title: String,
        closeAccessibilityLabel: String,
        closeA11yIdentifier: String,
        sections: [PreviewSection] = []
    ) {
        self.title = title
        self.closeAccessibilityLabel = closeAccessibilityLabel
        self.closeA11yIdentifier = closeA11yIdentifier
        self.sections = sections
    }
}
