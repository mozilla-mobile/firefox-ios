// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import StoreKit

struct UserConversionMetrics {
    private enum ConversionValue: Int {
        /// These conversion values just need to be larger than the onboarding events
        /// that can be as low as 1 or as high as 7.
        case newTab = 10
        case search = 11
    }

    func didOpenNewTab() {
        sendActivationEvent(conversionValue: .newTab)
    }

    func didPerformSearch() {
        sendActivationEvent(conversionValue: .search)
    }

    private func sendActivationEvent(conversionValue: ConversionValue) {
        let logger: Logger = DefaultLogger.shared
        /// Google ads only supports SKAN 3 so it will only interpret fine values.
        /// Setting the coarse value to low for now.
        let conversionValueUtil = ConversionValueUtil(fineValue: conversionValue.rawValue, coarseValue: .low, logger: logger)
        conversionValueUtil.adNetworkAttributionUpdateConversionEvent()
    }
}
