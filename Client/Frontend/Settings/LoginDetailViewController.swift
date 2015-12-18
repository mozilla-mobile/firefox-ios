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

    private let login: LoginData

    private let LoginCellIdentifier = "LoginCell"
    private let DeleteCellIdentifier = "DeleteCell"
    private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

    init(login: LoginData) {
        self.login = login
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(LoginTableViewCell.self, forCellReuseIdentifier: LoginCellIdentifier)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: DeleteCellIdentifier)
        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 20))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        tableView.scrollEnabled = false
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = ListSection(rawValue: indexPath.section)!

        switch section {
        case .Info:
            let loginCell = tableView.dequeueReusableCellWithIdentifier(LoginCellIdentifier, forIndexPath: indexPath) as! LoginTableViewCell
            loginCell.selectionStyle = .None

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
                loginCell.descriptionLabel.text = login.password.anonymize()
            case .WebsiteItem:
                loginCell.style = .NoIconAndBothLabels
                loginCell.highlightedLabel.text = NSLocalizedString("website", tableName: "LoginManager", comment: "Title for website row in Login Detail View")
                loginCell.descriptionLabel.text = login.hostname
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
            let lastModified = NSLocalizedString("Last modified %@", tableName: "LoginManager", comment: "Footer label describing when the login was last modified with the timestamp as the parameter")
            footer.titleLabel.text = String(format: lastModified, "Date goes here")
            return footer
        default: return nil
        }
    }
}
