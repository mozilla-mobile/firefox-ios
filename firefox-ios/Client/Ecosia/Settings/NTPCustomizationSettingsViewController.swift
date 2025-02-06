// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common
import Ecosia

final class NTPCustomizationSettingsViewController: SettingsTableViewController {
    init(windowUUID: WindowUUID) {
        super.init(style: .insetGrouped, windowUUID: windowUUID)

        title = .localized(.homepage)
        navigationItem.rightBarButtonItem = .init(title: .localized(.done),
                                                  style: .done) { [weak self] _ in
            self?.settingsDelegate?.reloadHomepage()
            self?.settingsDelegate?.didFinish()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func generateSettings() -> [SettingSection] {
        let customizableSectionConfigs = HomepageSectionType.allCases.compactMap({ $0.customizableConfig })
        let settings: [Setting] = customizableSectionConfigs.map { config in
            if config == .topSites {
                return HomePageSettingViewController.TopSitesSettings(settings: self)
            }
            return NTPCustomizationSetting(prefs: profile.prefs,
                                           theme: themeManager.getCurrentTheme(for: windowUUID),
                                           config: config)
        }
        return [SettingSection(title: .init(string: .localized(.showOnHomepage)), children: settings)]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        settingsDelegate?.reloadHomepage()
    }
}

final class NTPCustomizationSetting: BoolSetting {
    private var config: CustomizableNTPSettingConfig = .topSites

    convenience init(prefs: Prefs, theme: Theme, config: CustomizableNTPSettingConfig) {
        self.init(prefs: prefs,
                  theme: theme,
                  accessibilityIdentifier: config.accessibilityIdentifierPrefix,
                  defaultValue: true,
                  titleText: .localized(config.localizedTitleKey))
        self.config = config
    }

    override func displayBool(_ control: UISwitch) {
        control.isOn = config.persistedFlag
    }

    override func writeBool(_ control: UISwitch) {
        config.persistedFlag = control.isOn
        Analytics.shared.ntpCustomisation(control.isOn ? .enable : .disable, label: config.analyticsLabel)
    }
}
