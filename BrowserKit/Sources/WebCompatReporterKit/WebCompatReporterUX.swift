// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CoreGraphics

/// Layout constants for the WebCompat "Report a Website Issue" bottom sheet.
enum WebCompatReporterUX {
    enum Spacing {
        static let screenHorizontal: CGFloat = 16
        static let sectionGap: CGFloat = 24
        static let rowVertical: CGFloat = 12
        static let interItem: CGFloat = 8
    }

    enum Card {
        static let cornerRadius: CGFloat = 16
        static let contentInset: CGFloat = 16
    }

    enum Sheet {
        static let cornerRadius: CGFloat = 24
    }

    enum Control {
        static let minimumTapTarget: CGFloat = 44
    }

    enum Chevron {
        static let size: CGFloat = 10
    }

    enum DetailsField {
        /// Visible lines before the text view scrolls internally. The box height is this many
        /// line heights of the body font, so it follows Dynamic Type without any recalculation.
        static let visibleLineCount = 4
    }

    enum Keyboard {
        static let focusPadding: CGFloat = 16
    }
}
