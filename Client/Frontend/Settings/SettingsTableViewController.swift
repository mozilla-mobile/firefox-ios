/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SettingsTableViewController: UITableViewController {
    let SectionAccount = 0
    let SectionSearch = 1
    let NumberOfSections = 2

    var profile: Profile!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Settings", comment: "Settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Settings"),
            style: UIBarButtonItemStyle.Done,
            target: navigationController, action: "SELdone")
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell

        if indexPath.section == SectionAccount {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: nil)
            cell.editingAccessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            cell.textLabel?.text = NSLocalizedString("Sign in", comment: "Settings")
        } else if indexPath.section == SectionSearch {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            cell.editingAccessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            cell.textLabel?.text = NSLocalizedString("Search", comment: "Settings")
        } else {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        }

        // So that the seperator line goes all the way to the left edge.
        cell.separatorInset = UIEdgeInsetsZero

        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NumberOfSections
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionAccount {
            return 1
        } else if section == SectionSearch {
            return 1
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SectionAccount {
            return nil
        } else if section == SectionSearch {
            return NSLocalizedString("Search", comment: "Settings")
        } else {
            return nil
        }
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == SectionSearch {
            let viewController = SearchSettingsTableViewController()
            viewController.model = profile.searchEngines
            navigationController?.pushViewController(viewController, animated: true)
        }
        return nil
    }
}
