// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Common
import Shared
import UIKit

struct SettingsUX {
    static let TableViewHeaderFooterHeight = CGFloat(44)
}

extension UILabel {
    // iOS bug: NSAttributed string color is ignored without setting font/color to nil
    func assign(attributed: NSAttributedString?, theme: Theme) {
        guard let attributed = attributed else { return }
        let attribs = attributed.attributes(at: 0, effectiveRange: nil)
        if attribs[NSAttributedString.Key.foregroundColor] == nil {
            // If the text color attribute isn't set, use textPrimary
            textColor = theme.colors.textPrimary
        } else {
            textColor = nil
        }
        attributedText = attributed
    }
}

// A base setting class that shows a title. You probably want to subclass this, not use it directly.
class Setting: NSObject {
    private var _title: NSAttributedString?
    private var _footerTitle: NSAttributedString?
    private var _cellHeight: CGFloat?
    private var _image: UIImage?
    var theme: Theme?

    weak var delegate: SettingsDelegate?

    // The url the SettingsContentViewController will show, e.g. Licenses and Privacy Policy.
    var url: URL? { return nil }

    // The title shown on the pref.
    var title: NSAttributedString? { return _title }
    var footerTitle: NSAttributedString? { return _footerTitle }
    var cellHeight: CGFloat? { return _cellHeight}
    fileprivate(set) var accessibilityIdentifier: String?

    // An optional second line of text shown on the pref.
    var status: NSAttributedString? { return nil }

    // Whether or not to show this pref.
    var hidden: Bool { return false }

    var style: UITableViewCell.CellStyle { return .subtitle }

    var accessoryType: UITableViewCell.AccessoryType { return .none }

    var accessoryView: UIImageView? { return nil }

    var textAlignment: NSTextAlignment { return .natural }

    var image: UIImage? { return _image }

    var enabled = true

    private lazy var backgroundView: UIView = .build()

    func accessoryButtonTapped() { onAccessoryButtonTapped?() }
    var onAccessoryButtonTapped: (() -> Void)?

    // Called when the cell is setup. Call if you need the default behaviour.
    func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        self.theme = theme
        cell.detailTextLabel?.assign(attributed: status, theme: theme)
        cell.detailTextLabel?.attributedText = status
        cell.detailTextLabel?.numberOfLines = 0
        if let cell = cell as? ThemedCenteredTableViewCell {
            cell.applyTheme(theme: theme)
            if let title = title?.string {
                cell.setTitle(to: title)
                cell.accessibilityLabel = title
            }
        } else {
            cell.textLabel?.assign(attributed: title, theme: theme)
            cell.textLabel?.textAlignment = textAlignment
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byTruncatingTail
            if let title = title?.string {
                if let detailText = cell.detailTextLabel?.text {
                    cell.accessibilityLabel = "\(title), \(detailText)"
                } else if let status = status?.string {
                    cell.accessibilityLabel = "\(title), \(status)"
                } else {
                    cell.accessibilityLabel = title
                }
            }
        }
        cell.accessoryType = accessoryType
        cell.accessoryView = accessoryView
        cell.selectionStyle = enabled ? .default : .none
        cell.accessibilityIdentifier = accessibilityIdentifier
        cell.imageView?.image = _image
        cell.accessibilityTraits = UIAccessibilityTraits.button
        cell.indentationWidth = 0
        cell.layoutMargins = .zero
        cell.isUserInteractionEnabled = enabled

        backgroundView.backgroundColor = theme.colors.layer5Hover
        backgroundView.bounds = cell.bounds
        cell.selectedBackgroundView = backgroundView

