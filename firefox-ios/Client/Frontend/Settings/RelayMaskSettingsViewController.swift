// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import ComponentLibrary

class RelayMaskSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    private lazy var linkButton: LinkButton = .build()

    private struct UX {
        static let buttonContentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
    }

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

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let _defaultFooter = super.tableView(
            tableView,
            viewForFooterInSection: section
        ) as? ThemedTableSectionHeaderFooterView
        guard let defaultFooter = _defaultFooter else { return nil }

        if section == 0 {
            let linkButtonViewModel = LinkButtonViewModel(
                title: String.RelayMask.RelayEmailMaskSettingsLearnMore,
                a11yIdentifier: String.RelayMask.RelayEmailMaskSettingsLearnMore,
                font: FXFontStyles.Regular.caption1.scaledFont(),
                contentInsets: UX.buttonContentInsets
            )
            linkButton.configure(viewModel: linkButtonViewModel)

            linkButton.addTarget(self, action: #selector(learnMoreTapped), for: .touchUpInside)

            defaultFooter.stackView.addArrangedSubview(linkButton)

            return defaultFooter
        }

        return defaultFooter
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    @objc
    func learnMoreTapped() {
        let viewController = SettingsContentViewController(windowUUID: windowUUID)
        viewController.url = SupportUtils.URLForRelayMaskLearnMoreArticle
        navigationController?.pushViewController(viewController, animated: true)
        RelayController.shared.telemetry.learnMoreTapped()
    }

    // MARK: - ThemeApplicable

    override func applyTheme() {
        super.applyTheme()
        linkButton.applyTheme(theme: currentTheme())
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
        return AccessibilityIdentifiers.Settings.RelayMask.manageMasksButton
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
        RelayController.shared.telemetry.manageMasksTapped()
        let viewController = SettingsContentViewController(windowUUID: windowUUID)
        viewController.url = SupportUtils.URLForRelayAccountManagement
        parentNav?.pushViewController(viewController, animated: true)
    }
}
