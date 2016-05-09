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
        func setHomePage(url: NSURL?) -> (UINavigationController? -> ()) {
            weak var tableView: UITableView? = self.tableView
            return { nav in
                helper.currentURL = url
                tableView?.reloadData()
            }
        }

        func isHomePage(url: NSURL?) -> (() -> Bool) {
            return {
                return url?.isWebPage() ?? false
            }
        }

        func URLFromString(string: String?) -> NSURL? {
            guard let string = string else {
                return nil
            }
            return NSURL(string: string)
        }

        let currentTabURL = self.tabManager.selectedTab?.displayURL
        let clipboardURL = URLFromString(UIPasteboard.generalPasteboard().string)
        let defaultURL = URLFromString(prefs.stringForKey(HomePageConstants.DefaultHomePageURLPrefKey))

        var basicSettings: [Setting] = [
            WebPageSetting(prefs: prefs,
                prefKey: HomePageConstants.HomePageURLPrefKey,
                placeholder: Strings.SettingsHomePagePlaceholder,
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

        if let _ = defaultURL {
            basicSettings += [
                ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageUseDefault),
                    accessibilityIdentifier: "UseDefault",
                    onClick: setHomePage(defaultURL)),
                ]
        }

        basicSettings += [
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageClear),
                destructive: true,
                accessibilityIdentifier: "ClearHomePage",
                onClick: setHomePage(nil)),
            ]

        var settings: [SettingSection] = [
            SettingSection(title: NSAttributedString(string: Strings.SettingsHomePageURLSectionTitle), children: basicSettings),
            ]

        if AppConstants.MOZ_MENU {
            settings += [
                SettingSection(children: [
                    BoolSetting(prefs: prefs,
                        prefKey: HomePageConstants.HomePageButtonIsInMenuPrefKey,
                        defaultValue: true,
                        titleText: Strings.SettingsHomePageUIPositionTitle,
                        statusText: Strings.SettingsHomePageUIPositionSubtitle),
                    ]),
                ]
        }

        return settings
    }
}

class WebPageSetting: StringSetting {
    init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String, accessibilityIdentifier: String, settingDidChange: (String? -> Void)? = nil) {
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   settingIsValid: WebPageSetting.isURL,
                   settingDidChange: settingDidChange)
        textField.keyboardType = .URL
        textField.autocapitalizationType = .None
        textField.autocorrectionType = .No
    }

    static func isURL(string: String?) -> Bool {
        guard let string = string else {
            return false
        }
        return NSURL(string: string)?.isWebPage() ?? false
    }
}
