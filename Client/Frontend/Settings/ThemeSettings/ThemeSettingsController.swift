// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared

class ThemeSettingsController: ThemedTableViewController, StoreSubscriber {
    typealias SubscriberStateType = ThemeSettingsState
    struct UX {
        static var rowHeight: CGFloat = 70
        static var moonSunIconSize: CGFloat = 18
        static var footerFontSize: CGFloat = 12
        static var sliderLeftRightInset: CGFloat = 16
        static var spaceBetweenTableSections: CGFloat = 20
    }

    enum Section: Int {
        case systemTheme
        case automaticBrightness
        case lightDarkPicker
    }

    private var themeState: ThemeSettingsState

    // A non-interactable slider is underlaid to show the current screen brightness indicator
    private var slider: (control: UISlider, deviceBrightnessIndicator: UISlider)?

    lazy var isReduxIntegrationEnabled: Bool = ReduxFlagManager.isReduxEnabled

    var isAutoBrightnessOn: Bool {
        return isReduxIntegrationEnabled ? themeState.isAutomaticBrightnessEnable
         : LegacyThemeManager.instance.automaticBrightnessIsOn
    }

    var isSystemThemeOn: Bool {
        return isReduxIntegrationEnabled ? themeState.useSystemAppearance : LegacyThemeManager.instance.systemThemeIsOn
    }

    init() {
        self.themeState = ThemeSettingsState()
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if isReduxIntegrationEnabled {
            store.dispatch(ThemeSettingsAction.themeSettingsDidAppear)
            store.subscribe(self, transform: {
                $0.select(ThemeSettingsState.init)
            })
        }

        title = .SettingsDisplayThemeTitle
        tableView.accessibilityIdentifier = "DisplayTheme.Setting.Options"
        tableView.register(cellType: ThemedSubtitleTableViewCell.self)
        tableView.register(ThemedTableSectionHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(systemBrightnessChanged),
                                               name: UIScreen.brightnessDidChangeNotification,
                                               object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isReduxIntegrationEnabled {
            store.unsubscribe(self)
        }
    }

    func newState(state: ThemeSettingsState) {
        themeState = state
        // Reload of tableView is needed to reflect the new state. Currently applyTheme calls tableview.reload
        applyTheme()
    }

    // MARK: - UI actions
    @objc
    func systemThemeSwitchValueChanged(control: UISwitch) {
        if isReduxIntegrationEnabled {
            store.dispatch(ThemeSettingsAction.toggleUseSystemAppearance(control.isOn))
        } else {
            LegacyThemeManager.instance.systemThemeIsOn = control.isOn
            themeManager.setSystemTheme(isOn: control.isOn)
        }

        if control.isOn {
            // Reset the user interface style to the default before choosing our theme
            UIApplication.shared.delegate?.window??.overrideUserInterfaceStyle = .unspecified
            let userInterfaceStyle = traitCollection.userInterfaceStyle
            LegacyThemeManager.instance.current = userInterfaceStyle == .dark ? LegacyDarkTheme() : LegacyNormalTheme()
        } else if LegacyThemeManager.instance.automaticBrightnessIsOn {
            LegacyThemeManager.instance.updateCurrentThemeBasedOnScreenBrightness()
        }

        // Switch animation must begin prior to scheduling table view update animation
        // (or the switch will be auto-synchronized to the slower tableview animation
        // and makes the switch behaviour feel slow and non-standard).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            UIView.transition(with: self.tableView, duration: 0.2, options: .transitionCrossDissolve, animations: { self.tableView.reloadData()  })
        }
    }

    @objc
    func systemBrightnessChanged() {
        guard LegacyThemeManager.instance.automaticBrightnessIsOn else { return }

        if isReduxIntegrationEnabled {
            store.dispatch(ThemeSettingsAction.receivedSystemBrightnessChange)
        }
        brightnessChanged()
    }

    /// Update Theme if user or system brightness change due to user action
    func brightnessChanged() {
        guard LegacyThemeManager.instance.automaticBrightnessIsOn else { return }

        if !isReduxIntegrationEnabled {
            LegacyThemeManager.instance.updateCurrentThemeBasedOnScreenBrightness()
        }
        applyTheme()
    }

