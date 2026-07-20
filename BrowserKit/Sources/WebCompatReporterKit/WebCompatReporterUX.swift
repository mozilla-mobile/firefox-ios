// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CoreGraphics

/// Layout constants for the WebCompat "Report a Website Issue" bottom sheet,
/// matching the iOS Figma source (Mobile Assembly File 2026, node 23608-71142).
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
        /// Roughly three lines tall; grows with typed content.
        static let minimumHeight: CGFloat = 88
    }

    /// The tilted page card on the Report Preview screen, matching the Figma
    /// (Report Preview: 150×180 card, 16pt corners, 4pt near-white frame, a soft
    /// #52525e @12% shadow, rotated 1.925° clockwise).
    enum Thumbnail {
        static let size = CGSize(width: 150, height: 180)
        static let cornerRadius: CGFloat = 16
        static let frameWidth: CGFloat = 4
        static let tiltDegrees: CGFloat = 1.925
        static let shadowOpacity: Float = 0.12
        static let shadowRadius: CGFloat = 7
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let verticalPadding: CGFloat = 18
    }
}
