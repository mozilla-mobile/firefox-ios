/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Shared
import UIKit

// A base setting class that shows a title. You probably want to subclass this, not use it directly.
class Setting: NSObject {
    fileprivate var _title: NSAttributedString?
    fileprivate var _footerTitle: NSAttributedString?
    fileprivate var _cellHeight: CGFloat?
    fileprivate var _image: UIImage?

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

    var style: UITableViewCellStyle { return .subtitle }

    var accessoryType: UITableViewCellAccessoryType { return .none }

    var textAlignment: NSTextAlignment { return .natural }
    
    var image: UIImage? { return _image }
    
    fileprivate(set) var enabled: Bool = true

    // Called when the cell is setup. Call if you need the default behaviour.
    func onConfigureCell(_ cell: UITableViewCell) {
        cell.detailTextLabel?.attributedText = status
        cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.attributedText = title
        cell.textLabel?.textAlignment = textAlignment
        cell.textLabel?.numberOfLines = 1
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        cell.accessoryType = accessoryType
        cell.accessoryView = nil
        cell.selectionStyle = enabled ? .default : .none
        cell.accessibilityIdentifier = accessibilityIdentifier
        cell.imageView?.image = _image
        if let title = title?.string {
            if let detailText = cell.detailTextLabel?.text {
                cell.accessibilityLabel = "\(title), \(detailText)"
            } else if let status = status?.string {
                cell.accessibilityLabel = "\(title), \(status)"
            } else {
                cell.accessibilityLabel = title
            }
        }
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.indentationWidth = 0
        cell.layoutMargins = UIEdgeInsets.zero
        // So that the separator line goes all the way to the left edge.
        cell.separatorInset = UIEdgeInsets.zero
    }

    // Called when the pref is tapped.
    func onClick(_ navigationController: UINavigationController?) { return }

