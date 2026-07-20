// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import PDFKit
import Shared
import UIKit
import WebKit

/// Collects the natively-available parts of the `broken-site-report` payload
/// from the device and the current tab, and captures a full-page screenshot.
/// Page-context values that need JavaScript (the `fastclick`/`marfeel`/`mobify`
/// framework flags) stay nil until FXIOS-16184 wires the page-context script.
@MainActor
enum WebCompatReportDataCollector {
    /// Fills the device- and tab-derived fields onto the given payload. The
    /// blocked-tracker list is only gathered when the user opted to include it.
    static func enrich(
        _ payload: WebCompatReportPayload,
        tab: Tab?,
        includeBlockedList: Bool
    ) -> WebCompatReportPayload {
        var payload = payload
        payload.languages = Locale.preferredLanguages
        payload.defaultLocales = Locale.preferredLanguages
        payload.isTablet = UIDevice.current.userInterfaceIdiom == .pad
        payload.memory = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024))
        payload.hasTouchScreen = true
        payload.defaultUseragentString = UserAgent.mobileUserAgent()

        guard let tab else { return payload }
        payload.devicePixelRatio = numberString(tab.webView?.traitCollection.displayScale ?? UIScreen.main.scale)
        payload.isPrivateBrowsing = tab.isPrivate
        let pageUserAgent = tab.webView?.customUserAgent
        payload.useragentString = (pageUserAgent?.isEmpty == false) ? pageUserAgent : UserAgent.mobileUserAgent()

        if let blocker = tab.contentBlocker {
            let isStrict = blocker.blockingStrengthPref == .strict
            payload.blockList = blocker.blockingStrengthPref.rawValue
            payload.etpCategory = isStrict ? "strict" : "standard"
            if includeBlockedList {
                payload.blockedOrigins = blocker.stats.domains.values.flatMap { $0 }.sorted()
            }
        }
        return payload
    }

    /// Captures the whole scrollable page as a tall image via `createPDF` (the
    /// same mechanism as "Save as PDF"). Calls back on the main thread with nil
    /// if there is no web view or the capture/render fails.
    static func captureFullPage(from tab: Tab?, completion: @escaping (UIImage?) -> Void) {
        guard let webView = tab?.webView else {
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
