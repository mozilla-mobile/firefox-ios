/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Shared
import UIKit
import XCGLogger


// The following are only here because we use master for L10N and otherwise these strings would disappear from the v1.0 release
private let Bug1204635_S1 = NSLocalizedString("Clear Everything", tableName: "ClearPrivateData", comment: "Title of the Clear private data dialog.")
private let Bug1204635_S2 = NSLocalizedString("Are you sure you want to clear all of your data? This will also close all open tabs.", tableName: "ClearPrivateData", comment: "Message shown in the dialog prompting users if they want to clear everything")
private let Bug1204635_S3 = NSLocalizedString("Clear", tableName: "ClearPrivateData", comment: "Used as a button label in the dialog to Clear private data dialog")
private let Bug1204635_S4 = NSLocalizedString("Cancel", tableName: "ClearPrivateData", comment: "Used as a button label in the dialog to cancel clear private data dialog")

// A base setting class that shows a title. You probably want to subclass this, not use it directly.
class Setting: NSObject {
    private var _title: NSAttributedString?

    weak var delegate: SettingsDelegate?

    // The url the SettingsContentViewController will show, e.g. Licenses and Privacy Policy.
    var url: NSURL? { return nil }

    // The title shown on the pref.
    var title: NSAttributedString? { return _title }
    private(set) var accessibilityIdentifier: String?

    // An optional second line of text shown on the pref.
    var status: NSAttributedString? { return nil }

    // Whether or not to show this pref.
    var hidden: Bool { return false }

    var style: UITableViewCellStyle { return .Subtitle }

    var accessoryType: UITableViewCellAccessoryType { return .None }

    var textAlignment: NSTextAlignment { return .Natural }
    
    private(set) var enabled: Bool = true

    // Called when the cell is setup. Call if you need the default behaviour.
    func onConfigureCell(cell: UITableViewCell) {
        cell.detailTextLabel?.attributedText = status
        cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.attributedText = title
        cell.textLabel?.textAlignment = textAlignment
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = accessoryType
        cell.accessoryView = nil
        cell.selectionStyle = enabled ? .Default : .None
        cell.accessibilityIdentifier = accessibilityIdentifier
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
        cell.layoutMargins = UIEdgeInsetsZero
        // So that the separator line goes all the way to the left edge.
        cell.separatorInset = UIEdgeInsetsZero
    }

    // Called when the pref is tapped.
    func onClick(navigationController: UINavigationController?) { return }

