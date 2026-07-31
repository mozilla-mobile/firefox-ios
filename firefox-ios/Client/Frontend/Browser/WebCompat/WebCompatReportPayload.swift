// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// One property per Glean metric in `broken_site_report.yaml`, so the field names
/// live in one place. The struct is flat; each comment below is the Glean category
/// the fields under it belong to. Page-context fields stay nil until FXIOS-16184.
struct WebCompatReportPayload: Equatable {
    // broken_site_report
    var url: String?
    var breakageCategory: String?
    var description: String?
    // broken_site_report.tab_info
    var languages: [String]?
    var userAgentString: String?
    // broken_site_report.tab_info.antitracking
    var blockList: String?
    var blockedOrigins: [String]?
    var etpCategory: String?
    var isPrivateBrowsing: Bool?
    // broken_site_report.tab_info.frameworks
    var fastclick: Bool?
    var marfeel: Bool?
    var mobify: Bool?
    // broken_site_report.browser_info.app
    var defaultLocales: [String]?
    var defaultUserAgentString: String?
    // broken_site_report.browser_info.graphics
    var devicePixelRatio: String?
    var hasTouchScreen: Bool?
    // broken_site_report.browser_info.system
    var isTablet: Bool?
    var memory: Int?

    /// Only what the user typed or picked; send-time data stays nil. The sub-option
    /// wins over the category as the more specific answer.
    static func make(from state: WebCompatReporterState) -> WebCompatReportPayload {
        var payload = WebCompatReportPayload()
        payload.url = state.url.isEmpty ? nil : state.url
        payload.breakageCategory = state.selectedSubOptionID ?? state.selectedCategory?.rawValue
        let details = state.additionalDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        payload.description = details.isEmpty ? nil : details
        return payload
    }
}
