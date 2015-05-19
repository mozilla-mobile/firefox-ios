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
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
        let cell = UITableViewCell()

        if clients.count > 0 {
            if indexPath.section == 0 {
                let textLabel = UILabel()
                cell.contentView.addSubview(textLabel)
                textLabel.font = ClientPickerViewControllerUX.TableHeaderTextFont
                textLabel.text = NSLocalizedString("Available devices:", tableName: "SendTo", comment: "Header for the list of devices table")
                textLabel.textColor = ClientPickerViewControllerUX.TableHeaderTextColor
                textLabel.snp_makeConstraints({ (make) -> Void in
                    make.left.equalTo(ClientPickerViewControllerUX.TableHeaderTextPaddingLeft)
                    make.centerY.equalTo(cell.snp_centerY)
                    make.right.equalTo(cell.snp_right)
                })

                cell.accessoryType = UITableViewCellAccessoryType.None
                cell.preservesSuperviewLayoutMargins = false
                cell.layoutMargins = UIEdgeInsetsZero
                cell.separatorInset = UIEdgeInsetsZero
            } else {
                let textLabel = UILabel()
                cell.contentView.addSubview(textLabel)
                textLabel.font = ClientPickerViewControllerUX.DeviceRowTextFont
                textLabel.text = clients[indexPath.row].name
                textLabel.numberOfLines = 2
                textLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
                textLabel.snp_makeConstraints({ (make) -> Void in
                    make.left.equalTo(ClientPickerViewControllerUX.DeviceRowTextPaddingLeft)
                    make.centerY.equalTo(cell.snp_centerY)
                    make.right.equalTo(cell.snp_right).offset(-ClientPickerViewControllerUX.DeviceRowTextPaddingRight)
                })

                cell.imageView?.image = UIImage(named: clients[indexPath.row].type == "mobile" ? "deviceTypeMobile" : "deviceTypeDesktop")
                cell.imageView?.transform = CGAffineTransformMakeScale(0.5, 0.5)

                cell.accessoryType = selectedClients.containsObject(indexPath) ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
                cell.tintColor = ClientPickerViewControllerUX.DeviceRowTintColor
                cell.preservesSuperviewLayoutMargins = false
            }
        } else {
            if reloading == false {
                setupHelpView(cell.contentView,
                    introText: NSLocalizedString("You currently don’t have any other devices currently connected to Firefox Sync. This needs proper copy. Do not translate.", tableName: "SendTo", comment: ""),
                    showMeText: NSLocalizedString("<Show me how> to connect my other Firefox-enabled devices. This needs proper copy. Do not translate.", tableName: "SendTo", comment: "The part between brackets is highlighted in styled text as if it is a link."))
                // Move the separator off screen
                cell.separatorInset = UIEdgeInsetsMake(0, 1000, 0, 0)
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
        reloading = true
        profile?.getClients().upon({ result in
            self.reloading = false
            self.refreshControl?.endRefreshing()
            if let c = result.successValue {
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
