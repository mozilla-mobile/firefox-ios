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

    /// The tilted page card on the Report Preview screen. Figma has it at 150×180,
    /// 16pt corners, a 4pt border and a soft shadow, rotated 1.925° clockwise.
    enum Thumbnail {
        static let size = CGSize(width: 150, height: 180)
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 4
        static let tiltDegrees: CGFloat = 1.925
        /// `shadowDefault` already carries the Figma 12% alpha. Set this below 1 and
        /// the two multiply, which leaves the shadow invisible.
        static let shadowOpacity: Float = 1
        static let shadowRadius: CGFloat = 7
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let verticalPadding: CGFloat = 18
    }
}
