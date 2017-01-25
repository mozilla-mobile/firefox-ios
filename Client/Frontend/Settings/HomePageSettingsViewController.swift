/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit

private let log = Logger.browserLogger

class HomePageSettingsViewController: SettingsTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsHomePageTitle
    }

    override func generateSettings() -> [SettingSection] {
        let prefs = profile.prefs
        let helper = HomePageHelper(prefs: prefs)
        func setHomePage(_ url: URL?) -> ((UINavigationController?) -> Void) {
            weak var tableView: UITableView? = self.tableView
            return { nav in
                helper.currentURL = url
                tableView?.reloadData()
            }
        }

        func isHomePage(_ url: URL?) -> (() -> Bool) {
            return {
                return url?.isWebPage() ?? false
            }
        }

        func URLFromString(_ string: String?) -> URL? {
            guard let string = string else {
                return nil
            }
            return URL(string: string)
        }

        let currentTabURL = self.tabManager.selectedTab?.url?.displayURL
        let clipboardURL = URLFromString(UIPasteboard.general.string)

        var basicSettings: [Setting] = [
            WebPageSetting(prefs: prefs,
                prefKey: HomePageConstants.HomePageURLPrefKey,
                placeholder: helper.defaultURLString ?? Strings.SettingsHomePagePlaceholder,
                accessibilityIdentifier: "HomePageSetting"),
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageUseCurrentPage),
                accessibilityIdentifier: "UseCurrentTab",
                isEnabled: isHomePage(currentTabURL),
                onClick: setHomePage(currentTabURL)),
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageUseCopiedLink),
                accessibilityIdentifier: "UseCopiedLink",
                isEnabled: isHomePage(clipboardURL),
                onClick: setHomePage(clipboardURL)),
            ]

        basicSettings += [
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageClear),
                destructive: true,
                accessibilityIdentifier: "ClearHomePage",
                onClick: setHomePage(nil)),
            ]

        let settings: [SettingSection] = [
            SettingSection(title: NSAttributedString(string: Strings.SettingsHomePageURLSectionTitle), children: basicSettings),
            SettingSection(children: [
                BoolSetting(prefs: prefs,
                    prefKey: HomePageConstants.HomePageButtonIsInMenuPrefKey,
                    defaultValue: true,
                    titleText: Strings.SettingsHomePageUIPositionTitle,
                    statusText: Strings.SettingsHomePageUIPositionSubtitle),
            ])
        ]

        return settings
    }
}

class WebPageSetting: StringSetting {
    init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String, accessibilityIdentifier: String, settingDidChange: ((String?) -> Void)? = nil) {
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   settingIsValid: WebPageSetting.isURLOrEmpty,
                   settingDidChange: settingDidChange)
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
    }

    override func prepareValidValue(userInput value: String?) -> String? {
        guard let value = value else {
            return nil
        }
        return URIFixup.getURL(value)?.absoluteString
    }

    static func isURLOrEmpty(_ string: String?) -> Bool {
        guard let string = string, !string.isEmpty else {
            return true
        }
        return URL(string: string)?.isWebPage() ?? false
    }
}
