/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper

/// Screen presented to the user when selecting the time interval before requiring a passcode
class RequirePasscodeIntervalViewController: UITableViewController {
    let intervalOptions: [PasscodeInterval] = [
        .immediately,
        .oneMinute,
        .fiveMinutes,
        .tenMinutes,
        .fifteenMinutes,
        .oneHour
    ]

    fileprivate let BasicCheckmarkCell = "BasicCheckmarkCell"
    fileprivate var authenticationInfo: AuthenticationKeychainInfo?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = .AuthenticationRequirePasscode

        tableView.accessibilityIdentifier = "AuthenticationManager.passcodeIntervalTableView"

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: BasicCheckmarkCell)
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground

        let headerFooterFrame = CGRect(width: self.view.frame.width, height: SettingsUX.TableViewHeaderFooterHeight)
        let headerView = ThemedTableSectionHeaderFooterView(frame: headerFooterFrame)
        headerView.showBorder(for: .bottom, true)

        let footerView = ThemedTableSectionHeaderFooterView(frame: headerFooterFrame)
        footerView.showBorder(for: .top, true)

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.authenticationInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo()
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BasicCheckmarkCell, for: indexPath)
        let option = intervalOptions[indexPath.row]
        let intervalTitle = NSAttributedString.tableRowTitle(option.settingTitle, enabled: true)
        cell.textLabel?.attributedText = intervalTitle
        cell.accessoryType = authenticationInfo?.requiredPasscodeInterval == option ? .checkmark : .none
        cell.backgroundColor = UIColor.theme.tableView.rowBackground
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return intervalOptions.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        authenticationInfo?.updateRequiredPasscodeInterval(intervalOptions[indexPath.row])
        KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(authenticationInfo)
        tableView.reloadData()
    }
}
