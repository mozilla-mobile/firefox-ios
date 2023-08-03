// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum ReliabilityRating: String {
    case a
    case b
    case c
    case d
    case f

    var letter: String {
        return self.rawValue.uppercased()
    }

    var description: String {
        switch self {
        case .a, .b: return .Shopping.ReliabilityRatingAB
        case .c: return .Shopping.ReliabilityRatingC
        case .d, .f: return .Shopping.ReliabilityRatingDF
        }
    }

    var color: UIColor {
        switch self {
        case .a: return UIColor(rgb: 0x10AD56)
        case .b: return UIColor(rgb: 0x007DEC)
        case .c: return UIColor(rgb: 0xF4A902)
        case .d: return UIColor(rgb: 0xF27313)
        case .f: return UIColor(rgb: 0xD51235)
        }
    }
}
