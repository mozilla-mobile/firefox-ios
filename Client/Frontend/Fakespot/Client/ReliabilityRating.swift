// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

enum ReliabilityRating: String {
    case gradeA = "a"
    case gradeB = "b"
    case gradeC = "c"
    case gradeD = "d"
    case gradeF = "f"

    var letter: String {
        return self.rawValue.uppercased()
    }

    var description: String {
        switch self {
        case .gradeA, .gradeB: return .Shopping.ReliabilityRatingAB
        case .gradeC: return .Shopping.ReliabilityRatingC
        case .gradeD, .gradeF: return .Shopping.ReliabilityRatingDF
        }
    }

    func color(theme: Theme) -> UIColor {
        switch self {
        case .gradeA: return theme.colors.layerAccentPrivate // Update in FXIOS-7154
        case .gradeB: return theme.colors.layerAccentPrivateNonOpaque // Update in FXIOS-7154
        case .gradeC: return theme.colors.layerSepia // Update in FXIOS-7154
        case .gradeD: return theme.colors.layerAccentNonOpaque // Update in FXIOS-7154
        case .gradeF: return theme.colors.layer1 // Update in FXIOS-7154
        }
    }
}
