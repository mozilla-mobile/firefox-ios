// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

// This will add a secret setting for a shorter timeout option
// for Terms Of Use, adding default(120 hours) and one minute options
enum TermsOfUseTimeoutOption: Int {
    case normal
    case oneMinute

    var nextOption: TermsOfUseTimeoutOption {
        switch self {
        case .normal:
            return .oneMinute
        case .oneMinute:
            return .normal
        }
    }

    var title: String {
        switch self {
        case .normal:
            return "120 hours"
        case .oneMinute:
            return "one minute"
        }
    }
}

class TermsOfUseTimeout: HiddenSetting {
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        let rawValue = UserDefaults.standard.integer(forKey: PrefsKeys.FasterTermsOfUseTimeoutOverride)
        let touTimeoutOption = TermsOfUseTimeoutOption(rawValue: rawValue) ?? .normal

        let buttonTitle = "Set ToU Timeout (current is \(touTimeoutOption.title))"
        return NSAttributedString(
            string: buttonTitle,
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let rawValue = UserDefaults.standard.integer(forKey: PrefsKeys.FasterTermsOfUseTimeoutOverride)
        let touTimeoutOption = TermsOfUseTimeoutOption(rawValue: rawValue) ?? .normal

        UserDefaults.standard.set(touTimeoutOption.nextOption.rawValue, forKey: PrefsKeys.FasterTermsOfUseTimeoutOverride)
        settingsDelegate?.askedToReload()
    }
}
