// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

enum ReliabilityGrade: String, Codable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"

    var description: String {
        switch self {
        case .a, .b: return .Shopping.ReliabilityRatingAB
        case .c: return .Shopping.ReliabilityRatingC
        case .d, .f: return .Shopping.ReliabilityRatingDF
        }
    }

    func color(theme: Theme) -> UIColor {
        switch self {
        case .a: return theme.colors.layerAccentPrivate // Update in FXIOS-7154
        case .b: return theme.colors.layerAccentPrivateNonOpaque // Update in FXIOS-7154
        case .c: return theme.colors.layerSepia // Update in FXIOS-7154
        case .d: return theme.colors.layerAccentNonOpaque // Update in FXIOS-7154
        case .f: return theme.colors.layer1 // Update in FXIOS-7154
        }
    }
}
