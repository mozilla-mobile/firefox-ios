// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The store-agnostic snapshot the `WebCompatReportSheetViewController` renders.
/// The Client maps `WebCompatReporterState` onto this so the package never
/// imports Redux; previews build one with a mock.
public struct WebCompatReportViewModel: Equatable, Sendable {
    /// A list section, optionally preceded by a header title (e.g. "Site Issue").
    public struct Section: Hashable, Sendable {
        public let id: String
        public let title: String?
        public let rows: [Row]

        public init(id: String, title: String? = nil, rows: [Row]) {
            self.id = id
            self.title = title
            self.rows = rows
        }
    }

    public struct Row: Hashable, Sendable {
        /// A selectable entry in a `categoryMenu` pull-down. `id` is the opaque
        /// key the Client maps back to a category.
        public struct MenuOption: Hashable, Sendable {
            public let id: String
            public let title: String
            public let isSelected: Bool

            public init(id: String, title: String, isSelected: Bool) {
                self.id = id
                self.title = title
                self.isSelected = isSelected
            }
        }

        /// How a row renders in the list.
        public enum Kind: Hashable, Sendable {
            case plain
            case categoryMenu(isPlaceholder: Bool, options: [MenuOption])
            case subOption(isSelected: Bool)
            case urlField(text: String, placeholder: String)
            case detailsField(text: String, placeholder: String)
            case toggle(isOn: Bool)
        }

        public let id: String
        public let title: String
        public let kind: Kind
        public let a11yIdentifier: String

        public init(id: String, title: String, kind: Kind = .plain, a11yIdentifier: String) {
            self.id = id
            self.title = title
            self.kind = kind
            self.a11yIdentifier = a11yIdentifier
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
