/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared

private enum InfoItem: Int {
    case TitleItem = 0
    case UsernameItem = 1
    case PasswordItem = 2
    case WebsiteItem = 3
    case LastModifiedSeperator = 4
    case DeleteItem = 5

    var indexPath: NSIndexPath {
        return NSIndexPath(forRow: rawValue, inSection: 0)
    }
}

private struct LoginDetailUX {
    static let InfoRowHeight: CGFloat = 58
    static let DeleteRowHeight: CGFloat = 44
    static let SeperatorHeight: CGFloat = 44
}

class LoginDetailViewController: UIViewController {

    private let profile: Profile

    private let tableView = UITableView()

    private var login: LoginData {
        didSet {
            tableView.reloadData()
        }
    }

    private var editingInfo: Bool = false {
        didSet {
            if editingInfo != oldValue {
                tableView.reloadData()
            }
        }
    }

    private let LoginCellIdentifier = "LoginCell"
    private let DefaultCellIdentifier = "DefaultCellIdentifier"

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
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: DefaultCellIdentifier)

        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        tableView.accessibilityIdentifier = "Login Detail List"
        tableView.delegate = self
        tableView.dataSource = self

        // Add empty footer view to prevent seperators from being drawn past the last item.
        tableView.tableFooterView = UIView()

        // Add a line on top of the table view so when the user pulls down it looks 'correct'.
        let topLine = UIView(frame: CGRect(origin: CGPointZero, size: CGSize(width: tableView.frame.width, height: 0.5)))
        topLine.backgroundColor = UIConstants.TableViewSeparatorColor
        tableView.tableHeaderView = topLine

        // Normally UITableViewControllers handle responding to content inset changes from keyboard events when editing
        // but since we don't use the tableView's editing flag for editing we handle this ourselves.
        KeyboardHelper.defaultHelper.addDelegate(self)
    }

    deinit {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.removeObserver(self, name: UIMenuControllerWillShowMenuNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIMenuControllerWillHideMenuNotification, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // The following hacks are to prevent the default cell seperators from displaying. We want to
        // hide the default seperator for the website/last modified cells since the last modified cell
        // draws it's own seperators. The last item in the list draws its seperator full width. The reason

        // Prevent seperators from showing by pushing them off screen by the width of the cell
        let itemsToHideSeperators: [InfoItem] = [.WebsiteItem, .LastModifiedSeperator]
        itemsToHideSeperators.forEach { item in
            let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: item.rawValue, inSection: 0))
            cell?.separatorInset = UIEdgeInsetsMake(0, cell?.bounds.width ?? 0, 0, 0)
        }

        // Rows to display full width seperator
        let itemsToShowFullWidthSeperator: [InfoItem] = [.DeleteItem]
        itemsToShowFullWidthSeperator.forEach { item in
            let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: item.rawValue, inSection: 0))
            cell?.separatorInset = UIEdgeInsetsZero
            cell?.layoutMargins = UIEdgeInsetsZero
            cell?.preservesSuperviewLayoutMargins = false
        }
    }
}

// MARK: - UITableViewDataSource
extension LoginDetailViewController: UITableViewDataSource {

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch InfoItem(rawValue: indexPath.row)! {
        case .TitleItem:
            let loginCell = dequeueLoginCellForIndexPath(indexPath)
            loginCell.style = .IconAndDescriptionLabel
            loginCell.descriptionLabel.text = login.hostname
            return loginCell

        case .UsernameItem:
            let loginCell = dequeueLoginCellForIndexPath(indexPath)
            loginCell.style = .NoIconAndBothLabels
            loginCell.highlightedLabel.text = NSLocalizedString("username", tableName: "LoginManager", comment: "Title for username row in Login Detail View")
            loginCell.descriptionLabel.text = login.username
            loginCell.descriptionLabel.keyboardType = .EmailAddress
            loginCell.descriptionLabel.userInteractionEnabled = editingInfo
            return loginCell

        case .PasswordItem:
            let loginCell = dequeueLoginCellForIndexPath(indexPath)
            loginCell.style = .NoIconAndBothLabels
            loginCell.highlightedLabel.text = NSLocalizedString("password", tableName: "LoginManager", comment: "Title for password row in Login Detail View")
            loginCell.descriptionLabel.text = login.password
            loginCell.displayDescriptionAsPassword = true
            loginCell.descriptionLabel.userInteractionEnabled = editingInfo
            return loginCell

        case .WebsiteItem:
            let loginCell = dequeueLoginCellForIndexPath(indexPath)
            loginCell.style = .NoIconAndBothLabels
            loginCell.highlightedLabel.text = NSLocalizedString("website", tableName: "LoginManager", comment: "Title for website row in Login Detail View")
            loginCell.descriptionLabel.text = login.hostname
            loginCell.enabledActions = [.Copy, .OpenAndFill]
            loginCell.descriptionLabel.keyboardType = .URL
            loginCell.descriptionLabel.userInteractionEnabled = editingInfo
            return loginCell

        case .LastModifiedSeperator:
            let footer = SettingsTableSectionHeaderFooterView()
            footer.titleAlignment = .Top
//            if let passwordModifiedTimestamp = loginUsageData?.timePasswordChanged {
//                let lastModified = NSLocalizedString("Last modified %@", tableName: "LoginManager", comment: "Footer label describing when the login was last modified with the timestamp as the parameter")
//                let formattedLabel = String(format: lastModified, NSDate.fromTimestamp(passwordModifiedTimestamp).toRelativeTimeString())
//                footer.titleLabel.text = formattedLabel
//            }
            let cell = wrapFooter(footer, withCellFromTableView: tableView, atIndexPath: indexPath)
            return cell

        case .DeleteItem:
            let deleteCell = tableView.dequeueReusableCellWithIdentifier(DefaultCellIdentifier, forIndexPath: indexPath)
            deleteCell.textLabel?.text = NSLocalizedString("Delete", tableName: "LoginManager", comment: "Button in login detail screen that deletes the current login")
            deleteCell.textLabel?.textAlignment = NSTextAlignment.Center
            deleteCell.textLabel?.textColor = UIConstants.DestructiveRed
            deleteCell.accessibilityTraits = UIAccessibilityTraitButton
            return deleteCell
        }
    }

    private func dequeueLoginCellForIndexPath(indexPath: NSIndexPath) -> LoginTableViewCell {
        let loginCell = tableView.dequeueReusableCellWithIdentifier(LoginCellIdentifier, forIndexPath: indexPath) as! LoginTableViewCell
        loginCell.selectionStyle = .None
        loginCell.delegate = self
        loginCell.descriptionLabel.delegate = self
        return loginCell
    }

    private func wrapFooter(footer: UITableViewHeaderFooterView, withCellFromTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(DefaultCellIdentifier, forIndexPath: indexPath)
        cell.selectionStyle = .None
        cell.addSubview(footer)
        footer.snp_makeConstraints { make in
            make.edges.equalTo(cell)
        }
        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
}