    // Helper method to set up and push a SettingsContentViewController
    func setUpAndPushSettingsContentViewController(_ navigationController: UINavigationController?) {
        if let url = self.url {
            let viewController = SettingsContentViewController()
            viewController.settingsTitle = self.title
            viewController.url = url
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    init(title: NSAttributedString? = nil, footerTitle: NSAttributedString? = nil, cellHeight: CGFloat? = nil, delegate: SettingsDelegate? = nil, enabled: Bool? = nil) {
        self._title = title
        self._footerTitle = footerTitle
        self._cellHeight = cellHeight
        self.delegate = delegate
        self.enabled = enabled ?? true
    }
}

// A setting in the sections panel. Contains a sublist of Settings
class SettingSection: Setting {
    fileprivate let children: [Setting]

    init(title: NSAttributedString? = nil, footerTitle: NSAttributedString? = nil, cellHeight: CGFloat? = nil, children: [Setting]) {
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

private class PaddedSwitch: UIView {
    fileprivate static let Padding: CGFloat = 8

    init(switchView: UISwitch) {
        super.init(frame: CGRect.zero)

        addSubview(switchView)

        frame.size = CGSize(width: switchView.frame.width + PaddedSwitch.Padding, height: switchView.frame.height)
        switchView.frame.origin = CGPoint(x: PaddedSwitch.Padding, y: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// A helper class for settings with a UISwitch.
// Takes and optional settingsDidChange callback and status text.
class BoolSetting: Setting {
    let prefKey: String? // Sometimes a subclass will manage its own pref setting. In that case the prefkey will be nil

    fileprivate let prefs: Prefs
    fileprivate let defaultValue: Bool
    fileprivate let settingDidChange: ((Bool) -> Void)?
    fileprivate let statusText: NSAttributedString?

    init(prefs: Prefs, prefKey: String? = nil, defaultValue: Bool, attributedTitleText: NSAttributedString, attributedStatusText: NSAttributedString? = nil, settingDidChange: ((Bool) -> Void)? = nil) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.statusText = attributedStatusText
        super.init(title: attributedTitleText)
    }

    convenience init(prefs: Prefs, prefKey: String? = nil, defaultValue: Bool, titleText: String, statusText: String? = nil, settingDidChange: ((Bool) -> Void)? = nil) {
        var statusTextAttributedString: NSAttributedString?
        if let statusTextString = statusText {
            statusTextAttributedString = NSAttributedString(string: statusTextString, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewHeaderTextColor])
        }
        self.init(prefs: prefs, prefKey: prefKey, defaultValue: defaultValue, attributedTitleText: NSAttributedString(string: titleText, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]), attributedStatusText: statusTextAttributedString, settingDidChange: settingDidChange)
    }

    override var status: NSAttributedString? {
        return statusText
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)

        let control = UISwitch()
        control.onTintColor = UIConstants.SystemBlueColor
        control.addTarget(self, action: #selector(BoolSetting.switchValueChanged(_:)), for: UIControlEvents.valueChanged)
        control.accessibilityIdentifier = prefKey
        
        displayBool(control)
        if let title = title {
            if let status = status {
                control.accessibilityLabel = "\(title.string), \(status.string)"
            } else {
                control.accessibilityLabel = title.string
            }
            cell.accessibilityLabel = nil
        }
        cell.accessoryView = PaddedSwitch(switchView: control)
        cell.selectionStyle = .none
    }

    @objc func switchValueChanged(_ control: UISwitch) {
        writeBool(control)
        settingDidChange?(control.isOn)
    }

    // These methods allow a subclass to control how the pref is saved
    func displayBool(_ control: UISwitch) {
        guard let key = prefKey else {
            return
        }
        control.isOn = prefs.boolForKey(key) ?? defaultValue
    }

    func writeBool(_ control: UISwitch) {
        guard let key = prefKey else {
            return
        }
        prefs.setBool(control.isOn, forKey: key)
    }
}

/// A helper class for a setting backed by a UITextField.
/// This takes an optional settingIsValid and settingDidChange callback
/// If settingIsValid returns false, the Setting will not change and the text remains red.
class StringSetting: Setting, UITextFieldDelegate {

    let prefKey: String
    fileprivate let Padding: CGFloat = 8

    fileprivate let prefs: Prefs
    fileprivate let defaultValue: String?
    fileprivate let placeholder: String
    fileprivate let settingDidChange: ((String?) -> Void)?
    fileprivate let settingIsValid: ((String?) -> Bool)?

    let textField = UITextField()

    init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String, accessibilityIdentifier: String, settingIsValid isValueValid: ((String?) -> Bool)? = nil, settingDidChange: ((String?) -> Void)? = nil) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        self.placeholder = placeholder

        super.init()
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if let id = accessibilityIdentifier {
            textField.accessibilityIdentifier = id + "TextField"
        }
        textField.placeholder = placeholder
        textField.textAlignment = .center
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        cell.isUserInteractionEnabled = true
        cell.accessibilityTraits = UIAccessibilityTraitNone
        cell.contentView.addSubview(textField)

        textField.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.trailing.equalTo(cell.contentView).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(Padding)
        }
        textField.text = prefs.stringForKey(prefKey) ?? defaultValue
        textFieldDidChange(textField)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        textField.becomeFirstResponder()
    }

    fileprivate func isValid(_ value: String?) -> Bool {
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

    @objc func textFieldDidChange(_ textField: UITextField) {
        let color = isValid(textField.text) ? UIConstants.TableViewRowTextColor : UIConstants.DestructiveRed
        textField.textColor = color
    }

    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return isValid(textField.text)
    }

    @objc func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text
        if !isValid(text) {
            return
        }
        if let text = prepareValidValue(userInput: text) {
            prefs.setString(text, forKey: prefKey)
        } else {
            prefs.removeObjectForKey(prefKey)
        }
        // Call settingDidChange with text or nil.
        settingDidChange?(text)
    }
}

