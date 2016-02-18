/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

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

    private let prefs: Prefs
    private let BasicCheckmarkCell = "BasicCheckmarkCell"
    private var selectedInterval: PasscodeInterval?

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = AuthenticationStrings.requirePasscode

        tableView.accessibilityIdentifier = "AuthenticationManager.passcodeIntervalTableView"

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: BasicCheckmarkCell)
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        let headerFooterFrame = CGRect(origin: CGPointZero, size: CGSize(width: 0, height: UIConstants.TableViewHeaderFooterHeight))
        let headerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        headerView.showTopBorder = false
        headerView.showBottomBorder = true

        let footerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        footerView.showTopBorder = true
        footerView.showBottomBorder = false

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let intervalTime = prefs.intForKey(PrefKeyRequirePasscodeInterval) {
            self.selectedInterval = PasscodeInterval(rawValue: intervalTime)
        }
        tableView.reloadData()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(BasicCheckmarkCell, forIndexPath: indexPath)
        let option = intervalOptions[indexPath.row]
        let intervalTitle = NSAttributedString.tableRowTitle(option.settingTitle)
        cell.textLabel?.attributedText = intervalTitle
        cell.accessoryType = selectedInterval == option ? .Checkmark : .None
        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return intervalOptions.count
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedOption = intervalOptions[indexPath.row]
        selectedInterval = selectedOption
        prefs.setInt(selectedOption.rawValue, forKey: PrefKeyRequirePasscodeInterval)
        tableView.reloadData()
    }
}
