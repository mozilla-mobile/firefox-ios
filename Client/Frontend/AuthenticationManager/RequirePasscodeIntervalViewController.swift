/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper

/// Screen presented to the user when selecting the time interval before requiring a passcode
class RequirePasscodeIntervalViewController: UITableViewController {
    let intervalOptions: [PasscodeInterval] = [
        .Immediately,
        .OneMinute,
        .FiveMinutes,
        .TenMinutes,
        .FifteenMinutes,
        .OneHour
    ]

    private let BasicCheckmarkCell = "BasicCheckmarkCell"
    private var authenticationInfo: AuthenticationKeychainInfo?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = AuthenticationStrings.requirePasscode

        tableView.accessibilityIdentifier = "AuthenticationManager.passcodeIntervalTableView"

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: BasicCheckmarkCell)
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        let headerFooterFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width, height: UIConstants.TableViewHeaderFooterHeight))
        let headerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        headerView.showTopBorder = false
        headerView.showBottomBorder = true

        let footerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        footerView.showTopBorder = true
        footerView.showBottomBorder = false

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.authenticationInfo = KeychainWrapper.authenticationInfo()
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BasicCheckmarkCell, for: indexPath)
        let option = intervalOptions[indexPath.row]
        let intervalTitle = AttributedString.tableRowTitle(option.settingTitle)
        cell.textLabel?.attributedText = intervalTitle
        cell.accessoryType = authenticationInfo?.requiredPasscodeInterval == option ? .Checkmark : .None
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return intervalOptions.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        authenticationInfo?.updateRequiredPasscodeInterval(intervalOptions[indexPath.row])
        KeychainWrapper.setAuthenticationInfo(authenticationInfo)
        tableView.reloadData()
    }
}
