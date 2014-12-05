// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class SettingsViewController: UIViewController, ToolbarViewProtocol, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var signOutButton: UIButton!

    var account: Account!

    let SETTING_CELL_ID = "SETTING_CELL_ID"

    lazy var panels: Panels = {
        return Panels(account: self.account)
    }()
    
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
        settingsTableView.allowsSelectionDuringEditing = true
        
        settingsTableView.backgroundColor = view.backgroundColor
        settingsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: SETTING_CELL_ID)
        
        signOutButton.layer.borderColor = UIColor.whiteColor().CGColor
        signOutButton.layer.borderWidth = 1.0
        signOutButton.layer.cornerRadius = 6.0
        signOutButton.addTarget(self, action: "didClickLogout", forControlEvents: UIControlEvents.TouchUpInside)
    }

    // Referenced as button selector.
    func didClickLogout() {
        account.logout()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if let sw = cell?.editingAccessoryView as? UISwitch {
            sw.setOn(!sw.on, animated: true)
            panels.enablePanelAt(sw.on, position: indexPath.item)
        }

        return indexPath;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Subtract one so that we don't show our own panel
        return panels.count - 1;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(SETTING_CELL_ID, forIndexPath: indexPath) as UITableViewCell
        
        if var item = panels[indexPath.item] {
            cell.textLabel!.text = item.title
            cell.textLabel!.font = UIFont(name: "FiraSans-Light", size: cell.textLabel!.font.pointSize)
            cell.textLabel!.textColor = UIColor.whiteColor()
            cell.backgroundColor = self.view.backgroundColor
            cell.separatorInset = UIEdgeInsetsZero
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            let toggle: UISwitch = UISwitch()
            toggle.on = item.enabled;
            cell.editingAccessoryView = toggle
        }
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        panels.moveItem(sourceIndexPath.item, to: destinationIndexPath.item)
        settingsTableView.setNeedsDisplay();
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
