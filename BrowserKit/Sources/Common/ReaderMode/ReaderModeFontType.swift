// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public enum ReaderModeFontType: String {
    case serif = "serif"
    case serifBold = "serif-bold"
    case sansSerif = "sans-serif"
    case sansSerifBold = "sans-serif-bold"

    public init(type: String) {
        let font = ReaderModeFontType(rawValue: type)
        let isBoldFontEnabled = UIAccessibility.isBoldTextEnabled

        switch font {
        case .serif,
                .serifBold:
            self = isBoldFontEnabled ? .serifBold : .serif
        case .sansSerif,
                .sansSerifBold:
            self = isBoldFontEnabled ? .sansSerifBold : .sansSerif
        case .none:
            self = .sansSerif
        }
    }

    public func isSameFamily(_ font: ReaderModeFontType) -> Bool {
        return FontFamily.families.contains(where: { $0.contains(font) && $0.contains(self) })
    }
}

private struct FontFamily {
    static let serifFamily = [ReaderModeFontType.serif, ReaderModeFontType.serifBold]
    static let sansFamily = [ReaderModeFontType.sansSerif, ReaderModeFontType.sansSerifBold]
    static let families = [serifFamily, sansFamily]
}
