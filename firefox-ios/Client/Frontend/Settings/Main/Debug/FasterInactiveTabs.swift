// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum FasterInactiveTabsOption: Int {
    case normal
    case tenSeconds
    case oneMinute
    case twoMinutes

    var nextOption: FasterInactiveTabsOption {
        switch self {
        case .normal:
            return .tenSeconds
        case .tenSeconds:
            return .oneMinute
        case .oneMinute:
            return .twoMinutes
        case .twoMinutes:
            return .normal
        }
    }

    var title: String {
        switch self {
        case .normal:
            return "default"
        case .tenSeconds:
            return "ten seconds"
        case .oneMinute:
            return "one minute"
        case .twoMinutes:
            return "two minutes"
        }
    }
}

class FasterInactiveTabs: HiddenSetting {
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        let rawValue = UserDefaults.standard.integer(forKey: PrefsKeys.FasterInactiveTabsOverride)
        let fasterInactiveTabOption = FasterInactiveTabsOption(rawValue: rawValue) ?? .normal

        let buttonTitle = "Set Inactive Tab Timeout (\(fasterInactiveTabOption.title))"
        return NSAttributedString(
            string: buttonTitle,
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let rawValue = UserDefaults.standard.integer(forKey: PrefsKeys.FasterInactiveTabsOverride)
        let fasterInactiveTabOption = FasterInactiveTabsOption(rawValue: rawValue) ?? .normal

        UserDefaults.standard.set(fasterInactiveTabOption.nextOption.rawValue, forKey: PrefsKeys.FasterInactiveTabsOverride)
        settingsDelegate?.askedToReload()
    }
}
