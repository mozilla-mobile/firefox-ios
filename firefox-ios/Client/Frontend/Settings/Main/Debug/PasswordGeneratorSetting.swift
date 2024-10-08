// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common
import Redux

class PasswordGeneratorSetting: HiddenSetting {
    private weak var settingsDelegate: DebugSettingsDelegate?
    private var windowUUID: WindowUUID

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate,
         windowUUID: WindowUUID) {
        self.settingsDelegate = settingsDelegate
        self.windowUUID = windowUUID
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        let buttonTitle = "Show Password Generator Prompt"
        return NSAttributedString(
            string: buttonTitle,
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settings.dismiss(animated: false)
        let newAction = GeneralBrowserAction(
            windowUUID: windowUUID,
            actionType: GeneralBrowserActionType.showPasswordGenerator)
        store.dispatch(newAction)
        settingsDelegate?.askedToReload()
    }
}
