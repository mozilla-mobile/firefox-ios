/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared

private enum ListSection: Int {
    case Info = 0
    case Delete = 1
}

private enum InfoItem: Int {
    case TitleItem = 0
    case UsernameItem = 1
    case PasswordItem = 2
    case WebsiteItem = 3
}

private struct LoginDetailUX {
    static let InfoRowHeight: CGFloat = 58
    static let DeleteRowHeight: CGFloat = 44
    static let FooterHeight: CGFloat = 44
}

class LoginDetailViewController: UITableViewController {

    private let profile: Profile

    private let login: LoginData
    private var loginUsageData: LoginUsageData? = nil {
        didSet {
            tableView.reloadData()
        }
    }

    private let LoginCellIdentifier = "LoginCell"
    private let DeleteCellIdentifier = "DeleteCell"
    private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

    // Used to temporarily store a reference to the cell the user is showing the menu controller for
    private var menuControllerCell: LoginTableViewCell? = nil

    weak var settingsDelegate: SettingsDelegate?

    init(profile: Profile, login: LoginData) {
        self.login = login
        self.profile = profile
        super.init(nibName: nil, bundle: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELwillShowMenuController", name: UIMenuControllerWillShowMenuNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELwillHideMenuController", name: UIMenuControllerWillHideMenuNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "SELedit")

        tableView.registerClass(LoginTableViewCell.self, forCellReuseIdentifier: LoginCellIdentifier)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: DeleteCellIdentifier)
        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        let footer = SettingsTableSectionHeaderFooterView()
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        tableView.scrollEnabled = false
        tableView.accessibilityIdentifier = "Login Detail List"
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        profile.logins.getUsageDataForLoginByGUID(login.guid).uponQueue(dispatch_get_main_queue()) { result in
            self.loginUsageData = result.successValue
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillShowMenuNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillHideMenuNotification, object: nil)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = ListSection(rawValue: indexPath.section)!

        switch section {
        case .Info:
            let loginCell = tableView.dequeueReusableCellWithIdentifier(LoginCellIdentifier, forIndexPath: indexPath) as! LoginTableViewCell
            loginCell.selectionStyle = .None
            loginCell.delegate = self

            switch InfoItem(rawValue: indexPath.row)! {
            case .TitleItem:
                loginCell.style = .IconAndDescriptionLabel
                loginCell.descriptionLabel.text = login.hostname
            case .UsernameItem:
                loginCell.style = .NoIconAndBothLabels
                loginCell.highlightedLabel.text = NSLocalizedString("username", tableName: "LoginManager", comment: "Title for username row in Login Detail View")
                loginCell.descriptionLabel.text = login.username
            case .PasswordItem:
                loginCell.style = .NoIconAndBothLabels
                loginCell.highlightedLabel.text = NSLocalizedString("password", tableName: "LoginManager", comment: "Title for password row in Login Detail View")
                loginCell.descriptionLabel.text = login.password
                loginCell.descriptionLabel.secureTextEntry = true
                loginCell.enabledActions = [.Copy, .Reveal]
            case .WebsiteItem:
                loginCell.style = .NoIconAndBothLabels
                loginCell.highlightedLabel.text = NSLocalizedString("website", tableName: "LoginManager", comment: "Title for website row in Login Detail View")
                loginCell.descriptionLabel.text = login.hostname
                loginCell.enabledActions = [.Copy, .OpenAndFill]
            }
            return loginCell
        case .Delete:
            let deleteCell = tableView.dequeueReusableCellWithIdentifier(DeleteCellIdentifier, forIndexPath: indexPath)
            deleteCell.textLabel?.text = NSLocalizedString("Delete", tableName: "LoginManager", comment: "Button in login detail screen that deletes the current login")
            deleteCell.textLabel?.textAlignment = NSTextAlignment.Center
            deleteCell.textLabel?.textColor = UIConstants.DestructiveRed
            deleteCell.accessibilityTraits = UIAccessibilityTraitButton
            return deleteCell
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch ListSection(rawValue: section)! {
        case .Info: return 4
        case .Delete: return 1
        }
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch ListSection(rawValue: section)! {
        case .Info: return 60
        default: return 0
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch ListSection(rawValue: indexPath.section)! {
        case .Info: return LoginDetailUX.InfoRowHeight
        case .Delete: return LoginDetailUX.DeleteRowHeight
        }
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch ListSection(rawValue: section)! {
        case .Info:
            let footer = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
            footer.titleAlignment = .Top

            if let passwordModifiedTimestamp = loginUsageData?.timePasswordChanged {
                let lastModified = NSLocalizedString("Last modified %@", tableName: "LoginManager", comment: "Footer label describing when the login was last modified with the timestamp as the parameter")
                let formattedLabel = String(format: lastModified, NSDate.fromTimestamp(passwordModifiedTimestamp).toRelativeTimeString())
                footer.titleLabel.text = formattedLabel
            }
            return footer

        default:
            return nil
        }
    }

    override func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let section = ListSection(rawValue: indexPath.section)!
        let item = InfoItem(rawValue: indexPath.row)!
        if section == .Info {
            if item == .PasswordItem || item == .WebsiteItem {
                menuControllerCell = tableView.cellForRowAtIndexPath(indexPath) as? LoginTableViewCell
                return true
            }
        }

        return false
    }

