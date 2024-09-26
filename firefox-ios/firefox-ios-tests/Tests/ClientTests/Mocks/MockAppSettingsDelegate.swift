// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

@testable import Client

class MockDebugSettingsDelegate: DebugSettingsDelegate {
    var pressedVersionCalled = 0
    var pressedShowTourCalled = 0
    var pressedExperimentsCalled = 0
    var askedToShowAlertCalled = 0
    var askedToReloadCalled = 0

    func pressedVersion() {
        pressedVersionCalled += 1
    }

    func pressedShowTour() {
        pressedShowTourCalled += 1
    }

    func pressedExperiments() {
        pressedExperimentsCalled += 1
    }

    func pressedFirefoxSuggest() {}

    func pressedRemoteSettingsOption() {}

    func pressedOpenFiftyTabs() {}

    func pressedDebugFeatureFlags() {}

    func askedToShow(alert: AlertController) {
        askedToShowAlertCalled += 1
    }

    func askedToReload() {
        askedToReloadCalled += 1
    }
}
