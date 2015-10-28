/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import SnapKit

protocol ClientPickerViewControllerDelegate {
    func clientPickerViewControllerDidCancel(clientPickerViewController: ClientPickerViewController) -> Void
    func clientPickerViewController(clientPickerViewController: ClientPickerViewController, didPickClients clients: [RemoteClient]) -> Void
}

struct ClientPickerViewControllerUX {
    static let TableHeaderRowHeight = CGFloat(50)
    static let TableHeaderTextFont = UIFont.systemFontOfSize(16)
    static let TableHeaderTextColor = UIColor.grayColor()
    static let TableHeaderTextPaddingLeft = CGFloat(20)

    static let DeviceRowTintColor = UIColor(red:0.427, green:0.800, blue:0.102, alpha:1.0)
    static let DeviceRowHeight = CGFloat(50)
    static let DeviceRowTextFont = UIFont.systemFontOfSize(16)
    static let DeviceRowTextPaddingLeft = CGFloat(72)
    static let DeviceRowTextPaddingRight = CGFloat(50)
}

/// The ClientPickerViewController displays a list of clients associated with the provided Account.
/// The user can select a number of devices and hit the Send button.
/// This viewcontroller does not implement any specific business logic that needs to happen with the selected clients.
/// That is up to it's delegate, who can listen for cancellation and success events.

class ClientPickerViewController: UITableViewController {
    var profile: Profile?
    var clientPickerDelegate: ClientPickerViewControllerDelegate?

