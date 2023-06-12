// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ToggleHistoryGroups: HiddenSetting, FeatureFlaggable {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureEnabled(.historyGroups, checking: .userOnly) ? "OFF" : "ON"
        return NSAttributedString(
            string: "Toggle history groups \(toNewStatus)",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let newStatus = !featureFlags.isFeatureEnabled(.historyGroups, checking: .userOnly)
        featureFlags.set(feature: .historyGroups, to: newStatus)
        updateCell(navigationController)
    }
}
