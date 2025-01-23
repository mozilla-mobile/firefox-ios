// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
@testable import Client

class MockSearchEngineSelectionCoordinator: SearchEngineSelectionCoordinator {
    var navigateToSearchSettingsCalled = 0
    var dismissModalCalled = 0

    func navigateToSearchSettings(animated: Bool) {
        navigateToSearchSettingsCalled += 1
    }

    func dismissModal(animated: Bool) {
        dismissModalCalled += 1
    }
}
