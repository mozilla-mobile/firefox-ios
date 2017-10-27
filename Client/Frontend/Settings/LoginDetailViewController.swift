/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared
import SwiftKeychainWrapper

enum InfoItem: Int {
    case websiteItem = 0
    case usernameItem = 1
    case passwordItem = 2
    case lastModifiedSeparator = 3
    case deleteItem = 4

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

    fileprivate let profile: Profile

    fileprivate let tableView = UITableView()

    fileprivate var login: Login {
        didSet {
            tableView.reloadData()
        }
    }

    fileprivate var editingInfo: Bool = false {
        didSet {
            if editingInfo != oldValue {
                tableView.reloadData()
            }
        }
    }

    fileprivate let LoginCellIdentifier = "LoginCell"
    fileprivate let DefaultCellIdentifier = "DefaultCellIdentifier"
    fileprivate let SeparatorIdentifier = "SeparatorIdentifier"

    // Used to temporarily store a reference to the cell the user is showing the menu controller for
    fileprivate var menuControllerCell: LoginTableViewCell?

    fileprivate weak var websiteField: UITextField?
    fileprivate weak var usernameField: UITextField?
    fileprivate weak var passwordField: UITextField?

    fileprivate var deleteAlert: UIAlertController?

    weak var settingsDelegate: SettingsDelegate?

    init(profile: Profile, login: Login) {
        self.login = login
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginDetailViewController.dismissAlertController), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
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
        tableView.snp.makeConstraints { make in
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
        notificationCenter.removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // The following hacks are to prevent the default cell seperators from displaying. We want to
        // hide the default seperator for the website/last modified cells since the last modified cell
        // draws its own separators. The last item in the list draws its seperator full width.

        // Prevent seperators from showing by pushing them off screen by the width of the cell
        let itemsToHideSeperators: [InfoItem] = [.passwordItem, .lastModifiedSeparator]
        itemsToHideSeperators.forEach { item in
            let cell = tableView.cellForRow(at: IndexPath(row: item.rawValue, section: 0))
            cell?.separatorInset = UIEdgeInsets(top: 0, left: cell?.bounds.width ?? 0, bottom: 0, right: 0)
        }

        // Rows to display full width seperator
        let itemsToShowFullWidthSeperator: [InfoItem] = [.deleteItem]
        itemsToShowFullWidthSeperator.forEach { item in
            let cell = tableView.cellForRow(at: IndexPath(row: item.rawValue, section: 0))
            cell?.separatorInset = UIEdgeInsets.zero
            cell?.layoutMargins = UIEdgeInsets.zero
            cell?.preservesSuperviewLayoutMargins = false
        }
    }
}

// MARK: - UITableViewDataSource
extension LoginDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch InfoItem(rawValue: indexPath.row)! {
        case .usernameItem:
            let loginCell = dequeueLoginCellForIndexPath(indexPath)
            loginCell.style = .noIconAndBothLabels
            loginCell.highlightedLabelTitle = NSLocalizedString("username", tableName: "LoginManager", comment: "Label displayed above the username row in Login Detail View.")
            loginCell.descriptionLabel.text = login.username
            loginCell.descriptionLabel.keyboardType = .emailAddress
            loginCell.descriptionLabel.returnKeyType = .next
            loginCell.editingDescription = editingInfo
            usernameField = loginCell.descriptionLabel
            usernameField?.accessibilityIdentifier = "usernameField"
            return loginCell

        case .passwordItem:
            let loginCell = dequeueLoginCellForIndexPath(indexPath)
            loginCell.style = .noIconAndBothLabels
            loginCell.highlightedLabelTitle = NSLocalizedString("password", tableName: "LoginManager", comment: "Label displayed above the password row in Login Detail View.")
            loginCell.descriptionLabel.text = login.password
            loginCell.descriptionLabel.returnKeyType = .default
            loginCell.displayDescriptionAsPassword = true
            loginCell.editingDescription = editingInfo
            passwordField = loginCell.descriptionLabel
            passwordField?.accessibilityIdentifier = "passwordField"
            return loginCell