class CheckmarkSetting: Setting {
    let onChanged: () -> Void
    let isEnabled: () -> Bool
    private let subtitle: NSAttributedString?

    override var status: NSAttributedString? {
        return subtitle
    }

    init(title: NSAttributedString, subtitle: NSAttributedString?, accessibilityIdentifier: String? = nil, isEnabled: @escaping () -> Bool, onChanged: @escaping () -> Void) {
        self.subtitle = subtitle
        self.onChanged = onChanged
        self.isEnabled = isEnabled
        super.init(title: title)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.accessoryType = isEnabled() ? .checkmark : .none
        cell.selectionStyle = .none
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Force editing to end for any focused text fields so they can finish up validation first.
        navigationController?.view.endEditing(true)
        if !isEnabled() {
            onChanged()
        }
    }
}

/// A helper class for a setting backed by a UITextField.
/// This takes an optional isEnabled and mandatory onClick callback
/// isEnabled is called on each tableview.reloadData. If it returns
/// false then the 'button' appears disabled.
class ButtonSetting: Setting {
    let onButtonClick: (UINavigationController?) -> Void
    let destructive: Bool
    let isEnabled: (() -> Bool)?

    init(title: NSAttributedString?, destructive: Bool = false, accessibilityIdentifier: String, isEnabled: (() -> Bool)? = nil, onClick: @escaping (UINavigationController?) -> Void) {
        self.onButtonClick = onClick
        self.destructive = destructive
        self.isEnabled = isEnabled
        super.init(title: title)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)

        if isEnabled?() ?? true {
            cell.textLabel?.textColor = destructive ? UIConstants.DestructiveRed : UIConstants.HighlightBlue
        } else {
            cell.textLabel?.textColor = UIConstants.TableViewDisabledRowTextColor
        }
        cell.textLabel?.textAlignment = NSTextAlignment.center
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.selectionStyle = .none
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Force editing to end for any focused text fields so they can finish up validation first.
        navigationController?.view.endEditing(true)
        if isEnabled?() ?? true {
            onButtonClick(navigationController)
        }
    }
}

// A helper class for prefs that deal with sync. Handles reloading the tableView data if changes to
// the fxAccount happen.
class AccountSetting: Setting, FxAContentViewControllerDelegate {
    unowned var settings: SettingsTableViewController

    var profile: Profile {
        return settings.profile
    }

    override var title: NSAttributedString? { return nil }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if settings.profile.getAccount() != nil {
            cell.selectionStyle = .none
        }
    }

    override var accessoryType: UITableViewCellAccessoryType { return .none }

    func contentViewControllerDidSignIn(_ viewController: FxAContentViewController, withFlags flags: FxALoginFlags) {
        // This method will get called twice: once when the user signs in, and once
        // when the account is verified by email – on this device or another.
        // If the user hasn't dismissed the fxa content view controller,
        // then we should only do that (thus finishing the sign in/verification process)
        // once the account is verified.
        // By the time we get to here, we should be syncing or just about to sync in the
        // background, most likely from FxALoginHelper.
        if flags.verified {
            _ = settings.navigationController?.popToRootViewController(animated: true)
            // Reload the data to reflect the new Account immediately.
            settings.tableView.reloadData()
            // And start advancing the Account state in the background as well.
            settings.SELrefresh()
        }
    }

    func contentViewControllerDidCancel(_ viewController: FxAContentViewController) {
        NSLog("didCancel")
        _ = settings.navigationController?.popToRootViewController(animated: true)
    }
}

class WithAccountSetting: AccountSetting {
    override var hidden: Bool { return !profile.hasAccount() }
}

class WithoutAccountSetting: AccountSetting {
    override var hidden: Bool { return profile.hasAccount() }
}

@objc
protocol SettingsDelegate: class {
    func settingsOpenURLInNewTab(_ url: URL)
}

// The base settings view controller.
class SettingsTableViewController: UITableViewController {

