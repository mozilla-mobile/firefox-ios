// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class HomePageSettingViewController: SettingsTableViewController, FeatureFlagsProtocol {

    // MARK: - Variables
    /* variables for checkmark settings */
    let prefs: Prefs
    var currentNewTabChoice: NewTabPage!
    var currentStartAtHomeSetting: StartAtHomeSetting!
    var hasHomePage = false

    var isJumpBackInSectionEnabled: Bool {
        let isFeatureEnabled = featureFlags.isFeatureActiveForBuild(.jumpBackIn)
        let isNimbusFeatureEnabled = featureFlags.isFeatureActiveForNimbus(.jumpBackIn)
        guard isFeatureEnabled, isNimbusFeatureEnabled else { return false }
        return true
    }

    var isRecentlySavedSectionEnabled: Bool {
        let isFeatureEnabled = featureFlags.isFeatureActiveForBuild(.recentlySaved)
        let isNimbusFeatureEnabled = featureFlags.isFeatureActiveForNimbus(.recentlySaved)
        guard isFeatureEnabled, isNimbusFeatureEnabled else { return false }
        return true
    }

    var isWallpaperSectionEnabled: Bool {
        let isFeatureEnabled = featureFlags.isFeatureActiveForBuild(.wallpapers)
        guard isFeatureEnabled else { return false }
        return true
    }

    var isHistoryHighlightsSectionEnabled: Bool {
        // TODO: If this feature is going behind a Nimbus flag, that should be added here
        return featureFlags.isFeatureActiveForBuild(.historyHighlights)
    }

    // MARK: - Initializers
    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(style: .grouped)

        self.title = .SettingsHomePageSectionName
        self.navigationController?.navigationBar.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Homepage.homePageNavigationBar
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.keyboardDismissMode = .onDrag
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }

    // MARK: - Methods
    override func generateSettings() -> [SettingSection] {

        let customizeFirefoxHomeSection = customizeFirefoxSettingSection()
        let customizeHomePageSection = customizeHomeSettingSection()

        guard let startAtHomeSection = setupStartAtHomeSection() else {
            return [customizeFirefoxHomeSection, customizeHomePageSection]
        }

        return [startAtHomeSection, customizeFirefoxHomeSection, customizeHomePageSection]
    }

    private func customizeHomeSettingSection() -> SettingSection {

        // The Home button and the New Tab page can be set independently
        self.currentNewTabChoice = NewTabAccessors.getHomePage(self.prefs)
        self.hasHomePage = HomeButtonHomePageAccessors.getHomePage(self.prefs) != nil

        let onFinished = {
            self.prefs.setString(self.currentNewTabChoice.rawValue, forKey: NewTabAccessors.HomePrefKey)
            self.tableView.reloadData()
        }

        let showTopSites = CheckmarkSetting(title: NSAttributedString(string: .SettingsNewTabTopSites), subtitle: nil, accessibilityIdentifier: "HomeAsFirefoxHome", isChecked: {return self.currentNewTabChoice == NewTabPage.topSites}, onChecked: {
            self.currentNewTabChoice = NewTabPage.topSites
            onFinished()
        })
        let showWebPage = WebPageSetting(prefs: prefs, prefKey: PrefsKeys.HomeButtonHomePageURL, defaultValue: nil, placeholder: .CustomNewPageURL, accessibilityIdentifier: "HomeAsCustomURL", isChecked: {return !showTopSites.isChecked()}, settingDidChange: { (string) in
            self.currentNewTabChoice = NewTabPage.homePage
            self.prefs.setString(self.currentNewTabChoice.rawValue, forKey: NewTabAccessors.HomePrefKey)
            self.tableView.reloadData()
        })
        showWebPage.textField.textAlignment = .natural

        return SettingSection(title: NSAttributedString(string: .SettingsHomePageURLSectionTitle),
                              children: [showTopSites, showWebPage])
    }

    private func customizeFirefoxSettingSection() -> SettingSection {

        // Setup
        var sectionItems = [Setting]()

        let pocketSetting = BoolSetting(with: .pocket,
                                        titleText: NSAttributedString(string: .Settings.Homepage.CustomizeFirefoxHome.Pocket))

        let jumpBackInSetting = BoolSetting(with: .jumpBackIn,
                                            titleText: NSAttributedString(string: .Settings.Homepage.CustomizeFirefoxHome.JumpBackIn))

        let recentlySavedSetting = BoolSetting(with: .recentlySaved,
                                               titleText: NSAttributedString(string: .Settings.Homepage.CustomizeFirefoxHome.RecentlySaved))

        let historyHighlightsSetting = BoolSetting(with: .historyHighlights,
                                                   titleText: NSAttributedString(string: .Settings.Homepage.CustomizeFirefoxHome.RecentlyVisited))

        let wallpaperSetting = WallpaperSettings(settings: self)

        // Section ordering
        sectionItems.append(TopSitesSettings(settings: self))

        if isJumpBackInSectionEnabled {
            sectionItems.append(jumpBackInSetting)
        }

        if isRecentlySavedSectionEnabled {
            sectionItems.append(recentlySavedSetting)
        }

        if isHistoryHighlightsSectionEnabled {
            sectionItems.append(historyHighlightsSetting)
        }

        sectionItems.append(pocketSetting)

        if isWallpaperSectionEnabled {
            sectionItems.append(wallpaperSetting)
        }

        return SettingSection(title: NSAttributedString(string: .SettingsCustomizeHomeTitle),
                              footerTitle: NSAttributedString(string: .Settings.Homepage.CustomizeFirefoxHome.Description),
                              children: sectionItems)
    }

    private func setupStartAtHomeSection() -> SettingSection? {
        guard featureFlags.isFeatureActiveForBuild(.startAtHome) else { return nil }
        guard let startAtHomeSetting: StartAtHomeSetting = featureFlags.userPreferenceFor(.startAtHome) else { return nil }
        currentStartAtHomeSetting = startAtHomeSetting

        typealias a11y = AccessibilityIdentifiers.Settings.Homepage.StartAtHome

        let onOptionSelected: ((Bool, StartAtHomeSetting) -> Void) = { state, option in
            self.featureFlags.setUserPreferenceFor(.startAtHome, to: option)
            self.tableView.reloadData()

            let extras = [TelemetryWrapper.EventExtraKey.preference.rawValue: PrefsKeys.FeatureFlags.StartAtHome,
                          TelemetryWrapper.EventExtraKey.preferenceChanged.rawValue: option.rawValue]
            TelemetryWrapper.recordEvent(category: .action, method: .change, object: .setting, extras: extras)
        }

        let afterFourHoursOption = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Homepage.StartAtHome.AfterFourHours),
            subtitle: nil,
            accessibilityIdentifier: a11y.afterFourHours,
            isChecked: { return self.currentStartAtHomeSetting == .afterFourHours },
            onChecked: {
                self.currentStartAtHomeSetting = .afterFourHours
                onOptionSelected(true, .afterFourHours)
        })

        let alwaysOption = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Homepage.StartAtHome.Always),
            subtitle: nil,
            accessibilityIdentifier: a11y.always,
            isChecked: { return self.currentStartAtHomeSetting == .always },
            onChecked: {
                self.currentStartAtHomeSetting = .always
                onOptionSelected(true, .always)
        })

        let neverOption = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Homepage.StartAtHome.Never),
            subtitle: nil,
            accessibilityIdentifier: a11y.disabled,
            isChecked: { return self.currentStartAtHomeSetting == .disabled },
            onChecked: {
                self.currentStartAtHomeSetting = .disabled
                onOptionSelected(false, .disabled)
        })

        let section = SettingSection(title: NSAttributedString(string: .Settings.Homepage.StartAtHome.SectionTitle),
                                     footerTitle: NSAttributedString(string: .Settings.Homepage.StartAtHome.SectionDescription),
                                     children: [alwaysOption, neverOption, afterFourHoursOption])

        return section
    }
}

