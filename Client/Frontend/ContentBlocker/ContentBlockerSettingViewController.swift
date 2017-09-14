/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

@available(iOS 11.0, *)
class ContentBlockerSettingsTableView: SettingsTableViewController {
    // The first section header gets a More Info link
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            return super.tableView(tableView, viewForFooterInSection: section)
        }

        // TODO: Get a dedicated string for this.
        let title = NSLocalizedString("More Info…", tableName: "SendAnonymousUsageData", comment: "Re-using more info label from 'anonymous usage data' item for showing a 'More Info' link on the Tracking Protection settings screen.")

        var attributes = [String: AnyObject]()
        attributes[NSFontAttributeName] = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
        attributes[NSForegroundColorAttributeName] = UIConstants.HighlightBlue

        let button = UIButton()
        button.setAttributedTitle(NSAttributedString(string: title, attributes: attributes), for: .normal)
        button.contentHorizontalAlignment = .left
        // Top and left insets are needed to match the table row style.
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(ContentBlockerSettingsTableView.moreInfoTapped), for: .touchUpInside)
        return button
    }

    func moreInfoTapped() {
        let viewController = SettingsContentViewController()
        viewController.url = SupportUtils.URLForTopic("tracking-protection-ios")
        navigationController?.pushViewController(viewController, animated: true)
    }
}

@available(iOS 11.0, *)
class ContentBlockerSettingViewController: ContentBlockerSettingsTableView {
    let prefs: Prefs
    let EnabledStates = ContentBlockerHelper.EnabledState.allOptions
    let BlockingStrengths = ContentBlockerHelper.BlockingStrength.allOptions
    var currentEnabledState: ContentBlockerHelper.EnabledState
    var currentBlockingStrength: ContentBlockerHelper.BlockingStrength

    init(prefs: Prefs) {
        self.prefs = prefs
        currentEnabledState = ContentBlockerHelper.EnabledState(rawValue: prefs.stringForKey(ContentBlockerHelper.PrefKeyEnabledState) ?? "") ?? .onInPrivateBrowsing
        currentBlockingStrength = ContentBlockerHelper.BlockingStrength(rawValue: prefs.stringForKey(ContentBlockerHelper.PrefKeyStrength) ?? "") ?? .basic

        super.init(style: .grouped)

        self.title = Strings.SettingsTrackingProtectionSectionName
        hasSectionSeparatorLine = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let enabledSetting: [CheckmarkSetting] = EnabledStates.map { option in
            return CheckmarkSetting(title: NSAttributedString(string: option.settingTitle), subtitle: nil, isEnabled: {
                return option == self.currentEnabledState
            }, onChanged: {
                self.currentEnabledState = option
                self.prefs.setString(self.currentEnabledState.rawValue, forKey: ContentBlockerHelper.PrefKeyEnabledState)
                self.tableView.reloadData()
                ContentBlockerHelper.prefsChanged()

                LeanplumIntegration.sharedInstance.track(eventName: .trackingProtectionSettings, withParameters: ["Enabled option": option.rawValue as AnyObject])
            })
        }

        let strengthSetting: [CheckmarkSetting] = BlockingStrengths.map { option in
            return CheckmarkSetting(title: NSAttributedString(string: option.settingTitle), subtitle: NSAttributedString(string: option.subtitle), isEnabled: {
                return option == self.currentBlockingStrength
            }, onChanged: {
                self.currentBlockingStrength = option
                self.prefs.setString(self.currentBlockingStrength.rawValue, forKey: ContentBlockerHelper.PrefKeyStrength)
                self.tableView.reloadData()
                ContentBlockerHelper.prefsChanged()

                LeanplumIntegration.sharedInstance.track(eventName: .trackingProtectionSettings, withParameters: ["Strength option": option.rawValue as AnyObject])
            })
        }

        let firstSection = SettingSection(title: NSAttributedString(string: Strings.TrackingProtectionOptionOnOffHeader), footerTitle: NSAttributedString(string: Strings.TrackingProtectionOptionOnOffFooter), children: enabledSetting)

        // The bottom of the block lists section has a More Info button, implemented as a custom footer view,
        // SettingSection needs footerTitle set to create a footer, which we then override the view for.
        let blockListsTitle = Strings.TrackingProtectionOptionBlockListsTitle
        let secondSection = SettingSection(title: NSAttributedString(string: blockListsTitle), footerTitle: NSAttributedString(string: "placeholder replaced with UIButton"), children: strengthSetting)
        return [firstSection, secondSection]
    }
}
