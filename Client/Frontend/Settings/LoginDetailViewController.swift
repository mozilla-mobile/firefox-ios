/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared
import SwiftKeychainWrapper

private enum InfoItem: Int {
    case titleItem = 0
    case usernameItem = 1
    case passwordItem = 2
    case websiteItem = 3
    case lastModifiedSeparator = 4
    case deleteItem = 5

    var indexPath: IndexPath {
        return IndexPath(row: rawValue, section: 0)
    }
}

private struct LoginDetailUX {
    static let InfoRowHeight: CGFloat = 58
    static let DeleteRowHeight: CGFloat = 44
    static let SeparatorHeight: CGFloat = 44
}

class LoginDetailViewController: SensitiveViewController {

    private let profile: Profile

    private let tableView = UITableView()

    private var login: Login {
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
    private let SeparatorIdentifier = "SeparatorIdentifier"

    // Used to temporarily store a reference to the cell the user is showing the menu controller for
    private var menuControllerCell: LoginTableViewCell? = nil

    private weak var usernameField: UITextField?
    private weak var passwordField: UITextField?

    weak var settingsDelegate: SettingsDelegate?

    init(profile: Profile, login: Login) {
        self.login = login
        self.profile = profile
        super.init(nibName: nil, bundle: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginDetailViewController.SELwillShowMenuController), name: UIMenuControllerWillShowMenuNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginDetailViewController.SELwillHideMenuController), name: UIMenuControllerWillHideMenuNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(LoginDetailViewController.SELedit))

        tableView.register(LoginTableViewCell.self, forCellReuseIdentifier: LoginCellIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: DefaultCellIdentifier)
        tableView.register(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SeparatorIdentifier)

        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        tableView.accessibilityIdentifier = "Login Detail List"
        tableView.delegate = self
        tableView.dataSource = self

        // Add empty footer view to prevent seperators from being drawn past the last item.
        tableView.tableFooterView = UIView()

        // Add a line on top of the table view so when the user pulls down it looks 'correct'.
        let topLine = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: tableView.frame.width, height: 0.5)))
        topLine.backgroundColor = UIConstants.TableViewSeparatorColor
        tableView.tableHeaderView = topLine

        // Normally UITableViewControllers handle responding to content inset changes from keyboard events when editing
        // but since we don't use the tableView's editing flag for editing we handle this ourselves.
        KeyboardHelper.defaultHelper.addDelegate(self)
    }

    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name(rawValue: NotificationProfileDidFinishSyncing), object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIMenuControllerWillShowMenu, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIMenuControllerWillHideMenu, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // The following hacks are to prevent the default cell seperators from displaying. We want to
        // hide the default seperator for the website/last modified cells since the last modified cell
        // draws its own separators. The last item in the list draws its seperator full width.

        // Prevent seperators from showing by pushing them off screen by the width of the cell
        let itemsToHideSeperators: [InfoItem] = [.websiteItem, .lastModifiedSeparator]
        itemsToHideSeperators.forEach { item in
            let cell = tableView.cellForRow(at: IndexPath(row: item.rawValue, section: 0))
            cell?.separatorInset = UIEdgeInsetsMake(0, cell?.bounds.width ?? 0, 0, 0)
        }

        // Rows to display full width seperator
        let itemsToShowFullWidthSeperator: [InfoItem] = [.deleteItem]
        itemsToShowFullWidthSeperator.forEach { item in
            let cell = tableView.cellForRow(at: IndexPath(row: item.rawValue, section: 0))
            cell?.separatorInset = UIEdgeInsetsZero
            cell?.layoutMargins = UIEdgeInsetsZero
            cell?.preservesSuperviewLayoutMargins = false
        }
    }
}

// MARK: - UITableViewDataSource
extension LoginDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch InfoItem(rawValue: (indexPath as NSIndexPath).row)! {
        case .titleItem:
            let loginCell = dequeueLoginCell(forIndexPath: indexPath)
            loginCell.style = .noIconAndBothLabels
            loginCell.descriptionLabel.text = login.hostname
            return loginCell

