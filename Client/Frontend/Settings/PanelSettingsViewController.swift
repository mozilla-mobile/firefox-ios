/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

// Cell that displays the Panel name
private class PanelCell: UITableViewCell {
    static let Identifier = "PanelCell"

    lazy var panelTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(UIConstants.DefaultStandardFontSize, weight: UIFontWeightRegular)
        label.textColor = UIColor.blackColor()
        return label
    }()

    lazy var panelIcon: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = UIViewContentMode.ScaleAspectFit
        return icon
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        showsReorderControl = true

        contentView.addSubview(panelTitleLabel)
        contentView.addSubview(panelIcon)

        panelIcon.snp_makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.left.equalTo(contentView).offset(20)
            make.size.equalTo(CGSize(width: 32, height: 20))
        }

        panelTitleLabel.snp_makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.left.equalTo(panelIcon.snp_right).offset(20)
            make.right.equalTo(contentView).offset(-20)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View controller where the user can configure their home panels
class PanelSettingsViewController: UITableViewController {
    var panels = [HomePanelDescriptor]()
    var profile: Profile!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Panel Settings", comment: "Title for Customize Home Panels setting page")
        tableView.registerClass(PanelCell.self, forCellReuseIdentifier: PanelCell.Identifier)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        editing = true
        panels = HomePanels.enabledPanelsForProfile(profile)
        tableView.reloadData()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        let jsonStrings = panels.map { $0.jsonStringify() }
        profile.prefs.setStringArray(jsonStrings, forKey: "homePanels.enabled")
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return panels.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PanelCell.Identifier, forIndexPath: indexPath) as! PanelCell
        let panelDescriptor = panels[indexPath.row]
        cell.panelTitleLabel.text = panelDescriptor.accessibilityLabel
        cell.panelIcon.image = UIImage(named: "panelIcon\(panelDescriptor.imageName)")
        return cell
    }

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }

    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let movedPanel = panels[sourceIndexPath.row]
        panels.removeAtIndex(sourceIndexPath.row)
        panels.insert(movedPanel, atIndex: destinationIndexPath.row)
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
}
