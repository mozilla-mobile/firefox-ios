// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared
import ComponentLibrary
import UIKit

class ThemeSettingsController: ThemedTableViewController, StoreSubscriber, Notifiable {
    typealias SubscriberStateType = ThemeSettingsState
    struct UX {
        static let rowHeight: CGFloat = 70
        static let moonSunIconSize: CGFloat = 18
        static let sliderLeftRightInset: CGFloat = 16
        static let spaceBetweenTableSections: CGFloat = 20
        static let accentSwatchItemSize: CGFloat = 52
        static let accentCollectionHeight: CGFloat = 60
        static let accentItemCount = 6 // 5 presets + 1 custom
    }

    enum Section: Int {
        case systemTheme
        case automaticBrightness
        case lightDarkPicker
        case accentColor
    }

    /// Returns the list of sections currently visible, accounting for system theme state.
    private var allSections: [Section] {
        if isSystemThemeOn {
            return [.systemTheme, .accentColor]
        } else {
            return [.systemTheme, .automaticBrightness, .lightDarkPicker, .accentColor]
        }
    }

    /// Maps a table view section index to its Section case.
    private func sectionFor(_ sectionIndex: Int) -> Section {
        guard sectionIndex < allSections.count else { return .systemTheme }
        return allSections[sectionIndex]
    }

    /// Returns the table view section index for a given Section case, or nil if not visible.
    private func indexForSection(_ section: Section) -> Int? {
        return allSections.firstIndex(of: section)
    }

    private var themeState: ThemeSettingsState

    // A non-interactable slider is underlaid to show the current screen brightness indicator
    private var slider: (control: UISlider, deviceBrightnessIndicator: UISlider)?

    /// Embedded collection view for accent color swatches
    private var accentCollectionView: UICollectionView?

    var isAutoBrightnessOn: Bool {
        return themeState.isAutomaticBrightnessEnabled
    }

    var isSystemThemeOn: Bool {
        return themeState.useSystemAppearance
    }

    var manualThemeType: ThemeType {
        return themeState.manualThemeSelected
    }

