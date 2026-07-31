// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean

struct WebCompatReportRecorder {
    private let gleanWrapper: GleanWrapper
    private let logger: Logger

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
         logger: Logger = DefaultLogger.shared) {
        self.gleanWrapper = gleanWrapper
        self.logger = logger
    }

    func submit(_ payload: WebCompatReportPayload) {
        recordBasic(payload)
        recordTabInfo(payload)
        recordAntitracking(payload)
        recordFrameworks(payload)
        recordBrowserInfo(payload)
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.brokenSiteReport)
    }

    private func recordBasic(_ payload: WebCompatReportPayload) {
        // `URL(string:)` accepts scheme-less input like "asdf", so parseability is not enough.
        if let urlString = payload.url {
            if let url = URL(string: urlString), url.scheme != nil, url.host != nil {
                gleanWrapper.recordUrl(for: GleanMetrics.BrokenSiteReport.url, value: url)
            } else {
                logger.log("WebCompat report URL is not an absolute URL, omitting it from the ping",
                           level: .warning,
                           category: .webview)
            }
        }
        if let breakageCategory = payload.breakageCategory {
            gleanWrapper.recordString(for: GleanMetrics.BrokenSiteReport.breakageCategory,
                                      value: breakageCategory)
        }
        if let description = payload.description {
            gleanWrapper.recordText(for: GleanMetrics.BrokenSiteReport.description, value: description)
        }
    }

    private func recordTabInfo(_ payload: WebCompatReportPayload) {
        if let languages = payload.languages {
            gleanWrapper.recordStringList(for: GleanMetrics.BrokenSiteReportTabInfo.languages,
                                          value: languages)
        }
        if let userAgentString = payload.userAgentString {
            gleanWrapper.recordText(for: GleanMetrics.BrokenSiteReportTabInfo.useragentString,
                                    value: userAgentString)
        }
    }

    private func recordAntitracking(_ payload: WebCompatReportPayload) {
        if let blockList = payload.blockList {
            gleanWrapper.recordString(for: GleanMetrics.BrokenSiteReportTabInfoAntitracking.blockList,
                                      value: blockList)
        }
        if let blockedOrigins = payload.blockedOrigins {
            gleanWrapper.recordStringList(for: GleanMetrics.BrokenSiteReportTabInfoAntitracking.blockedOrigins,
                                          value: blockedOrigins)
        }
        if let etpCategory = payload.etpCategory {
            gleanWrapper.recordString(for: GleanMetrics.BrokenSiteReportTabInfoAntitracking.etpCategory,
                                      value: etpCategory)
        }
        if let isPrivateBrowsing = payload.isPrivateBrowsing {
            gleanWrapper.setBoolean(for: GleanMetrics.BrokenSiteReportTabInfoAntitracking.isPrivateBrowsing,
                                    value: isPrivateBrowsing)
        }
    }

    private func recordFrameworks(_ payload: WebCompatReportPayload) {
        if let fastclick = payload.fastclick {
            gleanWrapper.setBoolean(for: GleanMetrics.BrokenSiteReportTabInfoFrameworks.fastclick,
                                    value: fastclick)
        }
        if let marfeel = payload.marfeel {
            gleanWrapper.setBoolean(for: GleanMetrics.BrokenSiteReportTabInfoFrameworks.marfeel,
                                    value: marfeel)
        }
        if let mobify = payload.mobify {
            gleanWrapper.setBoolean(for: GleanMetrics.BrokenSiteReportTabInfoFrameworks.mobify,
                                    value: mobify)
        }
    }

    private func recordBrowserInfo(_ payload: WebCompatReportPayload) {
        if let defaultLocales = payload.defaultLocales {
            gleanWrapper.recordStringList(for: GleanMetrics.BrokenSiteReportBrowserInfoApp.defaultLocales,
                                          value: defaultLocales)
        }
        if let defaultUserAgentString = payload.defaultUserAgentString {
            gleanWrapper.recordText(for: GleanMetrics.BrokenSiteReportBrowserInfoApp.defaultUseragentString,
                                    value: defaultUserAgentString)
        }
        if let devicePixelRatio = payload.devicePixelRatio {
            gleanWrapper.recordString(for: GleanMetrics.BrokenSiteReportBrowserInfoGraphics.devicePixelRatio,
                                      value: devicePixelRatio)
        }
        if let hasTouchScreen = payload.hasTouchScreen {
            gleanWrapper.setBoolean(for: GleanMetrics.BrokenSiteReportBrowserInfoGraphics.hasTouchScreen,
                                    value: hasTouchScreen)
        }
        if let isTablet = payload.isTablet {
            gleanWrapper.setBoolean(for: GleanMetrics.BrokenSiteReportBrowserInfoSystem.isTablet,
                                    value: isTablet)
        }
        if let memory = payload.memory {
            gleanWrapper.recordQuantity(for: GleanMetrics.BrokenSiteReportBrowserInfoSystem.memory,
                                        value: Int64(memory))
        }
    }
}
