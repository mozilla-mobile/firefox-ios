/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Snap
import FxA

class SettingsPanel: UIViewController, ToolbarViewProtocol,
        UITableViewDataSource, UITableViewDelegate, FxASignInViewControllerDelegate
{
    var avatarImageView: UIImageView!
    var nameLabel: UILabel!
    var emailLabel: UILabel!
    var settingsTableView: UITableView!
    var signOutButton: UIButton!

    var profile: Profile!

    let SETTING_CELL_ID = "SETTING_CELL_ID"

    lazy var panels: Panels = {
        return Panels(profile: self.profile)
    }()

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func viewDidLoad() {
        view.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)

        let userContainer = UIView()
        view.addSubview(userContainer)
        userContainer.snp_makeConstraints { make in
            make.top.equalTo(self.view).offset(64)
            make.centerX.equalTo(self.view)
        }

        // User image
        let madhavaImage = UIImage(named: "Madhava")
        avatarImageView = UIImageView(image: madhavaImage)
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.layer.masksToBounds = true
        avatarImageView.isAccessibilityElement = true
        avatarImageView.accessibilityLabel = NSLocalizedString("Avatar", comment: "")
        userContainer.addSubview(avatarImageView)
        avatarImageView.snp_makeConstraints { make in
            make.top.bottom.leading.equalTo(userContainer)
            make.width.height.equalTo(100)
        }

        // Name label
        nameLabel = UILabel()
        nameLabel.textColor = UIColor.whiteColor()
        nameLabel.font = UIFont(name: "FiraSans-SemiBold", size: 20)
        nameLabel.text = "ROLLO TOMASI"
        userContainer.addSubview(nameLabel)
        nameLabel.snp_makeConstraints { make in
            make.leading.equalTo(self.avatarImageView.snp_trailing)
            make.top.trailing.equalTo(userContainer)
        }

        // Email label
        emailLabel = UILabel()
        emailLabel.textColor = UIColor.whiteColor()
        emailLabel.font = UIFont(name: "FiraSans-UltraLight", size: 13)
        emailLabel.text = "rollo.tomasi@email.org"
        userContainer.addSubview(emailLabel)
        emailLabel.snp_makeConstraints { make in
            make.leading.equalTo(self.avatarImageView.snp_right)
            make.top.equalTo(self.nameLabel.snp_bottom)
        }

        // Settings table
        settingsTableView = UITableView()
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        settingsTableView.separatorInset = UIEdgeInsetsZero
        settingsTableView.editing = true
        settingsTableView.allowsSelectionDuringEditing = true
        settingsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: SETTING_CELL_ID)
        settingsTableView.scrollEnabled = false
        view.addSubview(settingsTableView)
        settingsTableView.snp_makeConstraints { make in
            make.top.equalTo(userContainer.snp_bottom).offset(64)
            make.left.right.equalTo(self.view).offset(8)
            make.height.equalTo(190)
        }

        // Sign out button
        signOutButton = UIButton()
        signOutButton.setTitle("Sign Out", forState: UIControlState.Normal)
signOutButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        signOutButton.titleLabel!.font = UIFont(name: "FiraSans-Light", size: 15)
        signOutButton.layer.borderColor = UIColor.whiteColor().CGColor
        signOutButton.layer.borderWidth = 1.0
        signOutButton.layer.cornerRadius = 6.0
        signOutButton.contentEdgeInsets = UIEdgeInsetsMake(4, 6, 4, 6)
        signOutButton.addTarget(self, action: "SELdidClickLogout", forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(signOutButton)
        signOutButton.snp_makeConstraints { make in
            make.top.equalTo(self.settingsTableView.snp_bottom).offset(64)
            make.centerX.equalTo(self.view)
        }

        // Copyright
        let copyrightLabel = UILabel()
        copyrightLabel.textColor = UIColor.whiteColor()
        copyrightLabel.font = UIFont(name: "FiraSans-Light", size: 11)
        copyrightLabel.text = "© 2014 Mozilla"
        view.addSubview(copyrightLabel)
        copyrightLabel.snp_makeConstraints { make in
            make.leading.bottom.equalTo(self.view)
            return
        }

        // Project
        let projectLabel = UILabel()
        projectLabel.textColor = UIColor.whiteColor()
        projectLabel.font = UIFont(name: "FiraSans-Light", size: 11)
        projectLabel.text = "Project 105, v0.01a"
        view.addSubview(projectLabel)
        projectLabel.snp_makeConstraints { make in
            make.trailing.bottom.equalTo(self.view)
            return
        }
        updateButton(profile.getAccount())
    }

    func updateButton(account: FirefoxAccount?) {
        nameLabel.text = account?.email
        emailLabel.text = account?.email

        let signInOrOutLabel = account == nil
            ? NSLocalizedString("Sign in", comment: "")
            : NSLocalizedString("Sign out", comment: "")

        signOutButton.setTitle(signInOrOutLabel, forState: UIControlState.Normal)
    }

    func signInViewControllerDidCancel(vc: FxASignInViewController) {
        vc.dismissViewControllerAnimated(true, completion: nil)
    }

    // A temporary delegate which merely updates the displayed email address on
    // succesful Firefox Accounts sign in.
    func signInViewControllerDidSignIn(vc: FxASignInViewController, data: JSON) {
        // TODO: Error handling.
        let state = FirefoxAccountState.Engaged(
            verified: false, // TODO: have fxa-content-server provide this.
            sessionToken: NSData(base16EncodedString: data["sessionToken"].asString!, options: NSDataBase16DecodingOptions.allZeros),
            keyFetchToken: NSData(base16EncodedString: data["keyFetchToken"].asString!, options: NSDataBase16DecodingOptions.allZeros),
            unwrapkB: NSData(base16EncodedString: data["unwrapBKey"].asString!, options: NSDataBase16DecodingOptions.allZeros)
        )

        let account = FirefoxAccount(
            email: data["email"].asString!,
            uid: data["uid"].asString!,
            authEndpoint: NSURL(string: FxASignInEndpoint)!,
            contentEndpoint: NSURL(string: FxASignInEndpoint)!,
            oauthEndpoint: NSURL(string: FxASignInEndpoint)!,
            state: state
        )

        profile.setAccount(account)
        updateButton(account)
    }

    // Temporarily, we show the Firefox Accounts sign in view.
    func SELdidClickLogout() {
        if (profile.getAccount() != nil) {
            profile.setAccount(nil)
            updateButton(profile.getAccount())
        } else {
            let vc = FxASignInViewController()
            vc.signInDelegate = self
            presentViewController(vc, animated: true, completion: nil)
        }
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
            cell.textLabel?.text = item.title
            cell.textLabel?.font = UIFont(name: "FiraSans-Light", size: cell.textLabel?.font.pointSize ?? 0)
            cell.textLabel?.textColor = UIColor.whiteColor()
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