    init(windowUUID: WindowUUID) {
        self.themeState = ThemeSettingsState(windowUUID: windowUUID)
        super.init(style: .grouped, windowUUID: windowUUID)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToRedux()

        title = .SettingsDisplayThemeTitle
        tableView.accessibilityIdentifier = "DisplayTheme.Setting.Options"
        tableView.register(cellType: ThemedSubtitleTableViewCell.self)
        tableView.register(ThemedTableSectionHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier)

        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [
                UIScreen.brightnessDidChangeNotification
            ]
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromRedux()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        let action = ThemeSettingsViewAction(windowUUID: windowUUID,
                                             actionType: ThemeSettingsViewActionType.themeSettingsDidAppear)
        store.dispatch(action)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return ThemeSettingsState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .themeSettings)
        store.dispatch(action)
    }

    func newState(state: ThemeSettingsState) {
        themeState = state
        // Reload of tableView is needed to reflect the new state. Currently applyTheme calls tableview.reload
        applyTheme()
    }

    // MARK: - UI actions
    @objc
    func systemThemeSwitchValueChanged(control: UISwitch) {
        let action = ThemeSettingsViewAction(useSystemAppearance: control.isOn,
                                             windowUUID: windowUUID,
                                             actionType: ThemeSettingsViewActionType.toggleUseSystemAppearance)
        store.dispatch(action)

        // Switch animation must begin prior to scheduling table view update animation
        // (or the switch will be auto-synchronized to the slower tableview animation
        // and makes the switch behaviour feel slow and non-standard).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            UIView.transition(with: self.tableView,
                              duration: 0.2,
                              options: .transitionCrossDissolve,
                              animations: {
                self.tableView.reloadData()
            })
        }
    }

    nonisolated func systemBrightnessChanged() {
        ensureMainThread {
            guard self.themeState.isAutomaticBrightnessEnabled else { return }

            let action = ThemeSettingsViewAction(windowUUID: self.windowUUID,
                                                 actionType: ThemeSettingsViewActionType.receivedSystemBrightnessChange)
            store.dispatch(action)

            self.brightnessChanged()
        }
    }

    /// Update Theme if user or system brightness change due to user action
    func brightnessChanged() {
        guard themeState.isAutomaticBrightnessEnabled else { return }

        applyTheme()
    }

    @objc
    func sliderValueChanged(control: UISlider, event: UIEvent) {
        guard let touch = event.allTouches?.first, touch.phase == .ended else { return }

        let action = ThemeSettingsViewAction(userBrightness: control.value,
                                             windowUUID: windowUUID,
                                             actionType: ThemeSettingsViewActionType.updateUserBrightness)
        store.dispatch(action)
    }

    private func makeSlider(parent: UIView) -> UISlider {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let size = CGSize(width: UX.moonSunIconSize, height: UX.moonSunIconSize)
        let images = [StandardImageIdentifiers.Medium.nightMode, StandardImageIdentifiers.Medium.sun].map { name in
            UIImage(imageLiteralResourceName: name)
                .createScaled(size)
                .tinted(withColor: theme.colors.iconSecondary)
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

    // MARK: - Accent Color Helpers

    private func makeAccentCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: UX.accentSwatchItemSize, height: UX.accentSwatchItemSize)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0,
                                           left: UX.sliderLeftRightInset,
                                           bottom: 0,
                                           right: UX.sliderLeftRightInset)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(AccentColorCell.self, forCellWithReuseIdentifier: AccentColorCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }

    private func dispatchAccentColorChange(_ accentColor: AccentColor) {
        let action = ThemeSettingsViewAction(accentColor: accentColor,
                                             windowUUID: windowUUID,
                                             actionType: ThemeSettingsViewActionType.switchAccentColor)
        store.dispatch(action)
    }

    private func presentColorPicker() {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.delegate = self

        // Pre-select current custom color if any
        if case .custom(let hex) = themeState.accentColor,
           let currentColor = UIColor(accentHex: hex) {
            picker.selectedColor = currentColor
        }

        present(picker, animated: true)
    }

    /// Returns the custom swatch UIColor if the user has a custom accent set, or nil.
    private var customSwatchColor: UIColor? {
        if case .custom(let hex) = themeState.accentColor {
            return UIColor(accentHex: hex)
        }
        return nil
    }

    /// Whether the currently selected accent is a custom color.
    private var isCustomAccentSelected: Bool {
        if case .custom = themeState.accentColor { return true }
        return false
    }

    // MARK: - UITableView
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = super.tableView(
            tableView,
            viewForHeaderInSection: section
        ) as? ThemedTableSectionHeaderFooterView else { return nil }

        let sectionType = sectionFor(section)
        headerView.titleLabel.text = {
            switch sectionType {
            case .systemTheme:
                return .SystemThemeSectionHeader
            case .automaticBrightness:
                return .ThemeSwitchModeSectionHeader
            case .lightDarkPicker:
                return isAutoBrightnessOn ? .DisplayThemeBrightnessThresholdSectionHeader : .ThemePickerSectionHeader
            case .accentColor:
                return "Accent Color"
            }
        }()

        headerView.titleLabel.text = headerView.titleLabel.text?.uppercased()
        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sectionType = sectionFor(section)
        guard isAutoBrightnessOn && sectionType == .lightDarkPicker else { return nil }

        let footer = UIView()
        let label: UILabel = .build { label in
            label.text = .DisplayThemeSectionFooter
            label.numberOfLines = 0
            label.font = FXFontStyles.Regular.caption1.scaledFont()
            label.textColor = self.themeManager.getCurrentTheme(for: self.windowUUID).colors.textSecondary
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
        let sectionType = sectionFor(section)
        guard isAutoBrightnessOn && sectionType == .lightDarkPicker else {
            return sectionType == .automaticBrightness ? UX.spaceBetweenTableSections : 1
        }
        // When auto is on, make footer arbitrarily large enough to handle large block of text.
        return 120
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = sectionFor(indexPath.section)

        if sectionType == .accentColor {
            return configureAccentColorCell(for: tableView, at: indexPath)
        }

        let cell = dequeueCellFor(indexPath: indexPath)
        cell.selectionStyle = .none
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        switch sectionType {
        case .systemTheme:
            cell.textLabel?.text = .SystemThemeSectionSwitchTitle
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping

            let control = ThemedSwitch()
            control.applyTheme(theme: theme)
            control.accessibilityIdentifier = "SystemThemeSwitchValue"
            control.onTintColor = theme.colors.actionPrimary
            control.addTarget(self, action: #selector(systemThemeSwitchValueChanged), for: .valueChanged)
            control.isOn = themeState.useSystemAppearance

            cell.accessoryView = control
        case .automaticBrightness:
            configureAutomaticBrightness(indexPath: indexPath, cell: cell)

        case .lightDarkPicker:
            configureLightDarkTheme(indexPath: indexPath, cell: cell)

        case .accentColor:
            break // Handled above
        }
        cell.applyTheme(theme: theme)

        return cell
    }

    private func configureAccentColorCell(
        for tableView: UITableView,
        at indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "AccentColorHostCell")
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let collectionView = makeAccentCollectionView()
        accentCollectionView = collectionView
        cell.contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
            collectionView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
            collectionView.heightAnchor.constraint(equalToConstant: UX.accentCollectionHeight),
        ])

        let theme = themeManager.getCurrentTheme(for: windowUUID)
        cell.contentView.backgroundColor = theme.colors.layer5
        return cell
    }

    override func dequeueCellFor(indexPath: IndexPath) -> ThemedTableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ThemedSubtitleTableViewCell.cellIdentifier,
            for: indexPath
        ) as? ThemedSubtitleTableViewCell
        else {
            return ThemedSubtitleTableViewCell()
        }
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return allSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = sectionFor(section)
        switch sectionType {
        case .systemTheme:
            return 1
        case .automaticBrightness:
            return 2
        case .lightDarkPicker:
            return isAutoBrightnessOn ? 1 : 2
        case .accentColor:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionType = sectionFor(indexPath.section)
        if sectionType == .automaticBrightness {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            toggleAutomaticBrightness(isOn: indexPath.row != 0)
        } else if sectionType == .lightDarkPicker {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            changeManualTheme(isLightTheme: indexPath.row == 0)
        }
        // Accent color selection is handled by the embedded collection view delegate
        applyTheme()
    }

    // MARK: - Helper functions
    private func toggleAutomaticBrightness(isOn: Bool) {
        let action = ThemeSettingsViewAction(automaticBrightnessEnabled: isOn,
                                             windowUUID: windowUUID,
                                             actionType: ThemeSettingsViewActionType.enableAutomaticBrightness)
        store.dispatch(action)

        if let lightDarkIndex = indexForSection(.lightDarkPicker),
           let autoBrightnessIndex = indexForSection(.automaticBrightness) {
            tableView.reloadSections(IndexSet(integer: lightDarkIndex), with: .automatic)
            tableView.reloadSections(IndexSet(integer: autoBrightnessIndex), with: .none)
        }
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .press,
                                     object: .setting,
                                     value: isOn ? .themeModeManually : .themeModeAutomatically)
    }

    private func changeManualTheme(isLightTheme: Bool) {
        let theme: ThemeType = isLightTheme ? .light : .dark
        let action = ThemeSettingsViewAction(manualThemeType: theme,
                                             windowUUID: windowUUID,
                                             actionType: ThemeSettingsViewActionType.switchManualTheme)
        store.dispatch(action)

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

            if (indexPath.row == 0 && manualThemeType == .light) ||
                (indexPath.row == 1 && manualThemeType == .dark) {
                cell.accessoryType = .checkmark
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                cell.accessoryType = .none
            }
        }
    }

    private func configureAutomaticBrightness(cell: ThemedTableViewCell) {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let deviceBrightnessIndicator = makeSlider(parent: cell.contentView)
        let slider = makeSlider(parent: cell.contentView)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.value = themeState.userBrightnessThreshold
        deviceBrightnessIndicator.value = themeState.systemBrightness
        deviceBrightnessIndicator.isUserInteractionEnabled = false
        deviceBrightnessIndicator.minimumTrackTintColor = .clear
        deviceBrightnessIndicator.maximumTrackTintColor = .clear
        deviceBrightnessIndicator.thumbTintColor = theme.colors.formKnob
        self.slider = (slider, deviceBrightnessIndicator)
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIScreen.brightnessDidChangeNotification:
            ensureMainThread {
                self.systemBrightnessChanged
            }
        default:
            return
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ThemeSettingsController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return UX.accentItemCount
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AccentColorCell.reuseIdentifier,
            for: indexPath
        ) as? AccentColorCell else {
            return UICollectionViewCell()
        }

        let presets = AccentColor.presets
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        if indexPath.item < presets.count {
            let preset = presets[indexPath.item]
            let isSelected = themeState.accentColor == preset
            cell.configure(accentColor: preset, isSelected: isSelected)
        } else {
            // Custom swatch (last item)
            cell.configureAsCustom(color: customSwatchColor, isSelected: isCustomAccentSelected)
        }

        cell.applyTheme(theme: theme)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ThemeSettingsController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let presets = AccentColor.presets
        if indexPath.item < presets.count {
            dispatchAccentColorChange(presets[indexPath.item])
        } else {
            // Custom swatch tapped — present color picker
            presentColorPicker()
        }
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension ThemeSettingsController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let hex = viewController.selectedColor.accentHexString()
        dispatchAccentColorChange(.custom(hex: hex))
    }

    func colorPickerViewController(
        _ viewController: UIColorPickerViewController,
        didSelect color: UIColor,
        continuously: Bool
    ) {
        // Only commit on final selection (not continuous updates)
        guard !continuously else { return }
        let hex = color.accentHexString()
        dispatchAccentColorChange(.custom(hex: hex))
    }
}
