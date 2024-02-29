// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// This class contains the Firefox iOS type styles as part of our design system
public struct FXFontStyles {
    public struct Regular {
        public static let largeTitle = TextStyling(for: .largeTitle, size: 34, weight: .regular)
        public static let title1 = TextStyling(for: .title1, size: 28, weight: .regular)
        public static let title2 = TextStyling(for: .title2, size: 22, weight: .regular)
        public static let title3 = TextStyling(for: .title3, size: 20, weight: .regular)
        public static let headline = TextStyling(for: .headline, size: 17, weight: .semibold)
        public static let body = TextStyling(for: .body, size: 17, weight: .regular)
        public static let callout = TextStyling(for: .callout, size: 16, weight: .regular)
        public static let subheadline = TextStyling(for: .subheadline, size: 15, weight: .regular)
        public static let footnote = TextStyling(for: .footnote, size: 13, weight: .regular)
        public static let caption1 = TextStyling(for: .caption1, size: 12, weight: .regular)
        public static let caption2 = TextStyling(for: .caption2, size: 11, weight: .regular)
    }

    public struct Bold {
        public static let largeTitle = TextStyling(for: .largeTitle, size: 34, weight: .bold)
        public static let title1 = TextStyling(for: .title1, size: 28, weight: .bold)
        public static let title2 = TextStyling(for: .title2, size: 22, weight: .bold)
        public static let title3 = TextStyling(for: .title3, size: 20, weight: .semibold)
        public static let headline = TextStyling(for: .headline, size: 17, weight: .semibold)
        public static let body = TextStyling(for: .body, size: 17, weight: .semibold)
        public static let callout = TextStyling(for: .callout, size: 16, weight: .semibold)
        public static let subheadline = TextStyling(for: .subheadline, size: 15, weight: .semibold)
        public static let footnote = TextStyling(for: .footnote, size: 13, weight: .semibold)
        public static let caption1 = TextStyling(for: .caption1, size: 12, weight: .medium)
        public static let caption2 = TextStyling(for: .caption2, size: 11, weight: .semibold)
    }
}
