// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

class RelayMaskSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    weak var parentCoordinator: BrowsingSettingsDelegate?

    init(profile: Profile, windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)
        self.profile = profile
        self.title = .RelayMask.RelayEmailMaskSettingsTitle
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func getDefaultBrowserSetting() -> [SettingSection] {
        let footerTitle = NSAttributedString(
            string: "wut")

        return [SettingSection(footerTitle: footerTitle,
                               children: [DefaultBrowserSetting(theme: themeManager.getCurrentTheme(for: windowUUID))])]
    }

    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        var showMaskSettings = [Setting]()
        var manageMasksSettings = [Setting]()
        if let profile {
            let theme = themeManager.getCurrentTheme(for: windowUUID)
            let showEmailMaskSuggestions = BoolSetting(
                prefs: profile.prefs,
                theme: theme,
                prefKey: PrefsKeys.ShowRelayMaskSuggestions,
                defaultValue: true,
                titleText: .RelayMask.RelayEmailMaskSuggestMasksToggle
            )

            showMaskSettings += [showEmailMaskSuggestions]
        }

        settings += [SettingSection(title: NSAttributedString(string: ""),
                                    footerTitle: NSAttributedString(string: .RelayMask.RelayEmailMaskSettingsDetailInfo),
                                    children: showMaskSettings),
                     SettingSection(title: NSAttributedString(string: ""),
                                    children: manageMasksSettings)]

        return settings
    }
}
