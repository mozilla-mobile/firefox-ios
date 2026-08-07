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
        static let largeCornerRadius: CGFloat = 26
        static let verticalInset: CGFloat = 14.5
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

    /// The plain-language Report Preview screen.
    enum Preview {
        static let cardScreenInset: CGFloat = 24
        /// Drawn rather than typed: the `•` glyph renders under half this at footnote size.
        static let bulletDiameter: CGFloat = 6
        /// Where the text starts, so wrapped lines hang off it rather than the dot.
        static let bulletIndent: CGFloat = 24
        static let thumbnailGap: CGFloat = 32
    }

    /// The tilted page card on the Report Preview screen.
    enum Thumbnail {
        static let size = CGSize(width: 115, height: 138)
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 4
        static let tiltDegrees: CGFloat = 1.925
        static let verticalPadding: CGFloat = 18
        /// Clears the nav bar, so the tilt has room above it.
        static let topInset: CGFloat = 24
    }
}
