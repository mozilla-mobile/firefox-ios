/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import SnapKit

protocol ClientPickerViewControllerDelegate {
    func clientPickerViewControllerDidCancel(_ clientPickerViewController: ClientPickerViewController)
    func clientPickerViewController(_ clientPickerViewController: ClientPickerViewController, didPickClients clients: [RemoteClient])
}

struct ClientPickerViewControllerUX {
    static let TableHeaderRowHeight = CGFloat(50)
    static let TableHeaderTextFont = UIFont.systemFont(ofSize: 16)
    static let TableHeaderTextColor = UIColor.gray
    static let TableHeaderTextPaddingLeft = CGFloat(20)

    static let DeviceRowTintColor = UIColor(red:0.427, green:0.800, blue:0.102, alpha:1.0)
    static let DeviceRowHeight = CGFloat(50)
    static let DeviceRowTextFont = UIFont.systemFont(ofSize: 16)
    static let DeviceRowTextPaddingLeft = CGFloat(72)
    static let DeviceRowTextPaddingRight = CGFloat(50)
}

/// The ClientPickerViewController displays a list of clients associated with the provided Account.
/// The user can select a number of devices and hit the Send button.
/// This viewcontroller does not implement any specific business logic that needs to happen with the selected clients.
/// That is up to it's delegate, who can listen for cancellation and success events.

class ClientPickerViewController: UITableViewController {
    var profile: Profile?
    var profileNeedsShutdown = true

    var clientPickerDelegate: ClientPickerViewControllerDelegate?

    var reloading = true
    var clients: [RemoteClient] = []
    var selectedClients = NSMutableSet()

    // ShareItem has been added as we are now using this class outside of the ShareTo extension to provide Share To functionality
    // And in this case we need to be able to store the item we are sharing as we may not have access to the 
    // url later. Currently used only when sharing an item from the Tab Tray from a Preview Action.
    var shareItem: ShareItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Send Tab", tableName: "SendTo", comment: "Title of the dialog that allows you to send a tab to a different device")
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(ClientPickerViewController.refresh), for: UIControlEvents.valueChanged)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Strings.SendToCancelButton,
            style: .plain,
            target: self,
            action:  #selector(ClientPickerViewController.cancel)
        )

        tableView.register(ClientPickerTableViewHeaderCell.self, forCellReuseIdentifier: ClientPickerTableViewHeaderCell.CellIdentifier)
        tableView.register(ClientPickerTableViewCell.self, forCellReuseIdentifier: ClientPickerTableViewCell.CellIdentifier)
        tableView.register(ClientPickerNoClientsTableViewCell.self, forCellReuseIdentifier: ClientPickerNoClientsTableViewCell.CellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let refreshControl = refreshControl {
            refreshControl.beginRefreshing()
            let height = -(refreshControl.bounds.size.height + (self.navigationController?.navigationBar.bounds.size.height ?? 0))
            self.tableView.contentOffset = CGPoint(x: 0, y: height)
        }
        reloadClients()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if clients.count == 0 {
            return 1
        } else {
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell

        if clients.count > 0 {
            if indexPath.section == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: ClientPickerTableViewHeaderCell.CellIdentifier, for: indexPath) as! ClientPickerTableViewHeaderCell
            } else {
                let clientCell = tableView.dequeueReusableCell(withIdentifier: ClientPickerTableViewCell.CellIdentifier, for: indexPath) as! ClientPickerTableViewCell
                clientCell.nameLabel.text = clients[indexPath.row].name
                clientCell.clientType = clients[indexPath.row].type == "mobile" ? ClientType.Mobile : ClientType.Desktop
                clientCell.checked = selectedClients.contains(indexPath)
                cell = clientCell
            }
        } else {
            if reloading == false {
                cell = tableView.dequeueReusableCell(withIdentifier: ClientPickerNoClientsTableViewCell.CellIdentifier, for: indexPath) as! ClientPickerNoClientsTableViewCell
            } else {
                cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "ClientCell")
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
         return indexPath.section != 0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if clients.count > 0 && indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)

            if selectedClients.contains(indexPath) {
                selectedClients.remove(indexPath)
            } else {
                selectedClients.add(indexPath)
            }

            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)

            navigationItem.rightBarButtonItem?.isEnabled = (selectedClients.count != 0)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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

    fileprivate func reloadClients() {
        // If we were not given a profile, open the default profile. This happens in case we are called from an app
        // extension. That also means that we need to shut down the profile, otherwise the app extension will be
        // terminated when it goes into the background.

        if self.profile == nil {
            self.profile = BrowserProfile(localName: "profile")
            self.profileNeedsShutdown = true
        }

        guard let profile = self.profile else {
            return
        }

        // Re-open the profile it was shutdown. This happens when we run from an app extension, where we must
        // make sure that the profile is only open for brief moments of time.

        if profile.isShutdown {
            profile.reopen()
        }

        reloading = true
        profile.getClients().upon({ result in
            withExtendedLifetime(profile) {
                // If we are running from an app extension then make sure we shut down the profile as soon as we are
                // done with it.

                if self.profileNeedsShutdown {
                    profile.shutdown()
                }

                self.reloading = false
                guard let c = result.successValue else {
                    return
                }

                self.clients = c
                DispatchQueue.main.async {
                    if self.clients.count == 0 {
                        self.navigationItem.rightBarButtonItem = nil
                    } else {
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Send", tableName: "SendTo", comment: "Navigation bar button to Send the current page to a device"), style: UIBarButtonItemStyle.done, target: self, action: #selector(ClientPickerViewController.send))
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
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
            clients.append(self.clients[(indexPath as AnyObject).row])
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

        nameLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(ClientPickerViewControllerUX.TableHeaderTextPaddingLeft)
            make.centerY.equalTo(self)
            make.right.equalTo(self)
        }

        preservesSuperviewLayoutMargins = false
        layoutMargins = UIEdgeInsets.zero
        separatorInset = UIEdgeInsets.zero
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
            self.accessoryType = checked ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
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
        nameLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.tintColor = ClientPickerViewControllerUX.DeviceRowTintColor
        self.preservesSuperviewLayoutMargins = false
        self.selectionStyle = UITableViewCellSelectionStyle.none
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(ClientPickerViewControllerUX.DeviceRowTextPaddingLeft)
            make.centerY.equalTo(self.snp.centerY)
            make.right.equalTo(self.snp.right).offset(-ClientPickerViewControllerUX.DeviceRowTextPaddingRight)
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
        separatorInset = UIEdgeInsets(top: 0, left: 1000, bottom: 0, right: 0)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
