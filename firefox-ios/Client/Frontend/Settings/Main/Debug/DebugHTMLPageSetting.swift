// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

class DebugHTMLPageSetting: HiddenSetting {
    override var accessibilityIdentifier: String? { return "DebugHTMLPage.Setting" }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Debug HTML Page",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let profile = settings.profile else { return }
        let viewController = DebugHTMLPageViewController(profile: profile,
                                                         tabManager: settings.tabManager,
                                                         windowUUID: settings.windowUUID)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