// MARK: - TopSitesSettings
extension HomePageSettingViewController {
    class TopSitesSettings: Setting {
        let profile: Profile

        override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }
        override var status: NSAttributedString {
            let num = self.profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows
            return NSAttributedString(string: String(format: .Settings.Homepage.Shortcuts.RowCount, num))
        }

        override var accessibilityIdentifier: String? { return "TopSitesRows" }
        override var style: UITableViewCell.CellStyle { return .value1 }

        init(settings: SettingsTableViewController) {
            self.profile = settings.profile
            super.init(title: NSAttributedString(string: .Settings.Homepage.CustomizeFirefoxHome.Shortcuts,
                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
        }

        override func onClick(_ navigationController: UINavigationController?) {
            let viewController = TopSitesRowCountSettingsController(prefs: profile.prefs)
            viewController.profile = profile
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// MARK: - WallpaperSettings
extension HomePageSettingViewController {
    class WallpaperSettings: Setting {

        var profile: Profile
        var tabManager: TabManager

        override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }
        override var accessibilityIdentifier: String? { return "WallpaperSettings" }
        override var style: UITableViewCell.CellStyle { return .value1 }

        init(settings: SettingsTableViewController,
             and tabManager: TabManager = BrowserViewController.foregroundBVC().tabManager
        ) {
            self.profile = settings.profile
            self.tabManager = tabManager
            super.init(title: NSAttributedString(string: .Settings.Homepage.CustomizeFirefoxHome.Wallpaper))
        }

        override func onClick(_ navigationController: UINavigationController?) {
            let viewModel = WallpaperSettingsViewModel(with: tabManager,
                                                       and: WallpaperManager())
            let wallpaperVC = WallpaperSettingsViewController(with: viewModel)
            navigationController?.pushViewController(wallpaperVC, animated: true)
        }
    }
}