        // So that the separator line goes all the way to the left edge.
        cell.separatorInset = .zero
        if let cell = cell as? ThemedTableViewCell {
            cell.applyTheme(theme: theme)
        }
    }

    // Called when the pref is tapped.
    func onClick(_ navigationController: UINavigationController?) { return }

    // Called when the pref is long-pressed.
    func onLongPress(_ navigationController: UINavigationController?) { return }

    init(
        title: NSAttributedString? = nil,
        footerTitle: NSAttributedString? = nil,
        cellHeight: CGFloat? = nil,
        delegate: SettingsDelegate? = nil,
        enabled: Bool? = nil
    ) {
        self._title = title
        self._footerTitle = footerTitle
        self._cellHeight = cellHeight
        self.delegate = delegate
        self.enabled = enabled ?? true
    }
}

// A setting in the sections panel. Contains a sublist of Settings
class SettingSection: Setting {
    let children: [Setting]

    init(
        title: NSAttributedString? = nil,
        footerTitle: NSAttributedString? = nil,
        cellHeight: CGFloat? = nil,
        children: [Setting]
    ) {
        self.children = children
        super.init(title: title, footerTitle: footerTitle, cellHeight: cellHeight)
    }

    var count: Int {
        var count = 0
        for setting in children where !setting.hidden {
            count += 1
        }
        return count
    }

    subscript(val: Int) -> Setting? {
        var i = 0
        for setting in children where !setting.hidden {
            if i == val {
                return setting
            }
            i += 1
        }
        return nil
    }
}

class PaddedSwitch: UIView {
    private struct UX {
        static let padding: CGFloat = 8
    }

    let switchView: UISwitch

    init() {
        self.switchView = UISwitch()
        super.init(frame: .zero)

        addSubview(switchView)

        frame.size = CGSize(
            width: switchView.frame.width + UX.padding,
            height: switchView.frame.height
        )
        switchView.frame.origin = CGPoint(x: UX.padding, y: 0)
    }

    func configureSwitch(onTintColor: UIColor, isEnabled: Bool) {
        switchView.onTintColor = onTintColor
        switchView.isEnabled = isEnabled
    }

    func setSwitchTappable(to value: Bool) {
        switchView.isEnabled = value
    }

    func toggleSwitch(to value: Bool, animated: Bool = true) {
        switchView.setOn(value, animated: animated)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// A helper class for settings with a UISwitch.
// Takes and optional settingsDidChange callback and status text.
class BoolSetting: Setting, FeatureFlaggable {
    // Sometimes a subclass will manage its own pref setting. In that case the prefkey will be nil
    let prefKey: String?
    let prefs: Prefs?

    var settingDidChange: ((Bool) -> Void)?
    private let defaultValue: Bool?
    private let statusText: NSAttributedString?
    private let featureFlagName: NimbusFeatureFlagID?

    init(
        prefs: Prefs?,
        prefKey: String? = nil,
        defaultValue: Bool?,
        attributedTitleText: NSAttributedString,
        attributedStatusText: NSAttributedString? = nil,
        featureFlagName: NimbusFeatureFlagID? = nil,
        settingDidChange: ((Bool) -> Void)? = nil
    ) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.statusText = attributedStatusText
        self.featureFlagName = featureFlagName
        super.init(title: attributedTitleText)
    }

    convenience init(
        prefs: Prefs,
        theme: Theme,
        prefKey: String? = nil,
        defaultValue: Bool,
        titleText: String,
        statusText: String? = nil,
        settingDidChange: ((Bool) -> Void)? = nil
    ) {
        var statusTextAttributedString: NSAttributedString?
        if let statusTextString = statusText {
            let attributes = [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]
            statusTextAttributedString = NSAttributedString(string: statusTextString,
                                                            attributes: attributes)
        }
        self.init(
            prefs: prefs,
            prefKey: prefKey,
            defaultValue: defaultValue,
            attributedTitleText: NSAttributedString(
                string: titleText,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]),
            attributedStatusText: statusTextAttributedString,
            settingDidChange: settingDidChange)
    }

