// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebCompatReporterKit

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

    /// One preview line: its Glean metric key and a typed value (rendered by the
    /// preview's view layer, so the model never hand-builds display strings).
    struct Field: Equatable {
        let key: String
        let value: WebCompatReportPreviewViewModel.PreviewValue
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
    /// the Glean metric names; values are typed (`.null` when not collected) and
    /// rendered by the preview's view layer.
    var previewGroups: [Group] {
        return [
            Group(title: "basic", fields: [
                Field(key: "url", value: Self.value(url)),
                Field(key: "breakage_category", value: Self.value(breakageCategory)),
                Field(key: "description", value: Self.value(description))
            ]),
            Group(title: "tabInfo", fields: [
                Field(key: "languages", value: Self.value(languages)),
                Field(key: "useragent_string", value: Self.value(useragentString))
            ]),
            Group(title: "antitracking", fields: [
                Field(key: "block_list", value: Self.value(blockList)),
                Field(key: "blocked_origins", value: Self.value(blockedOrigins)),
                Field(key: "etp_category", value: Self.value(etpCategory)),
                Field(key: "is_private_browsing", value: Self.value(isPrivateBrowsing))
            ]),
            Group(title: "frameworks", fields: [
                Field(key: "fastclick", value: Self.value(fastclick)),
                Field(key: "marfeel", value: Self.value(marfeel)),
                Field(key: "mobify", value: Self.value(mobify))
            ]),
            Group(title: "app", fields: [
                Field(key: "default_locales", value: Self.value(defaultLocales)),
                Field(key: "default_useragent_string", value: Self.value(defaultUseragentString))
            ]),
            Group(title: "graphics", fields: [
                Field(key: "device_pixel_ratio", value: Self.value(devicePixelRatio)),
                Field(key: "has_touch_screen", value: Self.value(hasTouchScreen))
            ]),
            Group(title: "system", fields: [
                Field(key: "is_tablet", value: Self.value(isTablet)),
                Field(key: "memory", value: Self.value(memory))
            ])
        ]
    }

    private static func value(_ value: String?) -> WebCompatReportPreviewViewModel.PreviewValue {
        return value.map { .string($0) } ?? .null
    }

    private static func value(_ value: [String]?) -> WebCompatReportPreviewViewModel.PreviewValue {
        return value.map { .list($0) } ?? .null
    }

    private static func value(_ value: Bool?) -> WebCompatReportPreviewViewModel.PreviewValue {
        return value.map { .bool($0) } ?? .null
    }

    private static func value(_ value: Int?) -> WebCompatReportPreviewViewModel.PreviewValue {
        return value.map { .quantity($0) } ?? .null
    }
}
