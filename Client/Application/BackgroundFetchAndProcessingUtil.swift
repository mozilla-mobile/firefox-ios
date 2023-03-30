// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import BackgroundTasks
import Common

protocol BackgroundUtilProtocol {
    func scheduleSyncOnAppBackground()
}

class BackgroundFetchAndProcessingUtil {
    private var backgroundUtils = [BackgroundUtilProtocol]()

    func registerUtil(_ util: BackgroundUtilProtocol) {
        backgroundUtils.append(util)
    }

    func scheduleOnAppBackground() {
        for util in backgroundUtils {
            util.scheduleSyncOnAppBackground()
        }
    }
}