    init(
        title: String,
        description: String? = nil,
        prefs: Prefs?,
        prefKey: String? = nil,
        defaultValue: Bool = false,
        featureFlagName: NimbusFeatureFlagID? = nil,
        enabled: Bool = true,
        settingDidChange: @escaping (Bool) -> Void
    ) {
        self.statusText = description.map(NSAttributedString.init(string:))
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.featureFlagName = featureFlagName
        self.settingDidChange = settingDidChange
        super.init(title: NSAttributedString(string: title), enabled: enabled)
    }

    convenience init(
        with featureFlagID: NimbusFeatureFlagID,
        titleText: NSAttributedString,
        statusText: NSAttributedString? = nil,
        settingDidChange: ((Bool) -> Void)? = nil
    ) {
        self.init(
            prefs: nil,
            defaultValue: nil,
            attributedTitleText: titleText,
            attributedStatusText: statusText,
            featureFlagName: featureFlagID,
            settingDidChange: settingDidChange)
    }

    override var status: NSAttributedString? {
        return statusText
    }

    public lazy var control: PaddedSwitch = {
        let control = PaddedSwitch()
        control.switchView.accessibilityIdentifier = prefKey
        control.switchView.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        return control
    }()

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)

        control.configureSwitch(
            onTintColor: theme.colors.actionPrimary,
            isEnabled: enabled
        )

        displayBool(control.switchView)
        if let title = title {
            if let status = status {
                control.switchView.accessibilityLabel = "\(title.string), \(status.string)"
            } else {
                control.switchView.accessibilityLabel = title.string
            }
            cell.accessibilityLabel = nil
        }

        cell.accessoryView = control
        cell.selectionStyle = .none

        if !enabled {
            cell.subviews.forEach { $0.alpha = 0.5 }
        }
    }

    @objc
    func switchValueChanged(_ control: UISwitch) {
        writeBool(control)
        settingDidChange?(control.isOn)
        if let featureFlagName = featureFlagName {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .change,
                                         object: .setting,
                                         extras: ["pref": featureFlagName.rawValue as Any,
                                                  "to": control.isOn])
        } else {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .change,
                                         object: .setting,
                                         extras: ["pref": prefKey as Any, "to": control.isOn])
        }
    }

    func getFeatureFlagName() -> NimbusFeatureFlagID? {
        return featureFlagName
    }

    func getDefaultValue() -> Bool? {
        return defaultValue
    }

    // These methods allow a subclass to control how the pref is saved
    func displayBool(_ control: UISwitch) {
        if let featureFlagName = featureFlagName {
            control.isOn = featureFlags.isFeatureEnabled(featureFlagName, checking: .userOnly)
        } else {
            guard let key = prefKey, let defaultValue = defaultValue else { return }
            control.isOn = prefs?.boolForKey(key) ?? defaultValue
        }
    }

    func writeBool(_ control: UISwitch) {
        if let featureFlagName = featureFlagName {
            featureFlags.set(feature: featureFlagName, to: control.isOn)
        } else {
            guard let key = prefKey else { return }
            prefs?.setBool(control.isOn, forKey: key)
        }
    }
}

class BoolNotificationSetting: BoolSetting {
    var userDefaults: UserDefaultsInterface? = UserDefaults.standard

    override func displayBool(_ control: UISwitch) {
        if let featureFlagName = getFeatureFlagName() {
            control.isOn = featureFlags.isFeatureEnabled(featureFlagName, checking: .userOnly)
        } else {
            guard let key = prefKey, let defaultValue = getDefaultValue() else { return }

            Task { @MainActor in
                let isSystemNotificationOn = await isSystemNotificationOn()
                control.isOn = (userDefaults?.bool(forKey: key) ?? defaultValue) && isSystemNotificationOn
            }
        }
    }

    override func writeBool(_ control: UISwitch) {
        if let featureFlagName = getFeatureFlagName() {
            featureFlags.set(feature: featureFlagName, to: control.isOn)
        } else {
            Task { @MainActor in
                let isSystemNotificationOn = await isSystemNotificationOn()
                guard let key = prefKey, isSystemNotificationOn else { return }
                userDefaults?.set(control.isOn, forKey: key)
            }
        }
    }

