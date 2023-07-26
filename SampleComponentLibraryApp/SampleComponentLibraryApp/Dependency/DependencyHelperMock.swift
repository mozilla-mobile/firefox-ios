// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

class DependencyHelperMock {
    func bootstrapDependencies() {
        AppContainer.shared.reset()

        let themeManager: ThemeManager = MockThemeManager()
        AppContainer.shared.register(service: themeManager)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()
    }

    func reset() {
        AppContainer.shared.reset()
    }
}