    @objc
    func sliderValueChanged(control: UISlider, event: UIEvent) {
        guard let touch = event.allTouches?.first, touch.phase == .ended else { return }

        if isReduxIntegrationEnabled {
            store.dispatch(ThemeSettingsAction.updateUserBrightness(control.value))
        } else {
            themeManager.setAutomaticBrightnessValue(control.value)
            LegacyThemeManager.instance.automaticBrightnessValue = control.value
            brightnessChanged()
        }
    }

    private func makeSlider(parent: UIView) -> UISlider {
        let size = CGSize(width: UX.moonSunIconSize, height: UX.moonSunIconSize)
        let images = [ImageIdentifiers.nightMode, "themeBrightness"].map { name in
            UIImage(imageLiteralResourceName: name).createScaled(size).tinted(withColor: themeManager.currentTheme.colors.layerLightGrey30)
        }

        let slider: UISlider = .build { slider in
            slider.minimumValueImage = images[0]
            slider.maximumValueImage = images[1]
        }
        parent.addSubview(slider)

        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: parent.topAnchor, constant: 4),
            slider.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -4),
            slider.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: UX.sliderLeftRightInset),
            slider.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -UX.sliderLeftRightInset),
        ])
        return slider
    }

    // MARK: - UITableView
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = super.tableView(tableView, viewForHeaderInSection: section) as? ThemedTableSectionHeaderFooterView else { return nil }

        let section = Section(rawValue: section) ?? .automaticBrightness
        headerView.titleLabel.text = {
            switch section {
            case .systemTheme:
                return .SystemThemeSectionHeader
            case .automaticBrightness:
                return .ThemeSwitchModeSectionHeader
            case .lightDarkPicker:
                return isAutoBrightnessOn ? .DisplayThemeBrightnessThresholdSectionHeader : .ThemePickerSectionHeader
            }
        }()

        headerView.titleLabel.text = headerView.titleLabel.text?.uppercased()
        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard isAutoBrightnessOn && section == Section.lightDarkPicker.rawValue else { return nil }

        let footer = UIView()
        let label: UILabel = .build { label in
            label.text = .DisplayThemeSectionFooter
            label.numberOfLines = 0
            label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .footnote,
                                                                size: UX.footerFontSize)
            label.textColor = self.themeManager.currentTheme.colors.textSecondary
        }
        footer.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: footer.topAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: UX.sliderLeftRightInset),
            label.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -UX.sliderLeftRightInset),
        ])
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard isAutoBrightnessOn && section == Section.lightDarkPicker.rawValue else {
            return section == Section.automaticBrightness.rawValue ? UX.spaceBetweenTableSections : 1
        }
        // When auto is on, make footer arbitrarily large enough to handle large block of text.
        return 120
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCellFor(indexPath: indexPath)
        cell.selectionStyle = .none
        let section = Section(rawValue: indexPath.section) ?? .automaticBrightness
        switch section {
        case .systemTheme:
            cell.textLabel?.text = .SystemThemeSectionSwitchTitle
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping

            let control = UISwitch()
            control.accessibilityIdentifier = "SystemThemeSwitchValue"
            control.onTintColor = themeManager.currentTheme.colors.actionPrimary
            control.addTarget(self, action: #selector(systemThemeSwitchValueChanged), for: .valueChanged)
            if isReduxIntegrationEnabled {
                control.isOn = themeState.useSystemAppearance
            } else {
                control.isOn = LegacyThemeManager.instance.systemThemeIsOn
            }

            cell.accessoryView = control
        case .automaticBrightness:
            configureAutomaticBrightness(indexPath: indexPath, cell: cell)

        case .lightDarkPicker:
            configureLightDarkTheme(indexPath: indexPath, cell: cell)
        }
        cell.applyTheme(theme: themeManager.currentTheme)

        return cell
    }

    override func dequeueCellFor(indexPath: IndexPath) -> ThemedTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThemedSubtitleTableViewCell.cellIdentifier, for: indexPath) as? ThemedSubtitleTableViewCell
        else {
            return ThemedSubtitleTableViewCell()
        }
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSystemThemeOn ? 1 : 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.systemTheme.rawValue:
            return 1
        case Section.automaticBrightness.rawValue:
            return 2
        case Section.lightDarkPicker.rawValue:
            return isAutoBrightnessOn ? 1 : 2
        default:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Section.automaticBrightness.rawValue {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            toggleAutomaticBrightness(isOn: indexPath.row != 0)
        } else if indexPath.section == Section.lightDarkPicker.rawValue {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            changeManualTheme(isLightTheme: indexPath.row == 0)
        }
        applyTheme()
    }

    // MARK: - Helper functions
    private func toggleAutomaticBrightness(isOn: Bool) {
        if isReduxIntegrationEnabled {
            store.dispatch(ThemeSettingsAction.enableAutomaticBrightness(isOn))
        } else {
            LegacyThemeManager.instance.automaticBrightnessIsOn = isOn
            themeManager.setAutomaticBrightness(isOn: isOn)
        }

        tableView.reloadSections(IndexSet(integer: Section.lightDarkPicker.rawValue), with: .automatic)
        tableView.reloadSections(IndexSet(integer: Section.automaticBrightness.rawValue), with: .none)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .setting,
                                     value: isOn ? .themeModeManually : .themeModeAutomatically)
    }

    private func changeManualTheme(isLightTheme: Bool) {
        if isReduxIntegrationEnabled {
            let themeName: BuiltinThemeName = isLightTheme ? .normal : .dark
            store.dispatch(ThemeSettingsAction.switchManualTheme(themeName))
        } else {
            LegacyThemeManager.instance.current = isLightTheme ? LegacyNormalTheme() : LegacyDarkTheme()
            themeManager.changeCurrentTheme(isLightTheme ? .light : .dark)
        }
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .setting,
                                     value: isLightTheme ? .themeLight : .themeDark)
    }

    private func configureAutomaticBrightness(indexPath: IndexPath, cell: ThemedTableViewCell) {
        let isManualOption = indexPath.row == 0
        if isManualOption {
            cell.textLabel?.text = .DisplayThemeManualSwitchTitle
            cell.detailTextLabel?.text = .DisplayThemeManualSwitchSubtitle
        } else {
            cell.textLabel?.text = .DisplayThemeAutomaticSwitchTitle
            cell.detailTextLabel?.text = .DisplayThemeAutomaticSwitchSubtitle
        }
        cell.detailTextLabel?.numberOfLines = 2
        cell.detailTextLabel?.minimumScaleFactor = 0.5
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        if (isManualOption && !isAutoBrightnessOn) ||
            (!isManualOption && isAutoBrightnessOn) {
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }
    }

    private func configureLightDarkTheme(indexPath: IndexPath, cell: ThemedTableViewCell) {
        if isAutoBrightnessOn {
            configureAutomaticBrightness(cell: cell)
        } else {
            if indexPath.row == 0 {
                cell.textLabel?.text = .DisplayThemeOptionLight
            } else {
                cell.textLabel?.text = .DisplayThemeOptionDark
            }

            let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
            if (indexPath.row == 0 && theme == .normal) ||
                (indexPath.row == 1 && theme == .dark) {
                cell.accessoryType = .checkmark
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                cell.accessoryType = .none
            }
        }
    }

    private func configureAutomaticBrightness(cell: ThemedTableViewCell) {
        let deviceBrightnessIndicator = makeSlider(parent: cell.contentView)
        let slider = makeSlider(parent: cell.contentView)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        if isReduxIntegrationEnabled {
            slider.value = themeState.userBrightnessThreshold
            deviceBrightnessIndicator.value = themeState.systemBrightness
        } else {
            slider.value = Float(LegacyThemeManager.instance.automaticBrightnessValue)
            deviceBrightnessIndicator.value = Float(UIScreen.main.brightness)
        }
        deviceBrightnessIndicator.isUserInteractionEnabled = false
        deviceBrightnessIndicator.minimumTrackTintColor = .clear
        deviceBrightnessIndicator.maximumTrackTintColor = .clear
        deviceBrightnessIndicator.thumbTintColor = themeManager.currentTheme.colors.formKnob
        self.slider = (slider, deviceBrightnessIndicator)
    }
}
