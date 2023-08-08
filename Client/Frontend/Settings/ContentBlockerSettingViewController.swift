// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class ContentBlockerSettingViewController: SettingsTableViewController {
    private let button = UIButton()
    let prefs: Prefs
    var currentBlockingStrength: BlockingStrength

    init(prefs: Prefs,
         isShownFromSettings: Bool = true) {
        self.prefs = prefs

        currentBlockingStrength = prefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap({BlockingStrength(rawValue: $0)}) ?? .basic

        super.init(style: .grouped)

        self.title = .SettingsTrackingProtectionSectionName

        if !isShownFromSettings {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: .AppSettingsDone,
                style: .plain,
                target: self,
                action: #selector(done))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        tableView.reloadData()
    }

    override func generateSettings() -> [SettingSection] {
        let strengthSetting: [CheckmarkSetting] = BlockingStrength.allOptions.map { option in
            let id = BlockingStrength.accessibilityId(for: option)
            let setting = CheckmarkSetting(
                title: NSAttributedString(string: option.settingTitle),
                style: .leftSide,
                subtitle: NSAttributedString(string: option.settingSubtitle),
                accessibilityIdentifier: id,
                isChecked: { return option == self.currentBlockingStrength },
                onChecked: {
                    self.currentBlockingStrength = option
                    self.prefs.setString(self.currentBlockingStrength.rawValue,
                                         forKey: ContentBlockingConfig.Prefs.StrengthKey)
                    TabContentBlocker.prefsChanged()
                    self.tableView.reloadData()

                    let extras = [TelemetryWrapper.EventExtraKey.preference.rawValue: "ETP-strength",
                                  TelemetryWrapper.EventExtraKey.preferenceChanged.rawValue: option.rawValue]
                    TelemetryWrapper.recordEvent(category: .action,
                                                 method: .change,
                                                 object: .setting,
                                                 extras: extras)

                    if option == .strict {
                        self.button.isHidden = true
                        TelemetryWrapper.recordEvent(category: .action,
                                                     method: .tap,
                                                     object: .trackingProtectionMenu,
                                                     extras: [TelemetryWrapper.EventExtraKey.etpSetting.rawValue: option.rawValue])
                    } else {
                        TelemetryWrapper.recordEvent(category: .action,
                                                     method: .tap,
                                                     object: .trackingProtectionMenu,
                                                     extras: [TelemetryWrapper.EventExtraKey.etpSetting.rawValue: "standard"])
                    }
            })

            setting.onAccessoryButtonTapped = {
                let vc = TPAccessoryInfo()
                vc.isStrictMode = option == .strict
                self.navigationController?.pushViewController(vc, animated: true)
            }

            if self.prefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) == false {
                setting.enabled = false
            }
            return setting
        }

        let enabledSetting = BoolSetting(
            prefs: profile.prefs,
            prefKey: ContentBlockingConfig.Prefs.EnabledKey,
            defaultValue: ContentBlockingConfig.Defaults.NormalBrowsing,
            attributedTitleText: NSAttributedString(string: .TrackingProtectionEnableTitle)) { [weak self] enabled in
                TabContentBlocker.prefsChanged()
                strengthSetting.forEach { item in
                    item.enabled = enabled
                }
                self?.tableView.reloadData()
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .tap,
                                             object: .trackingProtectionMenu,
                                             extras: [TelemetryWrapper.EventExtraKey.etpEnabled.rawValue: enabled] )
        }

        let firstSection = SettingSection(title: nil, footerTitle: NSAttributedString(string: .TrackingProtectionCellFooter), children: [enabledSetting])

        let optionalFooterTitle = NSAttributedString(string: .TrackingProtectionLevelFooter)

        // The bottom of the block lists section has a More Info button, implemented as a custom footer view,
        // SettingSection needs footerTitle set to create a footer, which we then override the view for.
        let blockListsTitle: String = .TrackingProtectionOptionProtectionLevelTitle
        let secondSection = SettingSection(title: NSAttributedString(string: blockListsTitle), footerTitle: optionalFooterTitle, children: strengthSetting)
        return [firstSection, secondSection]
    }

    // The first section header gets a More Info link
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let _defaultFooter = super.tableView(tableView, viewForFooterInSection: section) as? ThemedTableSectionHeaderFooterView
        guard let defaultFooter = _defaultFooter else { return nil }

        if section == 0 {
            // TODO: Get a dedicated string for this.
            let title: String = .TrackerProtectionLearnMore

            let font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .subheadline, size: 12.0)
            var attributes = [NSAttributedString.Key: AnyObject]()
            attributes[NSAttributedString.Key.foregroundColor] = themeManager.currentTheme.colors.actionPrimary
            attributes[NSAttributedString.Key.font] = font

            button.setAttributedTitle(NSAttributedString(string: title, attributes: attributes), for: .normal)
            button.addTarget(self, action: #selector(moreInfoTapped), for: .touchUpInside)
            button.isHidden = false

            defaultFooter.addSubview(button)

            button.snp.makeConstraints { (make) in
                make.top.equalTo(defaultFooter.titleLabel.snp.bottom)
                make.leading.equalTo(defaultFooter.titleLabel)
            }
            return defaultFooter
        }

        if currentBlockingStrength == .basic {
            return nil
        }

        return defaultFooter
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    @objc
    func moreInfoTapped() {
        let viewController = SettingsContentViewController()
        viewController.url = SupportUtils.URLForTopic("tracking-protection-ios")
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc
    func done() {
        settingsDelegate?.didFinish()
    }
}
