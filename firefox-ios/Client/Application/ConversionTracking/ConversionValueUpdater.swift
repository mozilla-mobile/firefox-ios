// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import StoreKit

protocol ConversionValueUpdater {
    func update(conversionValue: ConversionValue)
}

struct SKAdNetworkUpdater: ConversionValueUpdater {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    func update(conversionValue: ConversionValue) {
        if #available(iOS 16.1, *) {
            SKAdNetwork.updatePostbackConversionValue(
                conversionValue.fine,
                coarseValue: conversionValue.coarse.value,
                lockWindow: conversionValue.lockWindow
            ) { error in
                log(with: error)
            }
        } else if #available(iOS 15.4, *) {
            SKAdNetwork.updatePostbackConversionValue(conversionValue.fine) { error in
                self.log(with: error)
            }
        } else {
            SKAdNetwork.registerAppForAdNetworkAttribution()
        }
    }

    private func log(with error: Error?) {
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