        case .usernameItem:
            let loginCell = dequeueLoginCell(forIndexPath: indexPath)
            loginCell.style = .noIconAndBothLabels
            loginCell.highlightedLabelTitle = NSLocalizedString("username", tableName: "LoginManager", comment: "Label displayed above the username row in Login Detail View.")
            loginCell.descriptionLabel.text = login.username
            loginCell.descriptionLabel.keyboardType = .emailAddress
            loginCell.descriptionLabel.returnKeyType = .next
            loginCell.editingDescription = editingInfo
            usernameField = loginCell.descriptionLabel
            return loginCell

        case .passwordItem:
            let loginCell = dequeueLoginCell(forIndexPath: indexPath)
            loginCell.style = .noIconAndBothLabels
            loginCell.highlightedLabelTitle = NSLocalizedString("password", tableName: "LoginManager", comment: "Label displayed above the password row in Login Detail View.")
            loginCell.descriptionLabel.text = login.password
            loginCell.descriptionLabel.returnKeyType = .default
            loginCell.displayDescriptionAsPassword = true
            loginCell.editingDescription = editingInfo
            passwordField = loginCell.descriptionLabel
            return loginCell

        case .websiteItem:
            let loginCell = dequeueLoginCell(forIndexPath: indexPath)
            loginCell.style = .noIconAndBothLabels
            loginCell.highlightedLabelTitle = NSLocalizedString("website", tableName: "LoginManager", comment: "Label displayed above the website row in Login Detail View.")
            loginCell.descriptionLabel.text = login.hostname
            return loginCell

        case .lastModifiedSeparator:
            let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: SeparatorIdentifier) as! SettingsTableSectionHeaderFooterView
            footer.titleAlignment = .top
            let lastModified = NSLocalizedString("Last modified %@", tableName: "LoginManager", comment: "Footer label describing when the current login was last modified with the timestamp as the parameter.")
            let formattedLabel = String(format: lastModified, Date.fromMicrosecondTimestamp(login.timePasswordChanged).toRelativeTimeString())
            footer.titleLabel.text = formattedLabel
            let cell = wrapFooter(footer, withCellFromTableView: tableView, atIndexPath: indexPath)
            return cell

        case .deleteItem:
            let deleteCell = tableView.dequeueReusableCell(withIdentifier: DefaultCellIdentifier, for: indexPath)
            deleteCell.textLabel?.text = NSLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.")
            deleteCell.textLabel?.textAlignment = NSTextAlignment.center
            deleteCell.textLabel?.textColor = UIConstants.DestructiveRed
            deleteCell.accessibilityTraits = UIAccessibilityTraitButton
            return deleteCell
        }
    }

    private func dequeueLoginCell(forIndexPath indexPath: IndexPath) -> LoginTableViewCell {
        let loginCell = tableView.dequeueReusableCell(withIdentifier: LoginCellIdentifier, for: indexPath) as! LoginTableViewCell
        loginCell.selectionStyle = .none
        loginCell.delegate = self
        return loginCell
    }

    private func wrapFooter(_ footer: UITableViewHeaderFooterView, withCellFromTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DefaultCellIdentifier, for: indexPath)
        cell.selectionStyle = .none
        cell.addSubview(footer)
        footer.snp_makeConstraints { make in
            make.edges.equalTo(cell)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
}

// MARK: - UITableViewDelegate
extension LoginDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == InfoItem.deleteItem.indexPath {
            deleteLogin()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch InfoItem(rawValue: (indexPath as NSIndexPath).row)! {
        case .titleItem, .usernameItem, .passwordItem, .websiteItem:
            return LoginDetailUX.InfoRowHeight
        case .lastModifiedSeparator:
            return LoginDetailUX.SeparatorHeight
        case .deleteItem:
            return LoginDetailUX.DeleteRowHeight
        }
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        let item = InfoItem(rawValue: (indexPath as NSIndexPath).row)!
        if item == .passwordItem || item == .websiteItem || item == .usernameItem {
            menuControllerCell = tableView.cellForRow(at: indexPath) as? LoginTableViewCell
            return true
        }

