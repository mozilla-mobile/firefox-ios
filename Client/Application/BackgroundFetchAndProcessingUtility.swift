// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import BackgroundTasks
import Common

protocol BackgroundUtilityProtocol {
    func scheduleTaskOnAppBackground()
}

class BackgroundFetchAndProcessingUtility {
    private var backgroundUtilities = [BackgroundUtilityProtocol]()

    func registerUtility(_ utility: BackgroundUtilityProtocol) {
        backgroundUtilities.append(utility)
    }

    func scheduleOnAppBackground() {
        for utility in backgroundUtilities {
            utility.scheduleTaskOnAppBackground()
        }
    }
}