    // Helper method to set up and push a SettingsContentViewController
    func setUpAndPushSettingsContentViewController(navigationController: UINavigationController?) {
        if let url = self.url {
            let viewController = SettingsContentViewController()
            viewController.settingsTitle = self.title
            viewController.url = url
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    init(title: NSAttributedString? = nil, delegate: SettingsDelegate? = nil, enabled: Bool? = nil) {
        self._title = title
        self.delegate = delegate
        self.enabled = enabled ?? true
    }
}

// A setting in the sections panel. Contains a sublist of Settings
class SettingSection : Setting {
    private let children: [Setting]

    init(title: NSAttributedString? = nil, children: [Setting]) {
        self.children = children
        super.init(title: title)
    }

    var count: Int {
        var count = 0
        for setting in children {
            if !setting.hidden {
                count += 1
            }
        }
        return count
    }

    subscript(val: Int) -> Setting? {
        var i = 0
        for setting in children {
            if !setting.hidden {
                if i == val {
                    return setting
                }
                i += 1
            }
        }
        return nil
    }
}

private class PaddedSwitch: UIView {
    private static let Padding: CGFloat = 8

    init(switchView: UISwitch) {
        super.init(frame: CGRectZero)

        addSubview(switchView)

        frame.size = CGSizeMake(switchView.frame.width + PaddedSwitch.Padding, switchView.frame.height)
        switchView.frame.origin = CGPointMake(PaddedSwitch.Padding, 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// A helper class for settings with a UISwitch.
// Takes and optional settingsDidChange callback and status text.
class BoolSetting: Setting {
    let prefKey: String

    private let prefs: Prefs
    private let defaultValue: Bool
    private let settingDidChange: ((Bool) -> Void)?
    private let statusText: NSAttributedString?

    init(prefs: Prefs, prefKey: String, defaultValue: Bool, attributedTitleText: NSAttributedString, attributedStatusText: NSAttributedString? = nil, settingDidChange: ((Bool) -> Void)? = nil) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.statusText = attributedStatusText
        super.init(title: attributedTitleText)
    }

    convenience init(prefs: Prefs, prefKey: String, defaultValue: Bool, titleText: String, statusText: String? = nil, settingDidChange: ((Bool) -> Void)? = nil) {
        var statusTextAttributedString: NSAttributedString?
        if let statusTextString = statusText {
            statusTextAttributedString = NSAttributedString(string: statusTextString, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewHeaderTextColor])
        }
        self.init(prefs: prefs, prefKey: prefKey, defaultValue: defaultValue, attributedTitleText: NSAttributedString(string: titleText, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]), attributedStatusText: statusTextAttributedString, settingDidChange: settingDidChange)
    }

    override var status: NSAttributedString? {
        return statusText
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)

        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(BoolSetting.switchValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        control.on = prefs.boolForKey(prefKey) ?? defaultValue
        if let title = title {
            if let status = status {
                control.accessibilityLabel = "\(title.string), \(status.string)"
            } else {
                control.accessibilityLabel = title.string
            }
            cell.accessibilityLabel = nil
        }
        cell.accessoryView = PaddedSwitch(switchView: control)
        cell.selectionStyle = .None
    }

    @objc func switchValueChanged(control: UISwitch) {
        prefs.setBool(control.on, forKey: prefKey)
        settingDidChange?(control.on)
    }
}

/// A helper class for a setting backed by a UITextField.
/// This takes an optional settingIsValid and settingDidChange callback
/// If settingIsValid returns false, the Setting will not change and the text remains red.
class StringSetting: Setting, UITextFieldDelegate {

    let prefKey: String

    private let prefs: Prefs
    private let defaultValue: String?
    private let placeholder: String
    private let settingDidChange: (String? -> Void)?
    private let settingIsValid: (String? -> Bool)?

    let textField = UITextField()

    init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String, accessibilityIdentifier: String, settingIsValid isValueValid: (String? -> Bool)? = nil, settingDidChange: (String? -> Void)? = nil) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        self.placeholder = placeholder

        super.init()
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if let id = accessibilityIdentifier {
            textField.accessibilityIdentifier = id + "TextField"
        }
        textField.placeholder = placeholder
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), forControlEvents: .EditingChanged)

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
        textFieldDidChange(textField)
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
        if let text = text {
            prefs.setString(text, forKey: prefKey)
        } else {
            prefs.removeObjectForKey(prefKey)
        }
        // Call settingDidChange with text or nil.
        settingDidChange?(text)
    }
}

/// A helper class for a setting backed by a UITextField.
/// This takes an optional isEnabled and mandatory onClick callback
/// isEnabled is called on each tableview.reloadData. If it returns
/// false then the 'button' appears disabled.
class ButtonSetting: Setting {
    let onButtonClick: (UINavigationController?) -> ()
    let destructive: Bool
    let isEnabled: (() -> Bool)?

    init(title: NSAttributedString?, destructive: Bool = false, accessibilityIdentifier: String, isEnabled: (() -> Bool)? = nil, onClick: UINavigationController? -> ()) {
        self.onButtonClick = onClick
        self.destructive = destructive
        self.isEnabled = isEnabled
        super.init(title: title)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)

