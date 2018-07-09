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
        case automaticOnOff
        case lightDarkPicker
    }

    // A non-interactable slider is underlaid to show the current screen brightness indicator
    private var slider: (control: UISlider, deviceBrightnessIndicator: UISlider)?

    // TODO decide if this is themeable, or if it is being replaced by a different style of slider
    private let deviceBrightnessIndicatorColor = UIColor(white: 182/255, alpha: 1.0)

    var isAutoBrightnessOn: Bool {
        return ThemeManager.instance.automaticBrightnessIsOn
    }

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

        let headerFooterFrame = CGRect(width: self.view.frame.width, height: SettingsUX.TableViewHeaderFooterHeight)
        let headerView = ThemedTableSectionHeaderFooterView(frame: headerFooterFrame)
        headerView.showTopBorder = false
        headerView.showBottomBorder = true
        tableView.tableHeaderView = headerView
        headerView.titleLabel.text = Strings.DisplayThemeSectionHeader

        NotificationCenter.default.addObserver(self, selector: #selector(brightnessChanged), name: .UIScreenBrightnessDidChange, object: nil)
    }

    @objc func brightnessChanged() {
        guard ThemeManager.instance.automaticBrightnessIsOn else { return }
        ThemeManager.instance.updateCurrentThemeBasedOnScreenBrightness()
        applyTheme()
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard isAutoBrightnessOn else { return nil }

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
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard isAutoBrightnessOn else {
            return section == Section.automaticOnOff.rawValue ? UX.spaceBetweenTableSections : 1
        }
        // When auto is on, make footer arbitrarily large enough to handle large block of text.
        return 120
    }

    @objc func switchValueChanged(control: UISwitch) {
        ThemeManager.instance.automaticBrightnessIsOn = control.isOn

        // Switch animation must begin prior to scheduling table view update animation (or the switch will be auto-synchronized to the slower tableview animation and makes the switch behaviour feel slow and non-standard).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.transition(with: self.tableView, duration: 0.2, options: .transitionCrossDissolve, animations: { self.tableView.reloadData()  })
        }
    }

    @objc func sliderValueChanged(control: UISlider) {
        ThemeManager.instance.automaticBrightnessValue = control.value

        brightnessChanged()
    }

    private func makeSlider(parent: UIView) -> UISlider {
        let slider = UISlider()
        parent.addSubview(slider)
        let size = CGSize(width: UX.moonSunIconSize, height: UX.moonSunIconSize)
        slider.minimumValueImage = UIImage(imageLiteralResourceName: "menu-NightMode").createScaled(size)
        slider.maximumValueImage = UIImage(imageLiteralResourceName: "themeBrightness").createScaled(size)

        slider.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(UX.sliderLeftRightInset)
        }
        return slider
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none

        let section = Section(rawValue: indexPath.section) ?? .automaticOnOff
        switch section {
        case .automaticOnOff:
            if indexPath.row == 0 {
                cell.textLabel?.text = Strings.DisplayThemeAutomaticSwitchTitle
                cell.detailTextLabel?.text = Strings.DisplayThemeAutomaticSwitchSubtitle

                let control = UISwitch()
                control.onTintColor = UIColor.theme.tableView.controlTint
                control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
                control.isOn = ThemeManager.instance.automaticBrightnessIsOn
                cell.accessoryView = control
            } else {
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
            }

        case .lightDarkPicker:
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

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return isAutoBrightnessOn ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isAutoBrightnessOn ? 2 : (section == Section.automaticOnOff.rawValue ? 1 : 2)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == Section.automaticOnOff.rawValue ? UX.rowHeight : super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section > 0 else { return }

        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        ThemeManager.instance.current = indexPath.row == 0 ? NormalTheme() : DarkTheme()
        applyTheme()
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