    private func isSystemNotificationOn() async -> Bool {
        let settings = await NotificationManager().getNotificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            fallthrough
        @unknown default:
            return false
        }
    }
}

class PrefPersister: SettingValuePersister {
    private let prefs: Prefs
    let prefKey: String

    init(prefs: Prefs, prefKey: String) {
        self.prefs = prefs
        self.prefKey = prefKey
    }

    func readPersistedValue() -> String? {
        return prefs.stringForKey(prefKey)
    }

    func writePersistedValue(value: String?) {
        if let value = value {
            prefs.setString(value, forKey: prefKey)
        } else {
            prefs.removeObjectForKey(prefKey)
        }
    }
}

class StringPrefSetting: StringSetting {
    init(
        prefs: Prefs,
        prefKey: String,
        defaultValue: String? = nil,
        placeholder: String,
        accessibilityIdentifier: String,
        settingIsValid isValueValid: ((String?) -> Bool)? = nil,
        settingDidChange: ((String?) -> Void)? = nil
    ) {
        super.init(defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   persister: PrefPersister(prefs: prefs, prefKey: prefKey),
                   settingIsValid: isValueValid,
                   settingDidChange: settingDidChange)
    }
}

class WebPageSetting: StringPrefSetting {
    let isChecked: () -> Bool

    init(
        prefs: Prefs,
        prefKey: String,
        defaultValue: String? = nil,
        placeholder: String,
        accessibilityIdentifier: String,
        isChecked: @escaping () -> Bool = { return false },
        settingDidChange: ((String?) -> Void)? = nil
    ) {
        self.isChecked = isChecked
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   settingIsValid: WebPageSetting.isURLOrEmpty,
                   settingDidChange: settingDidChange)
        configureTextField(
            keyboardType: .URL,
            autocapitalizationType: .none,
            autocorrectionType: .no
        )
    }

    override func prepareValidValue(userInput value: String?) -> String? {
        guard let value = value else { return nil }
        return URIFixup.getURL(value)?.absoluteString
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.accessoryType = isChecked() ? .checkmark : .none
        alignTextFieldToNatural()
    }

    static func isURLOrEmpty(_ string: String?) -> Bool {
        guard let string = string, !string.isEmpty else {
            return true
        }
        return URL(string: string, invalidCharacters: false)?.isWebPage() ?? false
    }
}

protocol SettingValuePersister {
    func readPersistedValue() -> String?
    func writePersistedValue(value: String?)
}

/// A helper class for a setting backed by a UITextField.
/// This takes an optional settingIsValid and settingDidChange callback
/// If settingIsValid returns false, the Setting will not change and the text remains red.
class StringSetting: Setting, UITextFieldDelegate {
    private struct UX {
        static let padding: CGFloat = 15
        static let textFieldHeight: CGFloat = 44
        static let textFieldIdentifierSuffix = "TextField"
    }

    private let defaultValue: String?
    private let placeholder: String
    private let settingDidChange: ((String?) -> Void)?
    private let settingIsValid: ((String?) -> Bool)?
    private let persister: SettingValuePersister

    private lazy var textField: UITextField = .build()

