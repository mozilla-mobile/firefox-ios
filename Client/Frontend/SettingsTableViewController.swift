/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SettingsTableViewController: UITableViewController {
    let SECTION_ACCOUNT = 0
    let SECTION_SEARCH = 1
    let NUMBER_OF_SECTIONS = 2

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

        if indexPath.section == SECTION_ACCOUNT {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: nil)
            cell.editingAccessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            cell.textLabel?.text = "Sign in"
        } else if indexPath.section == SECTION_SEARCH {
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
        return NUMBER_OF_SECTIONS
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_ACCOUNT {
            return 1
        } else if section == SECTION_SEARCH {
            return 1
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_ACCOUNT {
            return nil
        } else if section == SECTION_SEARCH {
            return NSLocalizedString("Search", comment: "Settings")
        } else {
            return nil
        }
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == SECTION_SEARCH {
            let viewController = SearchSettingsTableViewController()
            viewController.model = profile.searchEngines
            navigationController?.pushViewController(viewController, animated: true)
        }
        return nil
    }
}
