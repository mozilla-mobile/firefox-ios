// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

import Account

private class CustomFxAContentServerEnableSetting: BoolSetting {
      init(prefs: Prefs, settingDidChange: ((Bool?) -> Void)? = nil) {
          super.init(
              prefs: prefs,
              prefKey: PrefsKeys.KeyUseCustomFxAContentServer,
              defaultValue: false,
              attributedTitleText: NSAttributedString(
                string: .SettingsAdvancedAccountUseCustomFxAContentServerURITitle
              ),
              settingDidChange: settingDidChange
          )
      }
  }

  private class CustomSyncTokenServerEnableSetting: BoolSetting {
      init(prefs: Prefs, settingDidChange: ((Bool?) -> Void)? = nil) {
          super.init(
              prefs: prefs,
              prefKey: PrefsKeys.KeyUseCustomSyncTokenServerOverride,
              defaultValue: false,
              attributedTitleText: NSAttributedString(string: .SettingsAdvancedAccountUseCustomSyncTokenServerTitle),
              settingDidChange: settingDidChange
          )
      }
  }

  private class CustomURLSetting: WebPageSetting {
      override init(
        prefs: Prefs,
        prefKey: String,
        defaultValue: String? = nil,
        placeholder: String,
        accessibilityIdentifier: String,
        isChecked: @escaping () -> Bool = { return false },
        settingDidChange: ((String?) -> Void)? = nil
      ) {
          super.init(prefs: prefs,
                     prefKey: prefKey,
                     defaultValue: defaultValue,
                     placeholder: placeholder,
                     accessibilityIdentifier: accessibilityIdentifier,
                     settingDidChange: settingDidChange)
          enableClearButtonForTextField()
      }
  }

class AdvancedAccountSettingViewController: SettingsTableViewController {
    fileprivate var customFxAContentURI: String?
    fileprivate var customSyncTokenServerURI: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = .SettingsAdvancedAccountTitle
        self.customFxAContentURI = self.profile.prefs.stringForKey(PrefsKeys.KeyCustomFxAContentServer)
        self.customSyncTokenServerURI = self.profile.prefs.stringForKey(PrefsKeys.KeyCustomSyncTokenServerOverride)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        RustFirefoxAccounts.reconfig(prefs: profile.prefs) { _ in }
    }

    override func generateSettings() -> [SettingSection] {
        let prefs = profile.prefs

        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let attributes = [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        let useStage = BoolSetting(
            prefs: prefs,
            prefKey: PrefsKeys.UseStageServer,
            defaultValue: false,
            attributedTitleText: NSAttributedString(
                string: .AdvancedAccountUseStageServer,
                attributes: attributes)) { isOn in
            self.settings = self.generateSettings()
            self.tableView.reloadData()
        }

        let useReactFxA = BoolSetting(
            prefs: prefs,
            prefKey: PrefsKeys.KeyUseReactFxA,
            defaultValue: false,
            attributedTitleText: NSAttributedString(string: .SettingsAdvancedAccountUseReactContentServer)
        ) { isOn in
            self.settings = self.generateSettings()
            self.tableView.reloadData()
        }

        let customFxA = CustomURLSetting(prefs: prefs,
                                         prefKey: PrefsKeys.KeyCustomFxAContentServer,
                                         placeholder: .SettingsAdvancedAccountCustomFxAContentServerURI,
                                         accessibilityIdentifier: "CustomFxAContentServer")

        let customSyncTokenServerURISetting = CustomURLSetting(
            prefs: prefs,
            prefKey: PrefsKeys.KeyCustomSyncTokenServerOverride,
            placeholder: .SettingsAdvancedAccountCustomSyncTokenServerURI,
            accessibilityIdentifier: "CustomSyncTokenServerURISetting")

        let autoconfigSettings = [
            CustomFxAContentServerEnableSetting(prefs: prefs) { isOn in
                self.settings = self.generateSettings()
                self.tableView.reloadData()
            },
            customFxA
        ]

        let tokenServerSettings = [
            CustomSyncTokenServerEnableSetting(prefs: prefs),
            customSyncTokenServerURISetting
        ]

        var settings: [SettingSection] = [SettingSection(title: nil, children: [useStage, useReactFxA])]

        if !(prefs.boolForKey(PrefsKeys.UseStageServer) ?? false) {
            settings.append(SettingSection(title: nil, children: autoconfigSettings))
            settings.append(SettingSection(title: nil, children: tokenServerSettings))
        }
        return settings
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView else { return nil }

        let sectionSetting = settings[section]
        headerView.titleLabel.text = sectionSetting.title?.string

        switch section {
        case 1, 3:
            headerView.titleAlignment = .top
            headerView.titleLabel.numberOfLines = 0
        default:
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
        return headerView
    }
}
