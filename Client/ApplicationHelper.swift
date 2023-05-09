// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol ApplicationHelper {
    func openSettings()
    func open(_ url: URL)
}

/// UIApplication.shared wrapper
struct DefaultApplicationHelper: ApplicationHelper {
    func openSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
    }

    func open(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