        case .websiteItem:
            let loginCell = dequeueLoginCellForIndexPath(indexPath)
            loginCell.style = .noIconAndBothLabels
            loginCell.highlightedLabelTitle = NSLocalizedString("website", tableName: "LoginManager", comment: "Label displayed above the website row in Login Detail View.")
            loginCell.descriptionLabel.text = login.hostname
            websiteField = loginCell.descriptionLabel
            websiteField?.accessibilityIdentifier = "websiteField"
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

    fileprivate func dequeueLoginCellForIndexPath(_ indexPath: IndexPath) -> LoginTableViewCell {
        let loginCell = tableView.dequeueReusableCell(withIdentifier: LoginCellIdentifier, for: indexPath) as! LoginTableViewCell
        loginCell.selectionStyle = .none
        loginCell.delegate = self
        return loginCell
    }

    fileprivate func wrapFooter(_ footer: UITableViewHeaderFooterView, withCellFromTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DefaultCellIdentifier, for: indexPath)
        cell.selectionStyle = .none
        cell.addSubview(footer)
        footer.snp.makeConstraints { make in
            make.edges.equalTo(cell)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
}

// MARK: - UITableViewDelegate
extension LoginDetailViewController: UITableViewDelegate {
    private func showMenuOnSingleTap(forIndexPath indexPath: IndexPath) {
        guard let item = InfoItem(rawValue: indexPath.row) else { return }
        if ![InfoItem.passwordItem, InfoItem.websiteItem, InfoItem.usernameItem].contains(item) {
            return
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) as? LoginTableViewCell else { return }
        
        cell.becomeFirstResponder()
        
        let menu = UIMenuController.shared
        menu.setTargetRect(cell.frame, in: self.tableView)
        menu.setMenuVisible(true, animated: true)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == InfoItem.deleteItem.indexPath {
            deleteLogin()
        } else if !editingInfo {
            showMenuOnSingleTap(forIndexPath: indexPath)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch InfoItem(rawValue: indexPath.row)! {
        case .usernameItem, .passwordItem, .websiteItem:
            return LoginDetailUX.InfoRowHeight
        case .lastModifiedSeparator:
            return LoginDetailUX.SeparatorHeight
        case .deleteItem:
            return LoginDetailUX.DeleteRowHeight
        }
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

    @objc func dismissAlertController() {
        self.deleteAlert?.dismiss(animated: false, completion: nil)
    }

    func deleteLogin() {
        profile.logins.hasSyncedLogins().uponQueue(DispatchQueue.main) { yes in
            self.deleteAlert = UIAlertController.deleteLoginAlertWithDeleteCallback({ [unowned self] _ in
                self.profile.logins.removeLoginByGUID(self.login.guid).uponQueue(DispatchQueue.main) { _ in
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }, hasSyncedLogins: yes.successValue ?? true)

            self.present(self.deleteAlert!, animated: true, completion: nil)
        }
    }

    func SELonProfileDidFinishSyncing() {
        // Reload details after syncing.
        profile.logins.getLoginDataForGUID(login.guid).uponQueue(DispatchQueue.main) { result in
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
        
        defer {
            // Required to get UI to reload with changed state
            tableView.reloadData()
        }
        
        // We only care to update if we changed something
        guard let username = usernameField?.text,
                  let password = passwordField?.text, username != login.username || password != login.password else {
            return
        }

        // Keep a copy of the old data in case we fail and need to revert back
        let oldPassword = login.password
        let oldUsername = login.username
        login.update(password: password, username: username)

        if login.isValid.isSuccess {
            profile.logins.updateLoginByGUID(login.guid, new: login, significant: true)
        } else if let oldUsername = oldUsername {
            login.update(password: oldPassword, username: oldUsername)
        }
    }
}

// MARK: - Cell Delegate
extension LoginDetailViewController: LoginTableViewCellDelegate {

    fileprivate func cellForItem(_ item: InfoItem) -> LoginTableViewCell? {
        return tableView.cellForRow(at: item.indexPath) as? LoginTableViewCell
    }

    func didSelectOpenAndFillForCell(_ cell: LoginTableViewCell) {
        guard let url = (self.login.formSubmitURL?.asURL ?? self.login.hostname.asURL) else {
            return
        }

        navigationController?.dismiss(animated: true, completion: {
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
    
    func infoItemForCell(_ cell: LoginTableViewCell) -> InfoItem? {
        if let index = tableView.indexPath(for: cell),
            let item = InfoItem(rawValue: index.row) {
            return item
        }
        return nil
    }
}
