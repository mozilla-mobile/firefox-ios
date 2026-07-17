// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import ComponentLibrary

final class QuickAnswersSettingsViewController: SettingsTableViewController, UserFeaturePreferenceProvider {
    private struct UX {
        static let buttonContentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
    }
    let prefs: Prefs
    private lazy var linkButton: LinkButton = .build()

    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
        super.init(style: .grouped, windowUUID: windowUUID)
        // TODO: - FXIOS-14720 Add Strings
        self.title = "Quick Answers"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var theme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    override func generateSettings() -> [SettingSection] {
        return [quickAnswersSection]
    }

    private var quickAnswersSection: SettingSection {
        let enableFeatureSwitch = BoolSetting(
            prefs: prefs,
            theme: theme,
            prefKey: PrefsKeys.Settings.quickAnswersFeature,
            defaultValue: userPreferences.getPreferenceFor(.quickAnswers),
            // TODO: - FXIOS-14720 Add Strings
            titleText: "Quick Answers"
        ) { [weak self] _ in
            guard let self else { return }
            // Instead of passing the updated value here, we are using determining
            // whether the feature should be shown in the middleware so that we use the userPreferencesProvider
            // as the source of truth.
            store.dispatch(
                QuickAnswersAction(
                    windowUUID: self.windowUUID,
                    actionType: QuickAnswersActionType.didSettingsChange
                )
            )
        }
        // TODO: - FXIOS-14720 Add Strings
        let footer = "Ask out loud and get short answers. We don’t store your voice, questions, or answers."
        return SettingSection(
            footerTitle: NSAttributedString(string: footer),
            children: [enableFeatureSwitch]
        )
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let defaultFooter = super.tableView(
            tableView,
            viewForFooterInSection: section
        ) as? ThemedTableSectionHeaderFooterView else { return nil }

        let linkButtonViewModel = LinkButtonViewModel(
            // TODO: - FXIOS-14720 Add Strings
            title: "Learn more",
            a11yIdentifier: AccessibilityIdentifiers.Settings.QuickAnswers.learnMoreButton,
            font: FXFontStyles.Regular.caption1.scaledFont(),
            contentInsets: UX.buttonContentInsets
        )
        linkButton.configure(viewModel: linkButtonViewModel)
        linkButton.addTarget(self, action: #selector(learnMoreTapped), for: .touchUpInside)
        defaultFooter.stackView.addArrangedSubview(linkButton)

        return defaultFooter
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    @objc
    private func learnMoreTapped() {
        let controller = SettingsContentViewController(windowUUID: windowUUID)
        controller.url = QuickAnswersCoordinator.learnMoreURL
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - ThemeApplicable

    override func applyTheme() {
        super.applyTheme()
        linkButton.applyTheme(theme: theme)
    }
}
