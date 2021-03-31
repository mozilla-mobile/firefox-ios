/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

private let log = Logger.browserLogger

import Foundation

extension AppDelegate {
    func initializeExperiments() {
        let defaults = UserDefaults()
        let nimbusFirstRun = "NimbusFirstRun"
        let firstRun = defaults.object(forKey: nimbusFirstRun) != nil
        defaults.set(false, forKey: nimbusFirstRun)

        Experiments.intialize(with: nil, firstRun: firstRun)
    }
}
