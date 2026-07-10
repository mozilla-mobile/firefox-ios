// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The `broken-site-report` payload, aligned 1:1 with the Glean metrics defined
/// in `broken_site_report.yaml` (one property per metric). This is the single
/// source of truth for what the report sends: the Report Preview screen renders
/// it, and the Glean submission (FXIOS-16177 / FXIOS-16185) will serialize the
/// same values — so field names live here once, not hand-typed per screen.
///
/// Fields the app does not collect yet — native device/tab data (FXIOS-16183)
/// and JS page-context data (FXIOS-16184) — are `nil` and render as `null`.
struct WebCompatReportPayload: Equatable {
    // basic
    var url: String?
    var breakageCategory: String?
    var description: String?
    // tabInfo
    var languages: [String]?
    var useragentString: String?
    // tabInfo.antitracking
    var blockList: String?
    var blockedOrigins: [String]?
    var etpCategory: String?
    var isPrivateBrowsing: Bool?
    // tabInfo.frameworks
    var fastclick: Bool?
    var marfeel: Bool?
    var mobify: Bool?
    // browserInfo.app
    var defaultLocales: [String]?
    var defaultUseragentString: String?
    // browserInfo.graphics
    var devicePixelRatio: String?
    var hasTouchScreen: Bool?
    // browserInfo.system
    var isTablet: Bool?
    var memory: Int?

    /// One preview line: its Glean metric key and a JSON-style value.
    struct Field: Equatable {
        let key: String
        let value: String
    }

    /// A titled group of fields, mirroring the report's JSON nesting.
    struct Group: Equatable {
        let title: String
        let fields: [Field]
    }

    /// Seeds the payload from the in-progress report state. Only the fields the
    /// user supplies are populated; everything collected at send time stays nil.
    static func make(from state: WebCompatReporterState) -> WebCompatReportPayload {
        var payload = WebCompatReportPayload()
        payload.url = state.url.isEmpty ? nil : state.url
        payload.breakageCategory = state.selectedSubOptionID ?? state.selectedCategory?.rawValue
        payload.description = state.additionalDetails.isEmpty ? nil : state.additionalDetails
        return payload
    }

    /// The payload grouped for display, in the report's canonical order. Keys are
    /// the Glean metric names; values are JSON-style (`null` when not collected).
    var previewGroups: [Group] {
        return [
            Group(title: "basic", fields: [
                Field(key: "url", value: Self.string(url)),
                Field(key: "breakage_category", value: Self.string(breakageCategory)),
                Field(key: "description", value: Self.string(description))
            ]),
            Group(title: "tabInfo", fields: [
                Field(key: "languages", value: Self.list(languages)),
                Field(key: "useragent_string", value: Self.string(useragentString))
            ]),
            Group(title: "antitracking", fields: [
                Field(key: "block_list", value: Self.string(blockList)),
                Field(key: "blocked_origins", value: Self.list(blockedOrigins)),
                Field(key: "etp_category", value: Self.string(etpCategory)),
                Field(key: "is_private_browsing", value: Self.bool(isPrivateBrowsing))
            ]),
            Group(title: "frameworks", fields: [
                Field(key: "fastclick", value: Self.bool(fastclick)),
                Field(key: "marfeel", value: Self.bool(marfeel)),
                Field(key: "mobify", value: Self.bool(mobify))
            ]),
            Group(title: "app", fields: [
                Field(key: "default_locales", value: Self.list(defaultLocales)),
                Field(key: "default_useragent_string", value: Self.string(defaultUseragentString))
            ]),
            Group(title: "graphics", fields: [
                Field(key: "device_pixel_ratio", value: Self.string(devicePixelRatio)),
                Field(key: "has_touch_screen", value: Self.bool(hasTouchScreen))
            ]),
            Group(title: "system", fields: [
                Field(key: "is_tablet", value: Self.bool(isTablet)),
                Field(key: "memory", value: Self.quantity(memory))
            ])
        ]
    }

    private static func string(_ value: String?) -> String {
        guard let value else { return "null" }
        return "\"\(value)\""
    }

    private static func list(_ value: [String]?) -> String {
        guard let value else { return "null" }
        return "[" + value.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
    }

    private static func bool(_ value: Bool?) -> String {
        guard let value else { return "null" }
        return value ? "true" : "false"
    }

    private static func quantity(_ value: Int?) -> String {
        guard let value else { return "null" }
        return String(value)
    }
}
