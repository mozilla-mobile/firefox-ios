// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The store-agnostic snapshot the `WebCompatReportPreviewViewController` renders.
/// The Client maps `WebCompatReporterState` (plus device/tab data collected at
/// send time) onto this so the package never imports Redux; previews build one
/// with a mock. Labels and values are the raw Glean `broken_site_report` keys and
/// their JSON-formatted values (plain-language copy follows in a later PR).
public struct WebCompatReportPreviewViewModel: Equatable, Sendable {
    /// A single line inside a section: a raw payload key and its JSON value,
    /// e.g. label "breakage_category", value "\"media\"".
    public struct PreviewRow: Hashable, Sendable {
        public let id: String
        public let label: String
        public let value: String

        public init(id: String, label: String, value: String) {
            self.id = id
            self.label = label
            self.value = value
        }
    }

    /// A collapsible group of report data keyed by its payload group, e.g.
    /// "basic", "tabInfo", "antitracking".
    public struct PreviewSection: Hashable, Sendable {
        public let id: String
        public let title: String
        public let rows: [PreviewRow]

        public init(id: String, title: String, rows: [PreviewRow]) {
            self.id = id
            self.title = title
            self.rows = rows
        }
    }

    public let title: String
    public let closeAccessibilityLabel: String
    public let screenshotAccessibilityLabel: String
    /// The captured page image, shown as a tappable thumbnail. Nil until the
    /// screenshot capture pipeline lands; the thumbnail is hidden while nil.
    public let screenshot: UIImage?
    public let sections: [PreviewSection]

    public init(
        title: String,
        closeAccessibilityLabel: String,
        screenshotAccessibilityLabel: String,
        screenshot: UIImage? = nil,
        sections: [PreviewSection] = []
    ) {
        self.title = title
        self.closeAccessibilityLabel = closeAccessibilityLabel
        self.screenshotAccessibilityLabel = screenshotAccessibilityLabel
        self.screenshot = screenshot
        self.sections = sections
    }

    /// Returns a copy carrying the given captured screenshot. The Client builds
    /// the view model from Redux state (which has no image) and the coordinator
    /// attaches the current tab's screenshot before presenting.
    public func withScreenshot(_ image: UIImage?) -> WebCompatReportPreviewViewModel {
        return WebCompatReportPreviewViewModel(
            title: title,
            closeAccessibilityLabel: closeAccessibilityLabel,
            screenshotAccessibilityLabel: screenshotAccessibilityLabel,
            screenshot: image,
            sections: sections
        )
    }

    // `UIImage` isn't `Equatable`, so the screenshot is compared by identity.
    public static func == (lhs: WebCompatReportPreviewViewModel, rhs: WebCompatReportPreviewViewModel) -> Bool {
        return lhs.title == rhs.title
            && lhs.closeAccessibilityLabel == rhs.closeAccessibilityLabel
            && lhs.screenshotAccessibilityLabel == rhs.screenshotAccessibilityLabel
            && lhs.sections == rhs.sections
            && lhs.screenshot === rhs.screenshot
    }
}