// MARK: - UITableViewDelegate
extension LoginDetailViewController: UITableViewDelegate {

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch InfoItem(rawValue: indexPath.row)! {
        case .TitleItem, .UsernameItem, .PasswordItem, .WebsiteItem:
            return LoginDetailUX.InfoRowHeight
        case .LastModifiedSeperator:
            return LoginDetailUX.SeperatorHeight
        case .DeleteItem:
            return LoginDetailUX.DeleteRowHeight
        }
    }



    func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let item = InfoItem(rawValue: indexPath.row)!
        if item == .PasswordItem || item == .WebsiteItem {
            menuControllerCell = tableView.cellForRowAtIndexPath(indexPath) as? LoginTableViewCell
            return true
        }

        return false
    }

    func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        let item = InfoItem(rawValue: indexPath.row)!

        // Menu actions for password
        if item == .PasswordItem {
            let loginCell = tableView.cellForRowAtIndexPath(indexPath) as! LoginTableViewCell
            let showRevealOption = loginCell.descriptionLabel.secureTextEntry ? (action == MenuHelper.SelectorReveal) : (action == MenuHelper.SelectorHide)
            return action == MenuHelper.SelectorCopy || showRevealOption
        }

        // Menu actions for Website
        else if item == .WebsiteItem {
            return action == MenuHelper.SelectorCopy || action == MenuHelper.SelectorOpenAndFill
        } else {
            return false
        }
    }

    func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        // No-op. Needs to be overridden for custom menu action selectors to work.
    }
}

// MARK: - KeyboardHelperDelegate
extension LoginDetailViewController: KeyboardHelperDelegate {
    
    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(tableView)
        tableView.contentInset.bottom = coveredHeight
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}

// MARK: - UITextFieldDelegate
extension LoginDetailViewController: UITextFieldDelegate {

    private func cellForItem(item: InfoItem) -> LoginTableViewCell? {
        return tableView.cellForRowAtIndexPath(item.indexPath) as? LoginTableViewCell
    }

    private func textFieldForItem(item: InfoItem) -> UITextField? {
        guard let loginCell = cellForItem(item) else {
            return nil
        }

        return loginCell.descriptionLabel
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let usernameField = textFieldForItem(.UsernameItem)
        let passwordField = textFieldForItem(.PasswordItem)
        let websiteField = textFieldForItem(.WebsiteItem)

        if textField == usernameField {
            passwordField?.becomeFirstResponder()
        } else if textField == passwordField {
            websiteField?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        return false
    }

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if let passwordField = textFieldForItem(.PasswordItem) where passwordField == textField {
            cellForItem(.PasswordItem)?.displayDescriptionAsPassword = false
        }
        return true
    }

    func textFieldDidEndEditing(textField: UITextField) {
        if let passwordField = textFieldForItem(.PasswordItem) where passwordField == textField {
            cellForItem(.PasswordItem)?.displayDescriptionAsPassword = true
        }
    }
}

// MARK: - Selectors
extension LoginDetailViewController {

    func SELonProfileDidFinishSyncing() {
        // Reload details after syncing.
        profile.logins.getLoginDataForGUID(login.guid).uponQueue(dispatch_get_main_queue()) { result in
            if let syncedLogin = result.successValue {
                self.login = syncedLogin
            }
        }
    }

    func SELedit() {
        editingInfo = true

        let cell = tableView.cellForRowAtIndexPath(InfoItem.UsernameItem.indexPath) as! LoginTableViewCell
        cell.descriptionLabel.becomeFirstResponder()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "SELdoneEditing")
    }

    func SELdoneEditing() {
        let usernameField = textFieldForItem(.UsernameItem)
        let passwordField = textFieldForItem(.PasswordItem)
        let websiteField = textFieldForItem(.WebsiteItem)

        // Force resign responder from all input fields
        [usernameField, passwordField, websiteField].forEach { $0?.resignFirstResponder() }

        editingInfo = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "SELedit")

        let username = usernameField?.text ?? ""
        let password = passwordField?.text ?? ""
        let hostname = websiteField?.text ?? ""

        // Update login if there were any changes
        if username != login.username || password != login.password || hostname != login.hostname {
            // Update local, in-memory copy to view changes right away.
            login = Login(guid: login.guid, hostname: hostname, username: username, password: password)
            profile.logins.updateLoginByGUID(login.guid, new: login, significant: true)
        }
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
