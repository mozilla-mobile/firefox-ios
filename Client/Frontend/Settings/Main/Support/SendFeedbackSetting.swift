// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class SendFeedbackSetting: Setting {
    private weak var settingsDelegate: SupportSettingsDelegate?

    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsSendFeedback,
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "https://connect.mozilla.org/")
    }

    init(settingsDelegate: SupportSettingsDelegate?) {
        self.settingsDelegate = settingsDelegate
        super.init()
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.askedToOpen(url: url, withTitle: title)
            return
        }

        setUpAndPushSettingsContentViewController(navigationController, url)
    }
}
