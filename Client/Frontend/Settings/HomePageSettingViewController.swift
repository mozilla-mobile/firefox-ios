/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class HomePageSettingViewController: SettingsTableViewController, FeatureFlagsProtocol {

    /* variables for checkmark settings */
    let prefs: Prefs
    var currentNewTabChoice: NewTabPage!
    var currentStartAtHomeSetting: StartAtHomeSetting!
    var hasHomePage = false
    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(style: .grouped)

        self.title = Strings.AppMenuOpenHomePageTitleString
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {

        let customizeFirefoxHomeSection = customizeFirefoxSettingSection()
        let customizeHomePageSection = customizeHomeSettingSection()

        guard let startAtHomeSection = setupStartAtHomeSection() else {
            return [customizeFirefoxHomeSection, customizeHomePageSection]
        }

        return [customizeFirefoxHomeSection, customizeHomePageSection, startAtHomeSection]
    }

    private func customizeHomeSettingSection() -> SettingSection {

        // The Home button and the New Tab page can be set independently
        self.currentNewTabChoice = NewTabAccessors.getHomePage(self.prefs)
        self.hasHomePage = HomeButtonHomePageAccessors.getHomePage(self.prefs) != nil

        let onFinished = {
            self.prefs.setString(self.currentNewTabChoice.rawValue, forKey: NewTabAccessors.HomePrefKey)
            self.tableView.reloadData()
        }

        let showTopSites = CheckmarkSetting(title: NSAttributedString(string: Strings.SettingsNewTabTopSites), subtitle: nil, accessibilityIdentifier: "HomeAsFirefoxHome", isChecked: {return self.currentNewTabChoice == NewTabPage.topSites}, onChecked: {
            self.currentNewTabChoice = NewTabPage.topSites
            onFinished()
        })
        let showWebPage = WebPageSetting(prefs: prefs, prefKey: PrefsKeys.HomeButtonHomePageURL, defaultValue: nil, placeholder: Strings.CustomNewPageURL, accessibilityIdentifier: "HomeAsCustomURL", isChecked: {return !showTopSites.isChecked()}, settingDidChange: { (string) in
            self.currentNewTabChoice = NewTabPage.homePage
            self.prefs.setString(self.currentNewTabChoice.rawValue, forKey: NewTabAccessors.HomePrefKey)
            self.tableView.reloadData()
        })
        showWebPage.textField.textAlignment = .natural

        return SettingSection(title: NSAttributedString(string: Strings.NewTabSectionName),
                              footerTitle: NSAttributedString(string: Strings.NewTabSectionNameFooter),
                              children: [showTopSites, showWebPage])
    }

    private func customizeFirefoxSettingSection() -> SettingSection {

        var sectionItems = [Setting]()

        let pocketSetting = BoolSetting(with: .pocket,
                                        titleText: NSAttributedString(string: .SettingsCustomizeHomePocket))

        let jumpBackInSetting = BoolSetting(with: .jumpBackIn,
                                            titleText: NSAttributedString(string: .SettingsCustomizeHomeJumpBackIn))

        let recentlySavedSetting = BoolSetting(with: .recentlySaved,
                                               titleText: NSAttributedString(string: .SettingsCustomizeHomeRecentlySaved))

//        let recentlyVisitedSetting = BoolSetting(with: .recentlyVisited,
//                                                 titleText: NSAttributedString(string: .FirefoxHomeJumpBackInSectionTitle))


        sectionItems.append(TopSitesSettings(settings: self))
        sectionItems.append(jumpBackInSetting)
        sectionItems.append(recentlySavedSetting)
//        sectionItems.append(recentlyVisitedSetting)
        sectionItems.append(pocketSetting)

        return SettingSection(title: NSAttributedString(string: Strings.SettingsTopSitesCustomizeTitle),
                              footerTitle: NSAttributedString(string: .SettingsCustomizeHomeDescritpion),
                              children: sectionItems)
    }

    private func setupStartAtHomeSection() -> SettingSection? {
        // TODO: WHen fixing start at home, this setting needs to addressed as well. The
        // barebones of what needs to be done are here, just needs updating.
        return nil
//        guard featureFlags.isFeatureActiveForBuild(.startAtHome) else { return nil }
//        guard let startAtHomeSetting: StartAtHomeSetting = featureFlags.featureOption(.startAtHome) else { return nil }
//        currentStartAtHomeSetting = startAtHomeSetting
//
//        let onOptionSelected: ((Bool, StartAtHomeSetting) -> Void) = { state, option in
//            self.featureFlags.set(.startAtHome, to: state, with: option)
//            self.tableView.reloadData()
//        }
//
//        let afterFourHoursOption = CheckmarkSetting(title: NSAttributedString(string: .SettingsCustomizeHomeStartAtHomeAfterFourHours),
//                                                    subtitle: nil,
//                                                    accessibilityIdentifier: "StartAtHomeAfterFourHours",
//                                                    isChecked: { return self.currentStartAtHomeSetting == .afterFourHours },
//                                                    onChecked: {
//                                                        self.currentStartAtHomeSetting = .afterFourHours
//                                                        onOptionSelected(true, .afterFourHours)
//        })
//
//        let alwaysOption = CheckmarkSetting(title: NSAttributedString(string: .SettingsCustomizeHomeStartAtHomeAlways),
//                                            subtitle: nil,
//                                            accessibilityIdentifier: "StartAtHomeAlways",
//                                            isChecked: { return self.currentStartAtHomeSetting == .always },
//                                            onChecked: {
//                                                self.currentStartAtHomeSetting = .always
//                                                onOptionSelected(true, .always)
//        })
//
//        let neverOption = CheckmarkSetting(title: NSAttributedString(string: .SettingsCustomizeHomeStartAtHomeNever),
//                                           subtitle: nil,
//                                           accessibilityIdentifier: "StartAtHomeNever",
//                                           isChecked: { return self.currentStartAtHomeSetting == .never },
//                                           onChecked: {
//                                            self.currentStartAtHomeSetting = .never
//                                            onOptionSelected(false, .never)
//        })
//
//        let section = SettingSection(title: NSAttributedString(string: .SettingsCustomizeHomeStartAtHomeSectionTitle),
//                                     children: [afterFourHoursOption, alwaysOption, neverOption])
//
//        return section
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.keyboardDismissMode = .onDrag
    }

    class TopSitesSettings: Setting {
        let profile: Profile

        override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }
        override var status: NSAttributedString {
            let num = self.profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows
            return NSAttributedString(string: String(format: Strings.TopSitesRowCount, num))
        }

        override var accessibilityIdentifier: String? { return "TopSitesRows" }
        override var style: UITableViewCell.CellStyle { return .value1 }

        init(settings: SettingsTableViewController) {
            self.profile = settings.profile
            super.init(title: NSAttributedString(string: .SettingsCustomizeHomeShortcuts,
                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
        }

        override func onClick(_ navigationController: UINavigationController?) {
            let viewController = TopSitesRowCountSettingsController(prefs: profile.prefs)
            viewController.profile = profile
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

class TopSitesRowCountSettingsController: SettingsTableViewController {
    let prefs: Prefs
    var numberOfRows: Int32
    static let defaultNumberOfRows: Int32 = 2

    init(prefs: Prefs) {
        self.prefs = prefs
        numberOfRows = self.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows
        super.init(style: .grouped)
        self.title = Strings.AppMenuTopSitesTitleString
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {

        let createSetting: (Int32) -> CheckmarkSetting = { num in
            return CheckmarkSetting(title: NSAttributedString(string: "\(num)"), subtitle: nil, isChecked: { return num == self.numberOfRows }, onChecked: {
                self.numberOfRows = num
                self.prefs.setInt(Int32(num), forKey: PrefsKeys.NumberOfTopSiteRows)
                self.tableView.reloadData()
            })
        }

        let rows = [1, 2, 3, 4].map(createSetting)
        let section = SettingSection(title: NSAttributedString(string: Strings.TopSitesRowSettingFooter), footerTitle: nil, children: rows)
        return [section]
    }
}