    override func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        let section = ListSection(rawValue: indexPath.section)!
        let item = InfoItem(rawValue: indexPath.row)!

        // Menu actions for password
        if section == .Info && item == .PasswordItem {
            let loginCell = tableView.cellForRowAtIndexPath(indexPath) as! LoginTableViewCell
            let showRevealOption = loginCell.descriptionLabel.secureTextEntry ? (action == "SELrevealDescription") : (action == "SELsecureDescription")
            return action == "SELcopyDescription" || showRevealOption
        }

        // Menu actions for Website
        else if section == .Info && item == .WebsiteItem {
            return action == "SELcopyDescription" || action == "SELopenAndFillDescription"
        } else {
            return false
        }
    }

    override func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        // No-op. Needs to be overridden for custom menu action selectors to work.
    }
}

// MARK: - Table View Editing
extension LoginDetailViewController {

    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }

    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}

// MARK: - Selectors
extension LoginDetailViewController {

    func SELedit() {
        tableView.editing = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "SELdoneEditing")
    }

    func SELdoneEditing() {
        tableView.editing = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "SELedit")
    }

    func SELwillShowMenuController() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillShowMenuNotification, object: nil)

        let menuController = UIMenuController.sharedMenuController()
        guard let cell = menuControllerCell,
              let textSize = cell.descriptionTextSize else {
            return
        }

        // The description label constraints are such that it extends full width of the cell instead of only 
        // the size of its text. The reason is because when the description is used as a password, the dots
        // are slightly larger characters than the font size which causes the password text to be truncated 
        // even though the revealed text fits. Since the label is actually full width, the menu controller will
        // display in its center by default which looks weird with small passwords. To prevent this,
        // the actual size of the text is used to determine where to correctly place the menu.

        var descriptionFrame = cell.descriptionLabel.frame
        descriptionFrame.size = textSize

        menuController.arrowDirection = .Up
        menuController.setTargetRect(descriptionFrame, inView: cell)
        menuController.setMenuVisible(true, animated: true)
    }

    func SELwillHideMenuController() {
        menuControllerCell = nil

        // Re-add observer
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELwillShowMenuController", name: UIMenuControllerWillShowMenuNotification, object: nil)
    }
}

// MARK: - Cell Delegate
extension LoginDetailViewController: LoginTableViewCellDelegate {

    func didSelectOpenAndFillForCell(cell: LoginTableViewCell) {
        guard let url = self.login.formSubmitURL?.asURL else {
            return
        }

        navigationController?.dismissViewControllerAnimated(true, completion: {
            self.settingsDelegate?.settingsOpenURLInNewTab(url)
        })
    }
}
