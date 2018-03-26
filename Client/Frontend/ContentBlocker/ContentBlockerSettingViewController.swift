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

        var attributes = [NSAttributedStringKey: AnyObject]()
        attributes[NSAttributedStringKey.font] = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        attributes[NSAttributedStringKey.foregroundColor] = UIConstants.HighlightBlue

        let button = UIButton()
        button.setAttributedTitle(NSAttributedString(string: title, attributes: attributes), for: .normal)
        button.addTarget(self, action: #selector(moreInfoTapped), for: .touchUpInside)

        let footer = UIView()
        footer.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.top.equalTo(footer).offset(8)
            make.bottom.equalTo(footer).offset(8)
            make.leading.equalTo(footer).offset(16)
        }

        return footer
    }

    @objc func moreInfoTapped() {
        let viewController = SettingsContentViewController()
        viewController.url = SupportUtils.URLForTopic("tracking-protection-ios")
        navigationController?.pushViewController(viewController, animated: true)
    }
}

@available(iOS 11.0, *)
extension BlockingStrength {
    var settingTitle: String {
        switch self {
        case .basic:
            return Strings.TrackingProtectionOptionBlockListTypeBasic
        case .strict:
            return Strings.TrackingProtectionOptionBlockListTypeStrict
        }
    }

    var subtitle: String {
        switch self {
        case .basic:
            return Strings.TrackingProtectionOptionBlockListTypeBasicDescription
        case .strict:
            return Strings.TrackingProtectionOptionBlockListTypeStrictDescription
        }
    }

    static func accessibilityId(for strength: BlockingStrength) -> String {
        switch strength {
        case .basic:
            return "Settings.TrackingProtectionOption.BlockListBasic"
        case .strict:
            return "Settings.TrackingProtectionOption.BlockListStrict"
        }
    }
}

@available(iOS 11.0, *)
class ContentBlockerSettingViewController: ContentBlockerSettingsTableView {
    let prefs: Prefs
    var currentBlockingStrength: BlockingStrength

    init(prefs: Prefs) {
        self.prefs = prefs

        currentBlockingStrength = prefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap({BlockingStrength(rawValue: $0)}) ?? .basic
        
        super.init(style: .grouped)

        self.title = Strings.SettingsTrackingProtectionSectionName
        hasSectionSeparatorLine = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let normalBrowsing = BoolSetting(prefs: profile.prefs, prefKey: ContentBlockingConfig.Prefs.NormalBrowsingEnabledKey, defaultValue: ContentBlockingConfig.Defaults.NormalBrowsing, attributedTitleText: NSAttributedString(string: Strings.TrackingProtectionOptionOnInNormalBrowsing)) { _ in
            ContentBlockerHelper.prefsChanged()
        }
        let privateBrowsing = BoolSetting(prefs: profile.prefs, prefKey: ContentBlockingConfig.Prefs.PrivateBrowsingEnabledKey, defaultValue: ContentBlockingConfig.Defaults.PrivateBrowsing, attributedTitleText: NSAttributedString(string: Strings.TrackingProtectionOptionOnInPrivateBrowsing))  { _ in
            ContentBlockerHelper.prefsChanged()
        }

        let strengthSetting: [CheckmarkSetting] = BlockingStrength.allOptions.map { option in
            let id = BlockingStrength.accessibilityId(for: option)
            return CheckmarkSetting(title: NSAttributedString(string: option.settingTitle), subtitle: NSAttributedString(string: option.subtitle), accessibilityIdentifier: id, isEnabled: {
                return option == self.currentBlockingStrength
            }, onChanged: {
                self.currentBlockingStrength = option
                self.prefs.setString(self.currentBlockingStrength.rawValue, forKey: ContentBlockingConfig.Prefs.StrengthKey)
                ContentBlockerHelper.prefsChanged()
                self.tableView.reloadData()
                LeanPlumClient.shared.track(event: .trackingProtectionSettings, withParameters: ["Strength option": option.rawValue as AnyObject])
                UnifiedTelemetry.recordEvent(category: .action, method: .change, object: .setting, value: ContentBlockingConfig.Prefs.StrengthKey, extras: ["to": option.rawValue])
            })
        }

        let firstSection = SettingSection(title: NSAttributedString(string: Strings.TrackingProtectionOptionOnOffHeader), footerTitle: NSAttributedString(string: Strings.TrackingProtectionOptionOnOffFooter), children: [normalBrowsing, privateBrowsing])

        // The bottom of the block lists section has a More Info button, implemented as a custom footer view,
        // SettingSection needs footerTitle set to create a footer, which we then override the view for.
        let blockListsTitle = Strings.TrackingProtectionOptionBlockListsTitle
        let secondSection = SettingSection(title: NSAttributedString(string: blockListsTitle), footerTitle: NSAttributedString(string: "placeholder replaced with UIButton"), children: strengthSetting)
        return [firstSection, secondSection]
    }
}