        if isEnabled?() ?? true {
            cell.textLabel?.textColor = destructive ? UIConstants.DestructiveRed : UIConstants.HighlightBlue
        } else {
            cell.textLabel?.textColor = UIConstants.TableViewDisabledRowTextColor
        }
        cell.textLabel?.textAlignment = NSTextAlignment.Center
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.selectionStyle = .None
    }

    override func onClick(navigationController: UINavigationController?) {
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

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if settings.profile.getAccount() != nil {
            cell.selectionStyle = .None
        }
    }

    override var accessoryType: UITableViewCellAccessoryType { return .None }

    func contentViewControllerDidSignIn(viewController: FxAContentViewController, data: JSON) -> Void {
        if data["keyFetchToken"].asString == nil || data["unwrapBKey"].asString == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            NSLog("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            return
        }

        // TODO: Error handling.
        let account = FirefoxAccount.fromConfigurationAndJSON(profile.accountConfiguration, data: data)!
        settings.profile.setAccount(account)

        // Reload the data to reflect the new Account immediately.
        settings.tableView.reloadData()
        // And start advancing the Account state in the background as well.
        settings.SELrefresh()

        settings.navigationController?.popToRootViewControllerAnimated(true)
    }

    func contentViewControllerDidCancel(viewController: FxAContentViewController) {
        NSLog("didCancel")
        settings.navigationController?.popToRootViewControllerAnimated(true)
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
    func settingsOpenURLInNewTab(url: NSURL)
}

// The base settings view controller.
class SettingsTableViewController: UITableViewController {

    typealias SettingsGenerator = (SettingsTableViewController, SettingsDelegate?) -> [SettingSection]

    private let Identifier = "CellIdentifier"
    private let SectionHeaderIdentifier = "SectionHeaderIdentifier"
    var settings = [SettingSection]()

    weak var settingsDelegate: SettingsDelegate?

    var profile: Profile!
    var tabManager: TabManager!

    /// Used to calculate cell heights.
    private lazy var dummyToggleCell: UITableViewCell = {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "dummyCell")
        cell.accessoryView = UISwitch()
        return cell
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifier)
        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderIdentifier)
        tableView.tableFooterView = SettingsTableFooterView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 128))
        
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        tableView.estimatedRowHeight = 44
        tableView.estimatedSectionHeaderHeight = 44
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        settings = generateSettings()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsTableViewController.SELsyncDidChangeState), name: NotificationProfileDidStartSyncing, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsTableViewController.SELsyncDidChangeState), name: NotificationProfileDidFinishSyncing, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsTableViewController.SELfirefoxAccountDidChange), name: NotificationFirefoxAccountChanged, object: nil)

        tableView.reloadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        SELrefresh()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationProfileDidStartSyncing, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
    }

    // Override to provide settings in subclasses
    func generateSettings() -> [SettingSection] {
        return []
    }

    @objc private func SELsyncDidChangeState() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }

    @objc private func SELrefresh() {
        // Through-out, be aware that modifying the control while a refresh is in progress is /not/ supported and will likely crash the app.
        if let account = self.profile.getAccount() {
            account.advance().upon { _ in
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
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

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            var cell: UITableViewCell!
            if let _ = setting.status {
                // Work around http://stackoverflow.com/a/9999821 and http://stackoverflow.com/a/25901083 by using a new cell.
                // I could not make any setNeedsLayout solution work in the case where we disconnect and then connect a new account.
                // Be aware that dequeing and then ignoring a cell appears to cause issues; only deque a cell if you're going to return it.
                cell = UITableViewCell(style: setting.style, reuseIdentifier: nil)
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier(Identifier, forIndexPath: indexPath)
            }
            setting.onConfigureCell(cell)
            return cell
        }
        return tableView.dequeueReusableCellWithIdentifier(Identifier, forIndexPath: indexPath)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settings[section]
        return section.count
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderIdentifier) as! SettingsTableSectionHeaderFooterView
        let sectionSetting = settings[section]
        if let sectionTitle = sectionSetting.title?.string {
            headerView.titleLabel.text = sectionTitle
        }

        // Hide the top border for the top section to avoid having a double line at the top
        if section == 0 {
            headerView.showTopBorder = false
        } else {
            headerView.showTopBorder = true
        }

        return headerView
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let section = settings[indexPath.section]
        // Workaround for calculating the height of default UITableViewCell cells with a subtitle under
        // the title text label.
        if let setting = section[indexPath.row] where setting is BoolSetting && setting.status != nil {
            return calculateStatusCellHeightForSetting(setting)
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] where setting.enabled {
            setting.onClick(navigationController)
        }
    }

    private func calculateStatusCellHeightForSetting(setting: Setting) -> CGFloat {
        let topBottomMargin: CGFloat = 10

        let tableWidth = tableView.frame.width
        let accessoryWidth = dummyToggleCell.accessoryView!.frame.width
        let insetsWidth = 2 * tableView.separatorInset.left
        let width = tableWidth - accessoryWidth - insetsWidth

        return
            heightForLabel(dummyToggleCell.textLabel!, width: width, text: setting.title?.string) +
            heightForLabel(dummyToggleCell.detailTextLabel!, width: width, text: setting.status?.string) +
            2 * topBottomMargin
    }

    private func heightForLabel(label: UILabel, width: CGFloat, text: String?) -> CGFloat {
        guard let text = text else { return 0 }

        let size = CGSize(width: width, height: CGFloat.max)
        let attrs = [NSFontAttributeName: label.font]
        let boundingRect = NSString(string: text).boundingRectWithSize(size,
            options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attrs, context: nil)
        return boundingRect.height
    }
}

