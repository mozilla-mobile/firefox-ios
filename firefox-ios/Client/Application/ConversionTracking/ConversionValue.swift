// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import StoreKit

struct ConversionValue {
    //  fineValue - An unsigned 6-bit value ≥0 and ≤63. The app or the ad network
    //              defines the meaning of the fine conversion value.
    //  coarseValue - An SKAdNetwork.CoarseConversionValue value of low, medium, or high.
    //                The app or the ad network defines the meaning of the coarse conversion value.
    //  lockWindow - Signals to SKAdNetwork that no further updates are expected in the
    //               current conversion window, allowing the postback to be scheduled sooner.

    var fine: Int
    var coarse: CoarseConversionValue
    var lockWindow = false

    enum CoarseConversionValue {
        case low
        case medium
        case high

        @available(iOS 16.1, *)
        var value: SKAdNetwork.CoarseConversionValue {
            switch self {
            case .low:
                return .low
            case .medium:
                return .medium
            case .high:
                return .high
            }
        }
    }
}
