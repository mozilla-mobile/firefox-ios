/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Base32
import UIKit

class SettingsTableViewController: UITableViewController {
    let SECTION_ACCOUNT = 0
    let ITEM_ACCOUNT_STATUS = 0
    let ITEM_ACCOUNT_DISCONNECT = 1

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
            if indexPath.item == ITEM_ACCOUNT_STATUS {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: nil)
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                updateCell(cell, toReflectAccount: profile.getAccount())
            } else if indexPath.item == ITEM_ACCOUNT_DISCONNECT {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
                cell.textLabel?.text = NSLocalizedString("Disconnect", comment: "Settings")
            } else {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            }
        } else if indexPath.section == SECTION_SEARCH {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
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
            if profile.getAccount() == nil {
                // Just "Sign in".
                return 1
            } else {
                // Account state, and "Disconnect."
                return 2
            }
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
        if indexPath.section == SECTION_ACCOUNT {
            switch indexPath.item {
            case ITEM_ACCOUNT_STATUS:
                let viewController = FxAContentViewController()
                viewController.delegate = self
                if let account = profile.getAccount() {
                    switch account.getActionNeeded() {
                    case .None, .NeedsVerification:
                        let cs = NSURLComponents(URL: profile.accountConfiguration.settingsURL, resolvingAgainstBaseURL: false)
                        cs?.queryItems?.append(NSURLQueryItem(name: "email", value: account.email))
                        viewController.url = cs?.URL
                    case .NeedsPassword:
                        let cs = NSURLComponents(URL: profile.accountConfiguration.forceAuthURL, resolvingAgainstBaseURL: false)
                        cs?.queryItems?.append(NSURLQueryItem(name: "email", value: account.email))
                        viewController.url = cs?.URL
                    case .NeedsUpgrade:
                        // In future, we'll want to link to an upgrade page.
                        break
                    }
                } else {
                    viewController.url = profile.accountConfiguration.signInURL
                }
                navigationController?.pushViewController(viewController, animated: true)

            case ITEM_ACCOUNT_DISCONNECT:
                maybeDisconnectAccount()

            default:
                break
            }
        } else if indexPath.section == SECTION_SEARCH {
            let viewController = SearchSettingsTableViewController()
            viewController.model = profile.searchEngines
            navigationController?.pushViewController(viewController, animated: true)
        }
        return nil
    }

    func updateCell(cell: UITableViewCell, toReflectAccount account: FirefoxAccount?) {
        if let account = account {
            cell.textLabel?.text = account.email
            cell.detailTextLabel?.text = nil

            switch account.getActionNeeded() {
            case .None:
                break
            case .NeedsVerification:
                cell.detailTextLabel?.text = NSLocalizedString("Verify your email address.", comment: "Settings")
            case .NeedsPassword:
                // This assumes we never recycle cells.
                cell.detailTextLabel?.textColor = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1) // Firefox orange!
                cell.detailTextLabel?.text = NSLocalizedString("Enter your password to connect.", comment: "Settings")
            case .NeedsUpgrade:
                cell.detailTextLabel?.textColor = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1) // Firefox orange!
                cell.detailTextLabel?.text = NSLocalizedString("Upgrade Firefox to connect.", comment: "Settings")
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        } else {
            cell.textLabel?.text = NSLocalizedString("Sign in", comment: "Settings")
        }
    }

    func maybeDisconnectAccount() {
        let alertController = UIAlertController(
            title: NSLocalizedString("Disconnect Firefox Account?", comment: "Settings"),
            message: NSLocalizedString("Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Settings"),
            preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", comment: "Settings"), style: .Cancel) { (action) in
                // Do nothing.
            })
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Disconnect", comment: "Settings"), style: .Destructive) { (action) in
                self.profile.setAccount(nil)
                self.tableView.reloadData()
            })
        presentViewController(alertController, animated: true, completion: nil)
    }
}

extension SettingsTableViewController: FxAContentViewControllerDelegate {
    func contentViewControllerDidSignIn(viewController: FxAContentViewController, data: JSON) {
        if data["keyFetchToken"].asString? == nil || data["unwrapBKey"].asString? == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            NSLog("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            return
        }

        // TODO: Error handling.
        let state = FirefoxAccountState.Engaged(
            verified: data["verified"].asBool ?? false,
            sessionToken: data["sessionToken"].asString!.hexDecodedData,
            keyFetchToken: data["keyFetchToken"].asString!.hexDecodedData,
            unwrapkB: data["unwrapBKey"].asString!.hexDecodedData
        )

        let account = FirefoxAccount(
            email: data["email"].asString!,
            uid: data["uid"].asString!,
            authEndpoint: profile.accountConfiguration.authEndpointURL,
            contentEndpoint: profile.accountConfiguration.profileEndpointURL,
            oauthEndpoint: profile.accountConfiguration.oauthEndpointURL,
            state: state
        )

        profile.setAccount(account)
        tableView.reloadData()
        navigationController?.popToRootViewControllerAnimated(true)
    }

    func contentViewControllerDidCancel(viewController: FxAContentViewController) {
        NSLog("didCancel")
        navigationController?.popToRootViewControllerAnimated(true)
    }
}
