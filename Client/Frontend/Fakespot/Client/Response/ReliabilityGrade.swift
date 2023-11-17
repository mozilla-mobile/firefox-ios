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
        case .a: return theme.colors.layerRatingA
        case .b: return theme.colors.layerRatingB
        case .c: return theme.colors.layerRatingC
        case .d: return theme.colors.layerRatingD
        case .f: return theme.colors.layerRatingF
        }
    }

    func colorSubdued(theme: Theme) -> UIColor {
        switch self {
        case .a: return theme.colors.layerRatingASubdued
        case .b: return theme.colors.layerRatingBSubdued
        case .c: return theme.colors.layerRatingCSubdued
        case .d: return theme.colors.layerRatingDSubdued
        case .f: return theme.colors.layerRatingFSubdued
        }
    }
}
