// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

class RelayMaskSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    init(profile: Profile, windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)
        self.profile = profile
        self.title = .RelayMask.RelayEmailMaskSettingsTitle
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func generateSettings() -> [SettingSection] {
        guard let profile else { return [] }
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let showEmailMaskSuggestions = BoolSetting(prefs: profile.prefs,
                                                   theme: theme,
                                                   prefKey: PrefsKeys.ShowRelayMaskSuggestions,
                                                   defaultValue: true,
                                                   titleText: .RelayMask.RelayEmailMaskSuggestMasksToggle)
        let manageMaskSetting = ManageRelayMasksSetting(theme: theme,
                                                        prefs: profile.prefs,
                                                        windowUUID: windowUUID,
                                                        navigationController: navigationController)

        return [SettingSection(footerTitle: NSAttributedString(string: .RelayMask.RelayEmailMaskSettingsDetailInfo),
                               children: [showEmailMaskSuggestions]),
                SettingSection(children: [manageMaskSetting])]
    }
}

final class ManageRelayMasksSetting: Setting {
    private let windowUUID: WindowUUID
    private let parentNav: UINavigationController?

    override var accessoryView: UIImageView? {
        let image = UIImage(named: StandardImageIdentifiers.Small.externalLink)
        return UIImageView(image: image)
    }

    override var accessibilityIdentifier: String? {
        return String.RelayMask.RelayEmailMaskSettingsManageEmailMasks
    }

    override var style: UITableViewCell.CellStyle { return .default }

    init(theme: Theme, prefs: Prefs, windowUUID: WindowUUID, navigationController: UINavigationController?) {
        self.parentNav = navigationController
        self.windowUUID = windowUUID
        let color = theme.colors.textPrimary
        let attributes = [NSAttributedString.Key.foregroundColor: color]
        super.init(title: NSAttributedString(string: String.RelayMask.RelayEmailMaskSettingsManageEmailMasks,
                                             attributes: attributes))
        self.theme = theme
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SettingsContentViewController(windowUUID: windowUUID)
        viewController.url = SupportUtils.URLForRelayAccountManagement
        parentNav?.pushViewController(viewController, animated: true)
    }
}