class SettingsTableFooterView: UIView {
    var logo: UIImageView = {
        var image =  UIImageView(image: UIImage(named: "settingsFlatfox"))
        image.contentMode = UIViewContentMode.Center
        image.accessibilityIdentifier = "SettingsTableFooterView.logo"
        return image
    }()

    private lazy var topBorder: CALayer = {
        let topBorder = CALayer()
        topBorder.backgroundColor = UIConstants.SeparatorColor.CGColor
        return topBorder
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        layer.addSublayer(topBorder)
        addSubview(logo)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        topBorder.frame = CGRectMake(0.0, 0.0, frame.size.width, 0.5)
        logo.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
    }
}

struct SettingsTableSectionHeaderFooterViewUX {
    static let titleHorizontalPadding: CGFloat = 15
    static let titleVerticalPadding: CGFloat = 6
    static let titleVerticalLongPadding: CGFloat = 20
}

class SettingsTableSectionHeaderFooterView: UITableViewHeaderFooterView {

    enum TitleAlignment {
        case Top
        case Bottom
    }

    var titleAlignment: TitleAlignment = .Bottom {
        didSet {
            remakeTitleAlignmentConstraints()
        }
    }

    var showTopBorder: Bool = true {
        didSet {
            topBorder.hidden = !showTopBorder
        }
    }

    var showBottomBorder: Bool = true {
        didSet {
            bottomBorder.hidden = !showBottomBorder
        }
    }

    lazy var titleLabel: UILabel = {
        var headerLabel = UILabel()
        headerLabel.textColor = UIConstants.TableViewHeaderTextColor
        headerLabel.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightRegular)
        headerLabel.numberOfLines = 0
        return headerLabel
    }()

    private lazy var topBorder: UIView = {
        let topBorder = UIView()
        topBorder.backgroundColor = UIConstants.SeparatorColor
        return topBorder
    }()

    private lazy var bottomBorder: UIView = {
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
        bottomBorder.snp_makeConstraints { make in
            make.bottom.left.right.equalTo(self)
            make.height.equalTo(0.5)
        }

        topBorder.snp_makeConstraints { make in
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
        titleAlignment = .Bottom
    }

    private func remakeTitleAlignmentConstraints() {
        switch titleAlignment {
        case .Top:
            titleLabel.snp_remakeConstraints { make in
                make.left.right.equalTo(self).inset(SettingsTableSectionHeaderFooterViewUX.titleHorizontalPadding)
                make.top.equalTo(self).offset(SettingsTableSectionHeaderFooterViewUX.titleVerticalPadding)
                make.bottom.equalTo(self).offset(-SettingsTableSectionHeaderFooterViewUX.titleVerticalLongPadding)
            }
        case .Bottom:
            titleLabel.snp_remakeConstraints { make in
                make.left.right.equalTo(self).inset(SettingsTableSectionHeaderFooterViewUX.titleHorizontalPadding)
                make.bottom.equalTo(self).offset(-SettingsTableSectionHeaderFooterViewUX.titleVerticalPadding)
                make.top.equalTo(self).offset(SettingsTableSectionHeaderFooterViewUX.titleVerticalLongPadding)
            }
        }
    }
}
