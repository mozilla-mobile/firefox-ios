// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// One property per Glean metric in `broken_site_report.yaml`. The Report Preview
/// screen and the eventual submission (FXIOS-16185) both read from here, so field
/// names are written once rather than per screen.
///
/// Page-context data still needs FXIOS-16184, so those fields stay nil.
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

    /// Seeds the payload from the in-progress report: only what the user typed or
    /// picked, with everything gathered at send time left nil. The sub-option is
    /// the more specific answer, so it beats the category.
    static func make(from state: WebCompatReporterState) -> WebCompatReportPayload {
        var payload = WebCompatReportPayload()
        payload.url = state.url.isEmpty ? nil : state.url
        payload.breakageCategory = state.selectedSubOptionID ?? state.selectedCategory?.rawValue
        payload.description = state.additionalDetails.isEmpty ? nil : state.additionalDetails
        return payload
    }
}
