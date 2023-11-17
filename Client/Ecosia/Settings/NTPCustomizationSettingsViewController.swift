// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

final class NTPCustomizationSettingsViewController: SettingsTableViewController {
    init() {
        super.init(style: .insetGrouped)
        
        title = .localized(.homepage)
        navigationItem.rightBarButtonItem = .init(title: .localized(.done),
                                                  style: .done) { [weak self] _ in
            self?.dismiss(animated: true)
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
            return NTPCustomizationSetting(prefs: profile.prefs, config: config)
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
    
    convenience init(prefs: Prefs, config: CustomizableNTPSettingConfig) {
        self.init(prefs: prefs, 
                  theme: EcosiaThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier).currentTheme,
                  defaultValue: true,
                  titleText: .localized(config.localizedTitleKey))
        self.config = config
    }

    override func displayBool(_ control: UISwitch) {
        control.isOn = config.persistedFlag
    }

    override func writeBool(_ control: UISwitch) {
        config.persistedFlag = control.isOn
        Analytics.shared.ntp(control.isOn ? .enable : .disable, label: config.analyticsLabel)
    }
}
