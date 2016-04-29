/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit

private let log = Logger.browserLogger

struct HomePageConstants {
    static let HomePageURLPrefKey = "homepage.url"
    static let HomePageButtonIsInMenuPrefKey = "homepage.button.isInMenu"
    static let DefaultHomePageURLPrefKey = "homepage.url.default"
}

class HomePageSettingsViewController: SettingsTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsHomePageTitle
    }

    override func generateSettings() -> [SettingSection] {
        let prefs = profile.prefs

        typealias WebPageSource = () -> NSURL?
        func setHomePage(source: WebPageSource) -> ((UINavigationController?) -> ()) {
            return { nav in
                if let url = source(), string = url.absoluteDisplayString() {
                    prefs.setString(string, forKey: HomePageConstants.HomePageURLPrefKey)
                } else {
                    prefs.removeObjectForKey(HomePageConstants.HomePageURLPrefKey)
                }
                self.tableView.reloadData()
            }
        }

        func isHomePage(source: WebPageSource) -> (() -> Bool) {
            return {
                return source()?.isWebPage() ?? false
            }
        }

        let currentTab: WebPageSource = {
            return self.tabManager.selectedTab?.displayURL
        }

        let clipboardURL: WebPageSource = {
            let string = UIPasteboard.generalPasteboard().string ?? " "
            return NSURL(string: string)
        }

        let defaultURL: WebPageSource = {
            let string = prefs.stringForKey(HomePageConstants.DefaultHomePageURLPrefKey) ?? " "
            return NSURL(string: string)
        }

        var basicSettings: [Setting] = [
            WebPageSetting(prefs: prefs,
                prefKey: HomePageConstants.HomePageURLPrefKey,
                placeholder: Strings.SettingsHomePagePlaceholder),
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageUseCurrentPage),
                isEnabled: isHomePage(currentTab),
                onClick: setHomePage(currentTab)),
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageUseCopiedLink),
                isEnabled: isHomePage(clipboardURL),
                onClick: setHomePage(clipboardURL)),
        ]

        if let _ = defaultURL() {
            basicSettings += [
                ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageUseDefault),
                    onClick: setHomePage(defaultURL)
                )
            ]
        }

        basicSettings += [
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageClear),
                destructive: true,
                onClick: setHomePage({ nil })
            )
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
                        statusText: Strings.SettingsHomePageUIPositionSubtitle
                    ),
                ]),
            ]
        }

        return settings
    }
}

class WebPageSetting: StringSetting {
    init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String? = nil, settingDidChange: ((String?) -> Void)? = nil) {
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   placeholder: placeholder,
                   settingIsValid: WebPageSetting.isURL,
                   settingDidChange: settingDidChange)
        textField.keyboardType = .URL
        textField.autocapitalizationType = .None
        textField.autocorrectionType = .No
    }

    static func isURL(string: String?) -> Bool {
        return NSURL(string: string ?? "invalid://")?.isWebPage() ?? false
    }
}

class StringSetting: Setting, UITextFieldDelegate {

    let prefKey: String

    private let prefs: Prefs
    private let defaultValue: String?
    private let settingDidChange: ((String?) -> Void)?
    private let settingIsValid: ((String?) -> Bool)?

    let textField = UITextField()

    init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String? = nil, settingIsValid isValueValid: ((String?) -> Bool)? = nil, settingDidChange: ((String?) -> Void)? = nil) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        super.init()

        textField.placeholder = placeholder
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), forControlEvents: .EditingChanged)
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)

        cell.accessibilityTraits = UIAccessibilityTraitLink
        cell.contentView.addSubview(textField)

        let container = UIView()
        container.addSubview(textField)
        cell.contentView.addSubview(container)

        cell.contentView.snp_makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(cell.snp_width)
        }

        textField.snp_makeConstraints { make in
            make.height.equalTo(cell.contentView)
            make.width.equalTo(cell.contentView).offset(-2 * SettingsTableSectionHeaderFooterViewUX.titleHorizontalPadding)
            make.leading.equalTo(cell.contentView).offset(SettingsTableSectionHeaderFooterViewUX.titleHorizontalPadding)
        }
        textField.text = prefs.stringForKey(prefKey) ?? defaultValue
    }

    override func onClick(navigationController: UINavigationController?) {
        textField.becomeFirstResponder()
    }

    private func isValid(value: String?) -> Bool {
        return settingIsValid?(value) ?? true
    }

    @objc func textFieldDidChange(textField: UITextField) {
        let color = isValid(textField.text) ? UIConstants.TableViewRowTextColor : UIConstants.DestructiveRed
        textField.textColor = color
    }

    @objc func textFieldShouldReturn(textField: UITextField) -> Bool {
        return isValid(textField.text)
    }

    @objc func textFieldDidEndEditing(textField: UITextField) {
        let text = textField.text
        if !isValid(text) {
            return
        }
        // unsure if we want to actually set the value to the default here.
        if let string = text ?? defaultValue {
            prefs.setString(string, forKey: prefKey)
            settingDidChange?(textField.text)
        } else {
            prefs.removeObjectForKey(prefKey)
            settingDidChange?(defaultValue)
        }
    }
}

class ButtonSetting: Setting {
    let onButtonClick: (UINavigationController?) -> ()
    let destructive: Bool
    let isEnabled: () -> Bool

    static let always = { return true }

    init(title: NSAttributedString?, destructive: Bool = false, isEnabled: () -> Bool = ButtonSetting.always, onClick: (UINavigationController?) -> ()) {
        self.onButtonClick = onClick
        self.destructive = destructive
        self.isEnabled = isEnabled
        super.init(title: title)
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let enabled = isEnabled()
        if enabled {
            cell.textLabel?.textColor = destructive ? UIConstants.DestructiveRed : UIConstants.HighlightBlue
        } else {
            cell.textLabel?.textColor = UIConstants.TableViewDisabledRowTextColor
        }
        cell.textLabel?.textAlignment = NSTextAlignment.Center
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.selectionStyle = .None
    }

    override func onClick(navigationController: UINavigationController?) {
        if isEnabled() {
            onButtonClick(navigationController)
        }
    }
}