    init(
        defaultValue: String? = nil,
        placeholder: String,
        accessibilityIdentifier: String,
        persister: SettingValuePersister,
        settingIsValid isValueValid: ((String?) -> Bool)? = nil,
        settingDidChange: ((String?) -> Void)? = nil
    ) {
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        self.placeholder = placeholder
        self.persister = persister

        super.init()
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func configureTextField(
        keyboardType: UIKeyboardType,
        autocapitalizationType: UITextAutocapitalizationType,
        autocorrectionType: UITextAutocorrectionType
    ) {
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = autocapitalizationType
        textField.autocorrectionType = autocorrectionType
    }

    func alignTextFieldToNatural() {
        textField.textAlignment = textField.effectiveUserInterfaceLayoutDirection == .leftToRight ? .natural : .right
    }

    func enableClearButtonForTextField() {
        textField.clearButtonMode = .always
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        if let id = accessibilityIdentifier {
            textField.accessibilityIdentifier = id + UX.textFieldIdentifierSuffix
        }
        let placeholderColor = theme.colors.textSecondary
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
        )

        cell.tintColor = persister.readPersistedValue() != nil ? theme.colors.actionPrimary : UIColor.clear
        textField.textAlignment = .center
        textField.delegate = self
        textField.tintColor = theme.colors.actionPrimary
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        cell.isUserInteractionEnabled = true
        cell.accessibilityTraits = UIAccessibilityTraits.none
        cell.contentView.addSubview(textField)

        textField.font = FXFontStyles.Regular.body.scaledFont()

        NSLayoutConstraint.activate(
            [
                textField.heightAnchor.constraint(equalToConstant: UX.textFieldHeight),
                textField.trailingAnchor.constraint(
                    equalTo: cell.contentView.trailingAnchor,
                    constant: -UX.padding
                ),
                textField.leadingAnchor.constraint(
                    equalTo: cell.contentView.leadingAnchor,
                    constant: UX.padding
                )
            ]
        )

        if let value = persister.readPersistedValue() {
            textField.text = value
            textFieldDidChange(textField)
        }
    }

    override func onClick(_ navigationController: UINavigationController?) {
        textField.becomeFirstResponder()
    }

    private func isValid(_ value: String?) -> Bool {
        guard let test = settingIsValid else {
            return true
        }
        return test(prepareValidValue(userInput: value))
    }

    /// This gives subclasses an opportunity to treat the user input string
    /// before it is saved or tested.
    /// Default implementation does nothing.
    func prepareValidValue(userInput value: String?) -> String? {
        return value
    }

    @objc
    func textFieldDidChange(_ textField: UITextField) {
        let color = isValid(textField.text) ? theme?.colors.textPrimary : theme?.colors.textCritical
        textField.textColor = color
    }

    @objc
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return isValid(textField.text)
    }

    @objc
    func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text
        if !isValid(text) {
            return
        }
        persister.writePersistedValue(value: prepareValidValue(userInput: text))
        // Call settingDidChange with text or nil.
        settingDidChange?(text)
    }
}

enum CheckmarkSettingStyle {
    case leftSide
    case rightSide
}

class CheckmarkSetting: Setting {
    private struct UX {
        static let defaultInset: CGFloat = 0
        static let cellIndentationWidth: CGFloat = 42
        static let cellIndentationLevel = 1
        static let checkmarkTopHeight: CGFloat = 10
        static let checkmarkHeight: CGFloat = 20.0
        static let checkmarkWidth: CGFloat = 24.0
        static let checkmarkLeading: CGFloat = 20
        static let checkmarkSymbol = "\u{2713}"
        static let cellAlpha: CGFloat = 0.5
    }

    let onChecked: () -> Void
    let isChecked: () -> Bool
    private let subtitle: NSAttributedString?
    let checkmarkStyle: CheckmarkSettingStyle

    private lazy var check: UILabel = .build { label in
        label.text = UX.checkmarkSymbol
    }

    override var status: NSAttributedString? {
        return subtitle
    }

    init(
        title: NSAttributedString,
        style: CheckmarkSettingStyle = .rightSide,
        subtitle: NSAttributedString?,
        accessibilityIdentifier: String? = nil,
        isChecked: @escaping () -> Bool,
        onChecked: @escaping () -> Void
    ) {
        self.subtitle = subtitle
        self.onChecked = onChecked
        self.isChecked = isChecked
        self.checkmarkStyle = style
        super.init(title: title)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)

