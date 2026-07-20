// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import PDFKit
import Shared
import UIKit
import WebKit

/// Device- and process-level values that feed the `broken-site-report` payload.
/// Abstracted behind a protocol so the field mapping can be unit-tested with a
/// fake, instead of reading `UIDevice`/`ProcessInfo`/`UIScreen`/`Locale` statics.
protocol WebCompatDeviceInfoProviding {
    var preferredLanguages: [String] { get }
    var isTablet: Bool { get }
    var physicalMemoryMegabytes: Int { get }
    var defaultUserAgent: String { get }
    var displayScale: CGFloat { get }
}

/// The production provider, reading the live device and process statics.
struct WebCompatDeviceInfoProvider: WebCompatDeviceInfoProviding {
    var preferredLanguages: [String] { Locale.preferredLanguages }
    var isTablet: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    var physicalMemoryMegabytes: Int { Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024)) }
    var defaultUserAgent: String { UserAgent.mobileUserAgent() }
    var displayScale: CGFloat { UIScreen.main.scale }
}

/// The tab-derived inputs to the payload mapping, flattened to a plain value type
/// so tests can build one directly without a live `Tab`/`WKWebView`. A nil
/// `blockingStrength` means the tab has no content blocker; `blockedOrigins` is
/// only populated when the user opted to include the blocked-tracker list.
struct WebCompatTabSnapshot: Equatable {
    var isPrivate: Bool
    var pageUserAgent: String?
    var displayScale: CGFloat?
    var blockingStrength: BlockingStrength?
    var blockedOrigins: [String]?
}

/// Collects the natively-available parts of the `broken-site-report` payload
/// from the device and the current tab, and captures a full-page screenshot.
/// Page-context values that need JavaScript (the `fastclick`/`marfeel`/`mobify`
/// framework flags) stay nil until FXIOS-16184 wires the page-context script.
@MainActor
enum WebCompatReportDataCollector {
    /// Fills the device- and tab-derived fields onto the given payload by reading
    /// the tab, building a snapshot, and delegating to the pure mapping. The
    /// blocked-tracker list is only gathered when the user opted to include it.
    static func enrich(
        _ payload: WebCompatReportPayload,
        tab: Tab,
        includeBlockedList: Bool,
        device: WebCompatDeviceInfoProviding = WebCompatDeviceInfoProvider()
    ) -> WebCompatReportPayload {
        return enrich(payload, device: device, tab: makeSnapshot(from: tab, includeBlockedList: includeBlockedList))
    }

    /// The pure field mapping — no UIKit, no `Tab` — over injected device values
    /// and a tab snapshot. Unit-testable with fakes.
    static func enrich(
        _ payload: WebCompatReportPayload,
        device: WebCompatDeviceInfoProviding,
        tab: WebCompatTabSnapshot
    ) -> WebCompatReportPayload {
        var payload = payload
        payload.languages = device.preferredLanguages
        payload.defaultLocales = device.preferredLanguages
        payload.isTablet = device.isTablet
        payload.memory = device.physicalMemoryMegabytes
        payload.hasTouchScreen = true
        payload.defaultUseragentString = device.defaultUserAgent

        let pageUserAgent = tab.pageUserAgent
        payload.useragentString = (pageUserAgent?.isEmpty == false) ? pageUserAgent : device.defaultUserAgent
        payload.devicePixelRatio = numberString(tab.displayScale ?? device.displayScale)
        payload.isPrivateBrowsing = tab.isPrivate

        if let blockingStrength = tab.blockingStrength {
            payload.blockList = blockingStrength.rawValue
            payload.etpCategory = blockingStrength == .strict ? "strict" : "standard"
            payload.blockedOrigins = tab.blockedOrigins
        }
        return payload
    }

    /// Captures the whole scrollable page as a tall image via `createPDF` (the
    /// same mechanism as "Save as PDF"). Calls back on the main thread with nil
    /// if there is no web view or the capture/render fails.
    static func captureFullPage(from tab: Tab, completion: @escaping (UIImage?) -> Void) {
        guard let webView = tab.webView else {
            completion(nil)
            return
        }
        webView.createPDF { result in
            switch result {
            case .success(let data):
                completion(image(fromPDF: data))
            case .failure:
                completion(nil)
            }
        }
    }

    private static func makeSnapshot(from tab: Tab, includeBlockedList: Bool) -> WebCompatTabSnapshot {
        let blocker = tab.contentBlocker
        var blockedOrigins: [String]?
        if includeBlockedList, let blocker {
            blockedOrigins = blocker.stats.domains.values.flatMap { $0 }.sorted()
        }
        return WebCompatTabSnapshot(
            isPrivate: tab.isPrivate,
            pageUserAgent: tab.webView?.customUserAgent,
            displayScale: tab.webView?.traitCollection.displayScale,
            blockingStrength: blocker?.blockingStrengthPref,
            blockedOrigins: blockedOrigins
        )
    }

    private static func image(fromPDF data: Data) -> UIImage? {
        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        // Tall full pages can be huge; render at scale 1 to keep memory sane.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        return renderer.image { context in
            UIColor.white.set()
            context.fill(bounds)
            context.cgContext.translateBy(x: 0, y: bounds.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }

    private static func numberString(_ value: CGFloat) -> String {
        return String(format: "%g", value)
    }
}