    typealias SettingsGenerator = (SettingsTableViewController, SettingsDelegate?) -> [SettingSection]

    fileprivate let Identifier = "CellIdentifier"
    fileprivate let SectionHeaderIdentifier = "SectionHeaderIdentifier"
    var settings = [SettingSection]()

    weak var settingsDelegate: SettingsDelegate?

    var profile: Profile!
    var tabManager: TabManager!

    var hasSectionSeparatorLine = true

    /// Used to calculate cell heights.
    fileprivate lazy var dummyToggleCell: UITableViewCell = {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "dummyCell")
        cell.accessoryView = UISwitch()
        return cell
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Identifier)
        tableView.register(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderIdentifier)
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 30))
        tableView.estimatedRowHeight = 44
        tableView.estimatedSectionHeaderHeight = 44
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settings = generateSettings()

        NotificationCenter.default.addObserver(self, selector: #selector(SettingsTableViewController.SELsyncDidChangeState), name: NotificationProfileDidStartSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsTableViewController.SELsyncDidChangeState), name: NotificationProfileDidFinishSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsTableViewController.SELfirefoxAccountDidChange), name: NotificationFirefoxAccountChanged, object: nil)

        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SELrefresh()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NotificationProfileDidStartSyncing, object: nil)
        NotificationCenter.default.removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        NotificationCenter.default.removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
    }

    // Override to provide settings in subclasses
    func generateSettings() -> [SettingSection] {
        return []
    }

    @objc fileprivate func SELsyncDidChangeState() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @objc fileprivate func SELrefresh() {
        // Through-out, be aware that modifying the control while a refresh is in progress is /not/ supported and will likely crash the app.
        if let account = self.profile.getAccount() {
            account.advance().upon { state in
                DispatchQueue.main.async { () -> Void in
                    self.tableView.reloadData()
                }
            }
        } else {
            self.tableView.reloadData()
        }
    }

    @objc func SELfirefoxAccountDidChange() {
        self.tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            var cell: UITableViewCell!
            if let _ = setting.status {
                // Work around http://stackoverflow.com/a/9999821 and http://stackoverflow.com/a/25901083 by using a new cell.
                // I could not make any setNeedsLayout solution work in the case where we disconnect and then connect a new account.
                // Be aware that dequeing and then ignoring a cell appears to cause issues; only deque a cell if you're going to return it.
                cell = UITableViewCell(style: setting.style, reuseIdentifier: nil)
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifier, for: indexPath)
            }
            setting.onConfigureCell(cell)
            return cell
        }
        return tableView.dequeueReusableCell(withIdentifier: Identifier, for: indexPath)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settings[section]
        return section.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier) as! SettingsTableSectionHeaderFooterView
        let sectionSetting = settings[section]
        if let sectionTitle = sectionSetting.title?.string {
            headerView.titleLabel.text = sectionTitle.uppercased()
        }
        // Hide the top border for the top section to avoid having a double line at the top
        if section == 0 || !hasSectionSeparatorLine {
            headerView.showTopBorder = false
        } else {
            headerView.showTopBorder = true
        }

        return headerView
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sectionSetting = settings[section]
        guard let sectionFooter = sectionSetting.footerTitle?.string else {
            return nil
        }
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier) as! SettingsTableSectionHeaderFooterView
        footerView.titleLabel.text = sectionFooter
        footerView.titleAlignment = .top
        footerView.showBottomBorder = false
        return footerView
    }

    // To hide a footer dynamically requires returning nil from viewForFooterInSection
    // and setting the height to zero.
    // However, we also want the height dynamically calculated, there is a magic constant
    // for that: `UITableViewAutomaticDimension`.
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sectionSetting = settings[section]
        if let _ = sectionSetting.footerTitle?.string {
            return UITableViewAutomaticDimension
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = settings[indexPath.section]
        // Workaround for calculating the height of default UITableViewCell cells with a subtitle under
        // the title text label.
        if let setting = section[indexPath.row], setting is BoolSetting && setting.status != nil {
            return calculateStatusCellHeightForSetting(setting)
        }
        if let setting = section[indexPath.row], let height = setting.cellHeight {
            return height
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row], setting.enabled {
            setting.onClick(navigationController)
        }
    }

    fileprivate func calculateStatusCellHeightForSetting(_ setting: Setting) -> CGFloat {
        dummyToggleCell.layoutSubviews()

        let topBottomMargin: CGFloat = 10
        let width = dummyToggleCell.contentView.frame.width - 2 * dummyToggleCell.separatorInset.left

        return
            heightForLabel(dummyToggleCell.textLabel!, width: width, text: setting.title?.string) +
            heightForLabel(dummyToggleCell.detailTextLabel!, width: width, text: setting.status?.string) +
            2 * topBottomMargin
    }

    fileprivate func heightForLabel(_ label: UILabel, width: CGFloat, text: String?) -> CGFloat {
        guard let text = text else { return 0 }

        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let attrs = [NSFontAttributeName: label.font as Any]
        let boundingRect = NSString(string: text).boundingRect(with: size,
            options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attrs, context: nil)
        return boundingRect.height
    }
}