        if checkmarkStyle == .rightSide {
            cell.accessoryType = isChecked() ? .checkmark : .none
        } else {
            let window = UIWindow.keyWindow
            let safeAreaInsets = window?.safeAreaInsets.left ?? UX.defaultInset
            let dynamicIndentationWidth = UIFontMetrics.default.scaledValue(for: UX.cellIndentationWidth)
            cell.indentationWidth = dynamicIndentationWidth + safeAreaInsets
            cell.indentationLevel = UX.cellIndentationLevel
            cell.accessoryType = .detailButton

            setupLeftCheckLabel(cell, theme: theme)

            let result = NSMutableAttributedString()
            if let str = title?.string {
                result.append(
                    NSAttributedString(
                        string: str,
                        attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
                    )
                )
            }
            cell.textLabel?.assign(attributed: result, theme: theme)
        }

        if !enabled {
            cell.subviews.forEach { $0.alpha = UX.cellAlpha }
        }
    }

    private func setupLeftCheckLabel(_ cell: UITableViewCell, theme: Theme) {
        check.font = FXFontStyles.Regular.title3.scaledFont()
        let checkColor = isChecked() ? theme.colors.actionPrimary : UIColor.clear
        check.textColor = checkColor

        cell.contentView.addSubview(check)
        let checkmarkHeight = UIFontMetrics.default.scaledValue(for: UX.checkmarkHeight)
        let checkmarkWidth = UIFontMetrics.default.scaledValue(for: UX.checkmarkWidth)
        NSLayoutConstraint.activate([
            check.topAnchor.constraint(
                equalTo: cell.contentView.topAnchor,
                constant: UX.checkmarkTopHeight
            ),
            check.leadingAnchor.constraint(
                equalTo: cell.contentView.leadingAnchor,
                constant: UX.checkmarkLeading
            ),
            check.heightAnchor.constraint(equalToConstant: checkmarkHeight),
            check.widthAnchor.constraint(equalToConstant: checkmarkWidth)
        ])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Force editing to end for any focused text fields so they can finish up validation first.
        navigationController?.view.endEditing(true)
        if !isChecked() {
            onChecked()
        }
    }
}

// A helper class for prefs that deal with sync. Handles reloading the tableView data if changes to
// the fxAccount happen.
class AccountSetting: Setting {
    unowned var settings: SettingsTableViewController

    var profile: Profile? {
        return settings.profile
    }

    override var title: NSAttributedString? { return nil }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        if settings.profile?.rustFxA.userProfile != nil {
            cell.selectionStyle = .none
        }
    }

    override var accessoryType: UITableViewCell.AccessoryType { return .none }
}

class WithAccountSetting: AccountSetting {
    override var hidden: Bool {
        guard let profile else { return true }
        return !profile.hasAccount()
    }
}

class WithoutAccountSetting: AccountSetting {
    override var hidden: Bool {
        guard let profile else { return false }
        return profile.hasAccount()
    }
}

@objc
protocol SettingsDelegate: AnyObject {
    func settingsOpenURLInNewTab(_ url: URL)
    func didFinish()
}

// The base settings view controller.
class SettingsTableViewController: ThemedTableViewController {
    private struct UX {
        static let tableViewFooterHeight: CGFloat = 30
        static let estimatedRowHeight: CGFloat = 44
        static let estimatedSectionHeaderHeight: CGFloat = 44
    }

    var settings = [SettingSection]()

    weak var settingsDelegate: SettingsDelegate?

