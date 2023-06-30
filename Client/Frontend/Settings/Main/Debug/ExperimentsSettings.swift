// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ExperimentsSettings: HiddenSetting {
    private weak var settingsDelegate: DebugSettingsDelegate?

    override var title: NSAttributedString? { return NSAttributedString(string: "Experiments")}

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedExperiments()
        } else {
            navigationController?.pushViewController(ExperimentsViewController(), animated: true)
        }
    }
}