struct SettingsTableSectionHeaderFooterViewUX {
    static let titleHorizontalPadding: CGFloat = 15
    static let titleVerticalPadding: CGFloat = 6
    static let titleVerticalLongPadding: CGFloat = 20
}

class SettingsTableSectionHeaderFooterView: UITableViewHeaderFooterView {

    enum TitleAlignment {
        case top
        case bottom
    }

    var titleAlignment: TitleAlignment = .bottom {
        didSet {
            remakeTitleAlignmentConstraints()
        }
    }

    var showTopBorder: Bool = true {
        didSet {
            topBorder.isHidden = !showTopBorder
        }
    }

    var showBottomBorder: Bool = true {
        didSet {
            bottomBorder.isHidden = !showBottomBorder
        }
    }

    lazy var titleLabel: UILabel = {
        var headerLabel = UILabel()
        headerLabel.textColor = UIConstants.TableViewHeaderTextColor
        headerLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
        headerLabel.numberOfLines = 0
        return headerLabel
    }()

    fileprivate lazy var topBorder: UIView = {
        let topBorder = UIView()
        topBorder.backgroundColor = UIConstants.SeparatorColor
        return topBorder
    }()

    fileprivate lazy var bottomBorder: UIView = {
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIConstants.SeparatorColor
        return bottomBorder
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        addSubview(titleLabel)
        addSubview(topBorder)
        addSubview(bottomBorder)

        setupInitialConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupInitialConstraints() {
        bottomBorder.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self)
            make.height.equalTo(0.5)
        }

        topBorder.snp.makeConstraints { make in
            make.top.left.right.equalTo(self)
            make.height.equalTo(0.5)
        }

        remakeTitleAlignmentConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        showTopBorder = true
        showBottomBorder = true
        titleLabel.text = nil
        titleAlignment = .bottom
    }

    fileprivate func remakeTitleAlignmentConstraints() {
        switch titleAlignment {
        case .top:
            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalTo(self).inset(SettingsTableSectionHeaderFooterViewUX.titleHorizontalPadding)
                make.top.equalTo(self).offset(SettingsTableSectionHeaderFooterViewUX.titleVerticalPadding)
                make.bottom.equalTo(self).offset(-SettingsTableSectionHeaderFooterViewUX.titleVerticalLongPadding)
            }
        case .bottom:
            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalTo(self).inset(SettingsTableSectionHeaderFooterViewUX.titleHorizontalPadding)
                make.bottom.equalTo(self).offset(-SettingsTableSectionHeaderFooterViewUX.titleVerticalPadding)
                make.top.equalTo(self).offset(SettingsTableSectionHeaderFooterViewUX.titleVerticalLongPadding)
            }
        }
    }
}

