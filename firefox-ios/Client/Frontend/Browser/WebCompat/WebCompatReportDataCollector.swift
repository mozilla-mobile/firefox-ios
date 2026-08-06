// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import PDFKit
import Shared
import UIKit
import WebKit

/// Device and process values, behind a protocol so tests can fake the
/// `UIDevice`/`ProcessInfo`/`Locale` statics.
protocol WebCompatDeviceInfoProviding {
    var preferredLanguages: [String] { get }
    var isTablet: Bool { get }
    var physicalMemoryMegabytes: Int { get }
    var defaultUserAgent: String { get }
    var displayScale: CGFloat { get }
}

struct WebCompatDeviceInfoProvider: WebCompatDeviceInfoProviding {
    var preferredLanguages: [String] { Locale.preferredLanguages }
    var isTablet: Bool { UIDeviceDetails.userInterfaceIdiom == .pad }
    var physicalMemoryMegabytes: Int { Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024)) }
    /// Desktop User Agent on iPad, which is what the app actually sends.
    var defaultUserAgent: String { UserAgent.getUserAgent() }
    var displayScale: CGFloat { UITraitCollection.current.displayScale }
}

/// Tab inputs as a plain value, so tests don't need a live `Tab`/`WKWebView`. Nil
/// `blockingStrength` means no content blocker; `blockedOrigins` is filled only on opt-in.
struct WebCompatTabSnapshot: Equatable {
    var isPrivate: Bool?
    var pageUserAgent: String?
    var displayScale: CGFloat?
    var blockingStrength: BlockingStrength?
    var blockedOrigins: [String]?
}

/// Fills the `broken-site-report` fields readable natively, plus the page screenshot.
/// The `fastclick`/`marfeel`/`mobify` flags need JavaScript, so they stay nil until FXIOS-16184.
enum WebCompatReportDataCollector {
    /// Reads the tab into a snapshot and hands off to the pure mapping below.
    @MainActor
    static func enrich(
        _ payload: WebCompatReportPayload,
        tab: Tab,
        includeBlockedList: Bool,
        includeTabSpecificInfo: Bool = true,
        device: WebCompatDeviceInfoProviding = WebCompatDeviceInfoProvider()
    ) -> WebCompatReportPayload {
        let snapshot = makeSnapshot(
            from: tab,
            includeBlockedList: includeBlockedList,
            includeTabSpecificInfo: includeTabSpecificInfo
        )
        return enrich(payload, device: device, tab: snapshot)
    }

    /// Pure mapping: no UIKit, no `Tab`, so tests can drive it with fakes.
    static func enrich(
        _ payload: WebCompatReportPayload,
        device: WebCompatDeviceInfoProviding,
        tab: WebCompatTabSnapshot
    ) -> WebCompatReportPayload {
        var payload = payload
        // `languages` is the page's navigator.languages (FXIOS-16184); only
        // `defaultLocales` is an app-level list.
        payload.defaultLocales = device.preferredLanguages
        payload.isTablet = device.isTablet
        payload.memory = device.physicalMemoryMegabytes
        payload.hasTouchScreen = true
        payload.defaultUserAgentString = device.defaultUserAgent

        payload.userAgentString = tab.pageUserAgent.flatMap { $0.isEmpty ? nil : $0 }
        // An off-screen web view reports a display scale of 0, not nil.
        let pageScale = tab.displayScale ?? 0
        payload.devicePixelRatio = String(format: "%g", pageScale > 0 ? pageScale : device.displayScale)
        payload.isPrivateBrowsing = tab.isPrivate

        if let blockingStrength = tab.blockingStrength {
            payload.blockList = blockingStrength.rawValue
            payload.etpCategory = etpCategory(for: blockingStrength)
            payload.blockedOrigins = tab.blockedOrigins
        }
        return payload
    }

    /// Blocked trackers, or nil without opt-in. Kept out of `makeSnapshot` so the
    /// opt-out is testable without a live `Tab`.
    static func blockedOrigins(from stats: TPPageStats, includeBlockedList: Bool) -> [String]? {
        guard includeBlockedList else { return nil }
        return Set(stats.domains.values.flatMap { $0 }).sorted()
    }

    /// The page as one tall image, via the same PDF route as Save as PDF. WebKit
    /// paginates tall content and only page one is rendered, so anything past
    /// ~14400pt is cut. Nil if there's no web view or the capture fails.
    @MainActor
    static func captureFullPage(
        from tab: Tab,
        logger: Logger = DefaultLogger.shared
    ) async -> UIImage? {
        guard let webView = tab.webView else {
            logger.log("WebCompat screenshot skipped: tab has no web view", level: .warning, category: .webview)
            return nil
        }
        do {
            let data = try await webView.pdf()
            if let document = PDFDocument(data: data), document.pageCount > 1 {
                logger.log(
                    "WebCompat screenshot truncated to the first of \(document.pageCount) PDF pages",
                    level: .warning,
                    category: .webview
                )
            }
            // Scale 1: at native scale a full-page bitmap runs to hundreds of MB.
            guard let image = UIImage.imageFromPDF(data: data, scale: 1, backgroundColor: .white) else {
                logger.log("WebCompat screenshot failed: could not render the PDF", level: .warning, category: .webview)
                return nil
            }
            return image
        } catch {
            logger.log(
                "WebCompat screenshot failed: \(error.localizedDescription)",
                level: .warning,
                category: .webview
            )
            return nil
        }
    }

    /// Not `block_list`'s basic/strict: this is the cross-platform standard/strict vocabulary.
    private static func etpCategory(for blockingStrength: BlockingStrength) -> String {
        switch blockingStrength {
        case .basic: return "standard"
        case .strict: return "strict"
        }
    }

    @MainActor
    private static func makeSnapshot(
        from tab: Tab,
        includeBlockedList: Bool,
        includeTabSpecificInfo: Bool
    ) -> WebCompatTabSnapshot {
        guard includeTabSpecificInfo else { return WebCompatTabSnapshot() }
        let blocker = tab.contentBlocker
        return WebCompatTabSnapshot(
            isPrivate: tab.isPrivate,
            pageUserAgent: tab.webView?.customUserAgent,
            displayScale: tab.webView?.traitCollection.displayScale,
            blockingStrength: blocker?.blockingStrengthPref,
            blockedOrigins: blocker.flatMap { blockedOrigins(from: $0.stats, includeBlockedList: includeBlockedList) }
        )
    }
}