        return false
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) -> Bool {
        let item = InfoItem(rawValue: (indexPath as NSIndexPath).row)!

        // Menu actions for password
        if item == .passwordItem {
            let loginCell = tableView.cellForRow(at: indexPath) as! LoginTableViewCell
            let showRevealOption = loginCell.descriptionLabel.isSecureTextEntry ? (action == MenuHelper.SelectorReveal) : (action == MenuHelper.SelectorHide)
            return action == MenuHelper.SelectorCopy || showRevealOption
        }

        // Menu actions for Website
        if item == .websiteItem {
            return action == MenuHelper.SelectorCopy || action == MenuHelper.SelectorOpenAndFill
        }

        // Menu actions for Username
        if item == .usernameItem {
            return action == MenuHelper.SelectorCopy
        }

        return false
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) {
        // No-op. Needs to be overridden for custom menu action selectors to work.
    }
}

// MARK: - KeyboardHelperDelegate
extension LoginDetailViewController: KeyboardHelperDelegate {

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(tableView)
        tableView.contentInset.bottom = coveredHeight
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}

// MARK: - Selectors
extension LoginDetailViewController {

    func deleteLogin() {
        profile.logins.hasSyncedLogins().uponQueue(DispatchQueue.main) { yes in
            let deleteAlert = UIAlertController.deleteLoginAlertWithDeleteCallback({ [unowned self] _ in
                self.profile.logins.removeLogin(guid: self.login.guid).uponQueue(dispatch_get_main_queue()) { _ in
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }, hasSyncedLogins: yes.successValue ?? true)

            self.presentViewController(deleteAlert, animated: true, completion: nil)
        }
    }

    func SELonProfileDidFinishSyncing() {
        // Reload details after syncing.
        profile.logins.getLoginData(forGUID: login.guid).uponQueue(DispatchQueue.main) { result in
            if let syncedLogin = result.successValue {
                self.login = syncedLogin
            }
        }
    }

    func SELedit() {
        editingInfo = true

        let cell = tableView.cellForRow(at: InfoItem.usernameItem.indexPath) as! LoginTableViewCell
        cell.descriptionLabel.becomeFirstResponder()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(LoginDetailViewController.SELdoneEditing))
    }

    func SELdoneEditing() {
        editingInfo = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(LoginDetailViewController.SELedit))

        // We only care to update if we changed something
        guard let username = usernameField?.text,
                  password = passwordField?.text
            where username != login.username || password != login.password else {
            return
        }

        // Keep a copy of the old data in case we fail and need to revert back
        let oldPassword = login.password
        let oldUsername = login.username
        login.update(password: password, username: username)

        if login.isValid.isSuccess {
            profile.logins.updateLogin(guid: login.guid, new: login, significant: true)
        } else if let oldUsername = oldUsername {
            login.update(password: oldPassword, username: oldUsername)
        }
    }

    func SELwillShowMenuController() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIMenuControllerWillShowMenu, object: nil)

        let menuController = UIMenuController.shared()
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

        var descriptionFrame = passwordField?.frame ?? CGRect.zero
        descriptionFrame.size = textSize

        menuController.arrowDirection = .up
        menuController.setTargetRect(descriptionFrame, in: cell)
        menuController.setMenuVisible(true, animated: true)
    }

    func SELwillHideMenuController() {
        menuControllerCell = nil

        // Re-add observer
        NotificationCenter.default.addObserver(self, selector: #selector(LoginDetailViewController.SELwillShowMenuController), name: NSNotification.Name.UIMenuControllerWillShowMenu, object: nil)
    }
}

// MARK: - Cell Delegate
extension LoginDetailViewController: LoginTableViewCellDelegate {

    private func cellForItem(_ item: InfoItem) -> LoginTableViewCell? {
        return tableView.cellForRow(at: item.indexPath) as? LoginTableViewCell
    }

    func didSelectOpenAndFill(forCell cell: LoginTableViewCell) {
        guard let url = (self.login.formSubmitURL?.asURL ?? self.login.hostname.asURL) else {
            return
        }

        navigationController?.dismissViewControllerAnimated(true, completion: {
            self.settingsDelegate?.settingsOpenURLInNewTab(url)
        })
    }

    func shouldReturnAfterEditingDescription(_ cell: LoginTableViewCell) -> Bool {
        let usernameCell = cellForItem(.usernameItem)
        let passwordCell = cellForItem(.passwordItem)

        if cell == usernameCell {
            passwordCell?.descriptionLabel.becomeFirstResponder()
        }

        return false
    }
}
