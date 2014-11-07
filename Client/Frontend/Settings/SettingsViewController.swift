// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var signOutButton: UIButton!

    var accountManager: AccountManager!
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.layer.masksToBounds = true
        
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        settingsTableView.separatorInset = UIEdgeInsetsZero
        settingsTableView.editing = true
        settingsTableView.backgroundColor = view.backgroundColor
        
        signOutButton.layer.borderColor = UIColor.whiteColor().CGColor
        signOutButton.layer.borderWidth = 1.0
        signOutButton.layer.cornerRadius = 6.0
        signOutButton.addTarget(self, action: "didClickLogin", forControlEvents: UIControlEvents.TouchUpInside)
    }

    // Referenced as button selector.
    func didClickLogin() {
        accountManager.logout()
    }

    //
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        
        let labels = ["Tabs", "History", "Bookmarks", "Reader"]
        
        cell.textLabel.text = labels[indexPath.row]
        cell.textLabel.font = UIFont(name: "FiraSans-Light", size: cell.textLabel.font.pointSize)
        cell.textLabel.textColor = UIColor.whiteColor()
        cell.backgroundColor = self.view.backgroundColor
        cell.separatorInset = UIEdgeInsetsZero
        
        let switsch: UISwitch = UISwitch()
        switsch.on = (indexPath.row != 1)
        cell.editingAccessoryView = switsch
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.editing {
            for v in cell.subviews as [UIView] {
                if v.frame.width == 1.0 {
                    v.backgroundColor = UIColor.clearColor()
                }
            }
        }
    }
}
