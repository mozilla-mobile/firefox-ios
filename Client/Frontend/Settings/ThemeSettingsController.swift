/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class ThemeSettingsController: ThemedTableViewController {
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

    fileprivate let SectionHeaderIdentifier = "SectionHeaderIdentifier"

    // A non-interactable slider is underlaid to show the current screen brightness indicator
    private var slider: (control: UISlider, deviceBrightnessIndicator: UISlider)?

    // TODO decide if this is themeable, or if it is being replaced by a different style of slider
    private let deviceBrightnessIndicatorColor = UIColor(white: 182/255, alpha: 1.0)

    var isAutoBrightnessOn: Bool {
        return ThemeManager.instance.automaticBrightnessIsOn
    }

    var isSystemThemeOn: Bool {
        return ThemeManager.instance.systemThemeIsOn
    }

    private var shouldHideSystemThemeSection: Bool = {
        if #available(iOS 13.0, *) {
            return false
        } else {
            return true
        }
    }()

    init() {
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsDisplayThemeTitle
        tableView.accessibilityIdentifier = "DisplayTheme.Setting.Options"
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground

        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderIdentifier)

        NotificationCenter.default.addObserver(self, selector: #selector(brightnessChanged), name: UIScreen.brightnessDidChangeNotification, object: nil)
    }

    @objc func brightnessChanged() {
        guard ThemeManager.instance.automaticBrightnessIsOn else { return }
        ThemeManager.instance.updateCurrentThemeBasedOnScreenBrightness()
        applyTheme()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier) as! ThemedTableSectionHeaderFooterView
        let section = Section(rawValue: section) ?? .automaticBrightness
        headerView.titleLabel.text = {
            switch section {
            case .systemTheme:
                return Strings.SystemThemeSectionHeader
            case .automaticBrightness:
                return Strings.ThemeSwitchModeSectionHeader
            case .lightDarkPicker:
                return isAutoBrightnessOn ? Strings.DisplayThemeBrightnessThresholdSectionHeader : Strings.ThemePickerSectionHeader
            }
        }()
        headerView.titleLabel.text = headerView.titleLabel.text?.uppercased()

        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard isAutoBrightnessOn && section == Section.lightDarkPicker.rawValue else { return nil }

        let footer = UIView()
        let label = UILabel()
        footer.addSubview(label)
        label.text = Strings.DisplayThemeSectionFooter
        label.numberOfLines = 0
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.left.right.equalToSuperview().inset(16)
        }
        label.font = UIFont.systemFont(ofSize: UX.footerFontSize)
        label.textColor = UIColor.theme.tableView.headerTextLight
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == Section.systemTheme.rawValue else {
            return UITableView.automaticDimension
        }

        if shouldHideSystemThemeSection {
            return CGFloat.leastNonzeroMagnitude
        } else {
            return UITableView.automaticDimension
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard isAutoBrightnessOn && section == Section.lightDarkPicker.rawValue else {
            return section == Section.automaticBrightness.rawValue ? UX.spaceBetweenTableSections : 1
        }
        // When auto is on, make footer arbitrarily large enough to handle large block of text.
        return 120
    }

    @objc func systemThemeSwitchValueChanged(control: UISwitch) {
        ThemeManager.instance.systemThemeIsOn = control.isOn
        if #available(iOS 13.0, *) {
            let userInterfaceStyle = traitCollection.userInterfaceStyle
            if control.isOn {
                ThemeManager.instance.current = userInterfaceStyle == .dark ? DarkTheme() : NormalTheme()
            } else if ThemeManager.instance.automaticBrightnessIsOn {
                ThemeManager.instance.updateCurrentThemeBasedOnScreenBrightness()
            }
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .setting, value: .systemThemeSwitch, extras: ["to": control.isOn])
        }
        // Switch animation must begin prior to scheduling table view update animation (or the switch will be auto-synchronized to the slower tableview animation and makes the switch behaviour feel slow and non-standard).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.transition(with: self.tableView, duration: 0.2, options: .transitionCrossDissolve, animations: { self.tableView.reloadData()  })
        }
    }

    @objc func sliderValueChanged(control: UISlider, event: UIEvent) {
        guard let touch = event.allTouches?.first, touch.phase == .ended else {
            return
        }

        ThemeManager.instance.automaticBrightnessValue = control.value
        brightnessChanged()
    }

    private func makeSlider(parent: UIView) -> UISlider {
        let slider = UISlider()
        parent.addSubview(slider)
        let size = CGSize(width: UX.moonSunIconSize, height: UX.moonSunIconSize)
        let images = ["menu-NightMode", "themeBrightness"].map { name in
            UIImage(imageLiteralResourceName: name).createScaled(size).tinted(withColor: UIColor.theme.browser.tint)
        }
        slider.minimumValueImage = images[0]
        slider.maximumValueImage = images[1]

        slider.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(UX.sliderLeftRightInset)
        }
        return slider
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        let section = Section(rawValue: indexPath.section) ?? .automaticBrightness
        switch section {
        case .systemTheme:
            cell.textLabel?.text = Strings.SystemThemeSectionSwitchTitle
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping

            let control = UISwitchThemed()

            control.accessibilityIdentifier = "SystemThemeSwitchValue"
            control.onTintColor = UIColor.theme.tableView.controlTint
            control.addTarget(self, action: #selector(systemThemeSwitchValueChanged), for: .valueChanged)
            control.isOn = ThemeManager.instance.systemThemeIsOn
            cell.accessoryView = control
        case .automaticBrightness:
            if indexPath.row == 0 {
                cell.textLabel?.text = Strings.DisplayThemeManualSwitchTitle
                cell.detailTextLabel?.text = Strings.DisplayThemeManualSwitchSubtitle
            } else {
                cell.textLabel?.text = Strings.DisplayThemeAutomaticSwitchTitle
                cell.detailTextLabel?.text = Strings.DisplayThemeAutomaticSwitchSubtitle
            }
            cell.detailTextLabel?.numberOfLines = 2
            cell.detailTextLabel?.minimumScaleFactor = 0.5
            cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
            if (indexPath.row == 0 && !isAutoBrightnessOn) ||
                (indexPath.row == 1 && isAutoBrightnessOn) {
                cell.accessoryType = .checkmark
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                cell.accessoryType = .none
            }

        case .lightDarkPicker:
            if isAutoBrightnessOn {
                let deviceBrightnessIndicator = makeSlider(parent: cell.contentView)
                let slider = makeSlider(parent: cell.contentView)
                slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
                slider.value = Float(ThemeManager.instance.automaticBrightnessValue)
                deviceBrightnessIndicator.value = Float(UIScreen.main.brightness)
                deviceBrightnessIndicator.isUserInteractionEnabled = false
                deviceBrightnessIndicator.minimumTrackTintColor = .clear
                deviceBrightnessIndicator.maximumTrackTintColor = .clear
                deviceBrightnessIndicator.thumbTintColor = deviceBrightnessIndicatorColor
                self.slider = (slider, deviceBrightnessIndicator)
            } else {
                if indexPath.row == 0 {
                    cell.textLabel?.text = Strings.DisplayThemeOptionLight
                } else {
                    cell.textLabel?.text = Strings.DisplayThemeOptionDark
                }

                let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
                if (indexPath.row == 0 && theme == .normal) ||
                    (indexPath.row == 1 && theme == .dark) {
                    cell.accessoryType = .checkmark
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                } else {
                    cell.accessoryType = .none
                }
            }
        }

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if shouldHideSystemThemeSection {
            return 3
        } else {
            return isSystemThemeOn ? 1 : 3
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.systemTheme.rawValue:
            if #available(iOS 13.0, *) {
                return 1
            } else {
                return 0
            }
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
            ThemeManager.instance.automaticBrightnessIsOn = indexPath.row != 0
            tableView.reloadSections(IndexSet(integer: Section.lightDarkPicker.rawValue), with: .automatic)
            tableView.reloadSections(IndexSet(integer: Section.automaticBrightness.rawValue), with: .none)
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .setting, value: indexPath.row == 0 ? .themeModeManually : .themeModeAutomatically)
        } else if indexPath.section == Section.lightDarkPicker.rawValue {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            ThemeManager.instance.current = indexPath.row == 0 ? NormalTheme() : DarkTheme()
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .setting, value: indexPath.row == 0 ? .themeLight : .themeDark)
        }
        applyTheme()
    }
}
