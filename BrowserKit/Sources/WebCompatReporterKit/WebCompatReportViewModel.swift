// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The store-agnostic snapshot the `WebCompatReportSheetViewController` renders.
/// The Client maps `WebCompatReporterState` onto this so the package never
/// imports Redux; previews build one with a mock.
public struct WebCompatReportViewModel: Equatable, Sendable {
    /// A grouped section in the sheet's list. Later PRs (the issue picker, the
    /// URL/details/advanced fields) populate `rows`; the shell leaves it empty.
    public struct Section: Hashable, Sendable {
        public let id: String
        public let rows: [Row]

        public init(id: String, rows: [Row]) {
            self.id = id
            self.rows = rows
        }
    }

    public struct Row: Hashable, Sendable {
        public let id: String
        public let title: String

        public init(id: String, title: String) {
            self.id = id
            self.title = title
        }
    }

    public let navigationTitle: String
    public let closeButtonAccessibilityLabel: String
    public let previewButtonTitle: String
    public let isPreviewEnabled: Bool
    public let sections: [Section]

    public init(navigationTitle: String,
                closeButtonAccessibilityLabel: String,
                previewButtonTitle: String,
                isPreviewEnabled: Bool,
                sections: [Section] = []) {
        self.navigationTitle = navigationTitle
        self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
        self.previewButtonTitle = previewButtonTitle
        self.isPreviewEnabled = isPreviewEnabled
        self.sections = sections
    }
}