    var profile: Profile?
    var tabManager: TabManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(cellType: ThemedLeftAlignedTableViewCell.self)
        tableView.register(cellType: ThemedSubtitleTableViewCell.self)
        tableView.register(
            ThemedTableSectionHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        )
        tableView.tableFooterView = UIView(
            frame: CGRect(width: view.frame.width, height: UX.tableViewFooterHeight)
        )
        tableView.estimatedRowHeight = UX.estimatedRowHeight
        tableView.estimatedSectionHeaderHeight = UX.estimatedSectionHeaderHeight
        tableView.rowHeight = UITableView.automaticDimension

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(didLongPress)
        )
        tableView.addGestureRecognizer(longPressGestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settings = generateSettings()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncDidChangeState),
            name: .ProfileDidStartSyncing,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncDidChangeState),
            name: .ProfileDidFinishSyncing,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(firefoxAccountDidChange),
            name: .FirefoxAccountChanged,
            object: nil
        )

        applyTheme()
    }

    func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    override func applyTheme() {
        settings = generateSettings()
        super.applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        [Notification.Name.ProfileDidStartSyncing,
         Notification.Name.ProfileDidFinishSyncing,
         Notification.Name.FirefoxAccountChanged].forEach { name in
            NotificationCenter.default.removeObserver(self, name: name, object: nil)
        }
    }

    // Override to provide settings in subclasses
    func generateSettings() -> [SettingSection] {
        return []
    }

    @objc
    private func syncDidChangeState() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @objc
    private func refresh() {
        // Through-out, be aware that modifying the control while a refresh is in progress is /not/ supported
        // and will likely crash the app.
        // self.profile.rustAccount.refreshProfile()
        // TODO [rustfxa] listen to notification and refresh profile
    }

    @objc
    func firefoxAccountDidChange() {
        self.tableView.reloadData()
    }

    @objc
    func didLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location), gestureRecognizer.state == .began else { return }

        let section = settings[indexPath.section]
        if let setting = section[indexPath.row], setting.enabled {
            setting.onLongPress(navigationController)
        }
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            let cell = dequeueCellFor(indexPath: indexPath, setting: setting)
            setting.onConfigureCell(cell, theme: themeManager.getCurrentTheme(for: windowUUID))
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }

    override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row], let themedCell = cell as? ThemedTableViewCell {
            setting.onConfigureCell(themedCell, theme: themeManager.getCurrentTheme(for: windowUUID))
            themedCell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    private func dequeueCellFor(indexPath: IndexPath, setting: Setting) -> ThemedTableViewCell {
        if setting as? DisconnectSetting != nil {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ThemedCenteredTableViewCell.cellIdentifier,
                for: indexPath
            ) as? ThemedCenteredTableViewCell else {
                return ThemedCenteredTableViewCell()
            }
            return cell
        } else if setting.style == .subtitle {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ThemedSubtitleTableViewCell.cellIdentifier,
                for: indexPath
            ) as? ThemedSubtitleTableViewCell else {
                return ThemedSubtitleTableViewCell()
            }
            return cell
        }
        if setting.style == .value1 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ThemedLeftAlignedTableViewCell.cellIdentifier,
                for: indexPath
            ) as? ThemedLeftAlignedTableViewCell else {
                return ThemedLeftAlignedTableViewCell()
            }
            return cell
        }
        return dequeueCellFor(indexPath: indexPath)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settings[section]
        return section.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView else { return nil }

        let sectionSetting = settings[section]
        if let sectionTitle = sectionSetting.title?.string {
            headerView.titleLabel.text = sectionTitle.uppercased()
        }
        headerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sectionSetting = settings[section]

        guard let footerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView,
                let sectionFooter = sectionSetting.footerTitle?.string else { return nil }

        footerView.titleLabel.text = sectionFooter
        footerView.titleAlignment = .top
        footerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return footerView
    }

    // To hide a footer dynamically requires returning nil from viewForFooterInSection
    // and setting the height to zero.
    // However, we also want the height dynamically calculated, there is a magic constant
    // for that: `UITableViewAutomaticDimension`.
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sectionSetting = settings[section]
        if sectionSetting.footerTitle?.string != nil {
            return UITableView.automaticDimension
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row], let height = setting.cellHeight {
            return height
        }

        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = settings[indexPath.section]
        if let setting = section[indexPath.row], setting.enabled {
            setting.onClick(navigationController)
        }
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            setting.accessoryButtonTapped()
        }
    }
}