    var reloading = true
    var clients: [RemoteClient] = []
    var selectedClients = NSMutableSet()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Send Tab", tableName: "SendTo", comment: "Title of the dialog that allows you to send a tab to a different device")
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        tableView.registerClass(ClientPickerTableViewHeaderCell.self, forCellReuseIdentifier: ClientPickerTableViewHeaderCell.CellIdentifier)
        tableView.registerClass(ClientPickerTableViewCell.self, forCellReuseIdentifier: ClientPickerTableViewCell.CellIdentifier)
        tableView.registerClass(ClientPickerNoClientsTableViewCell.self, forCellReuseIdentifier: ClientPickerNoClientsTableViewCell.CellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let refreshControl = refreshControl {
            refreshControl.beginRefreshing()
            let height = -(refreshControl.bounds.size.height + (self.navigationController?.navigationBar.bounds.size.height ?? 0))
            self.tableView.contentOffset = CGPointMake(0, height)
        }
        reloadClients()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if clients.count == 0 {
            return 1
        } else {
            return 2
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if clients.count == 0 {
            return 1
        } else {
            if section == 0 {
                return 1
            } else {
                return clients.count
            }
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell

        if clients.count > 0 {
            if indexPath.section == 0 {
                cell = tableView.dequeueReusableCellWithIdentifier(ClientPickerTableViewHeaderCell.CellIdentifier, forIndexPath: indexPath) as! ClientPickerTableViewHeaderCell
            } else {
                let clientCell = tableView.dequeueReusableCellWithIdentifier(ClientPickerTableViewCell.CellIdentifier, forIndexPath: indexPath) as! ClientPickerTableViewCell
                clientCell.nameLabel.text = clients[indexPath.row].name
                clientCell.clientType = clients[indexPath.row].type == "mobile" ? ClientType.Mobile : ClientType.Desktop
                clientCell.checked = selectedClients.containsObject(indexPath)
                cell = clientCell
            }
        } else {
            if reloading == false {
                cell = tableView.dequeueReusableCellWithIdentifier(ClientPickerNoClientsTableViewCell.CellIdentifier, forIndexPath: indexPath) as! ClientPickerNoClientsTableViewCell
            } else {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "ClientCell")
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if clients.count > 0 && indexPath.section == 1 {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)

            if selectedClients.containsObject(indexPath) {
                selectedClients.removeObject(indexPath)
            } else {
                selectedClients.addObject(indexPath)
            }

            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)

            navigationItem.rightBarButtonItem?.enabled = (selectedClients.count != 0)
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if clients.count > 0 {
            if indexPath.section == 0 {
                return ClientPickerViewControllerUX.TableHeaderRowHeight
            } else {
                return ClientPickerViewControllerUX.DeviceRowHeight
            }
        } else {
            return tableView.frame.height
        }
    }

    private func reloadClients() {
        guard let profile = self.profile else {
            return
        }

        reloading = true
        profile.getClients().upon({ result in
            withExtendedLifetime(profile) {
                self.reloading = false
                guard let c = result.successValue else {
                    return
                }

                self.clients = c
                dispatch_async(dispatch_get_main_queue()) {
                    if self.clients.count == 0 {
                        self.navigationItem.rightBarButtonItem = nil
                    } else {
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Send", tableName: "SendTo", comment: "Navigation bar button to Send the current page to a device"), style: UIBarButtonItemStyle.Done, target: self, action: "send")
                        self.navigationItem.rightBarButtonItem?.enabled = false
                    }
                    self.selectedClients.removeAllObjects()
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            }
        })
    }

    func refresh() {
        reloadClients()
    }

    func cancel() {
        clientPickerDelegate?.clientPickerViewControllerDidCancel(self)
    }

    func send() {
        var clients = [RemoteClient]()
        for indexPath in selectedClients {
            clients.append(self.clients[indexPath.row])
        }
        clientPickerDelegate?.clientPickerViewController(self, didPickClients: clients)
    }
}

class ClientPickerTableViewHeaderCell: UITableViewCell {
    static let CellIdentifier = "ClientPickerTableViewSectionHeader"
    let nameLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(nameLabel)
        nameLabel.font = ClientPickerViewControllerUX.TableHeaderTextFont
        nameLabel.text = NSLocalizedString("Available devices:", tableName: "SendTo", comment: "Header for the list of devices table")
        nameLabel.textColor = ClientPickerViewControllerUX.TableHeaderTextColor

        nameLabel.snp_makeConstraints{ (make) -> Void in
            make.left.equalTo(ClientPickerViewControllerUX.TableHeaderTextPaddingLeft)
            make.centerY.equalTo(self)
            make.right.equalTo(self)
        }

        preservesSuperviewLayoutMargins = false
        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsZero
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public enum ClientType: String {
    case Mobile = "deviceTypeMobile"
    case Desktop = "deviceTypeDesktop"
}

class ClientPickerTableViewCell: UITableViewCell {
    static let CellIdentifier = "ClientPickerTableViewCell"

    var nameLabel: UILabel
    var checked: Bool = false {
        didSet {
            self.accessoryType = checked ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        }
    }

    var clientType: ClientType = ClientType.Mobile {
        didSet {
            self.imageView?.image = UIImage(named: clientType.rawValue)
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        nameLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        nameLabel.font = ClientPickerViewControllerUX.DeviceRowTextFont
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        self.tintColor = ClientPickerViewControllerUX.DeviceRowTintColor
        self.preservesSuperviewLayoutMargins = false
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.snp_makeConstraints{ (make) -> Void in
            make.left.equalTo(ClientPickerViewControllerUX.DeviceRowTextPaddingLeft)
            make.centerY.equalTo(self.snp_centerY)
            make.right.equalTo(self.snp_right).offset(-ClientPickerViewControllerUX.DeviceRowTextPaddingRight)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class ClientPickerNoClientsTableViewCell: UITableViewCell {
    static let CellIdentifier = "ClientPickerNoClientsTableViewCell"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupHelpView(contentView,
            introText: NSLocalizedString("You don't have any other devices connected to this Firefox Account available to sync.", tableName: "SendTo", comment: "Error message shown in the remote tabs panel"),
            showMeText: "") // TODO We used to have a 'show me how to ...' text here. But, we cannot open web pages from the extension. So this is clear for now until we decide otherwise.
        // Move the separator off screen
        separatorInset = UIEdgeInsetsMake(0, 1000, 0, 0)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
