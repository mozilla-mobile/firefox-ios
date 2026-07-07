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
}
