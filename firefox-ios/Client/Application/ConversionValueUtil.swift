// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import StoreKit

struct ConversionValueUtil {
    //  fineValue - An unsigned 6-bit value ≥0 and ≤63. The app or the ad network defines the meaning of the fine conversion value.
    //  coarseValue - An SKAdNetwork.CoarseConversionValue value of low, medium, or high. The app or the ad network defines the meaning of the coarse conversion value.

    var fineValue: Int
    var coarseValue: CoarseCoversionValue
    var logger: Logger

    enum CoarseCoversionValue {
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

    func adNetworkAttributionUpdateConversionEvent() {
        if #available(iOS 16.1, *) {
            SKAdNetwork.updatePostbackConversionValue(fineValue, coarseValue: coarseValue.value) { error in
                handleUpdateConversionInstallEvent(error: error)
            }
        } else if #available(iOS 15.4, *) {
            SKAdNetwork.updatePostbackConversionValue(fineValue) { error in
                handleUpdateConversionInstallEvent(error: error)
            }
        } else {
            SKAdNetwork.registerAppForAdNetworkAttribution()
        }
    }

    private func handleUpdateConversionInstallEvent(error: Error?) {
        if let error = error {
            logger.log("Postback Conversion Install Error",
                       level: .warning,
                       category: .setup,
                       description: "Update conversion value failed with error - \(error.localizedDescription)")
        } else {
            logger.log("Update install conversion success",
                       level: .debug,
                       category: .setup,
                       description: "Update conversion value was successful for Install Event")
        }
    }
}
