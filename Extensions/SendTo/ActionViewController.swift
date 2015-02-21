/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Snap

protocol LoginViewControllerDelegate {
    func loginViewControllerDidCancel(loginViewController: LoginViewController) -> Void
}

/*!
The LoginViewController is a viewcontroller that we show if the user is not logged in yet.
It not clear yet what needs to be done so consider this a temporary placeholder for now.
*/

class LoginViewController: UIViewController {
    var delegate: LoginViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()
        
        let label = UILabel()
        label.text = NSLocalizedString("TODO Not logged in.", comment: "")
        view.addSubview(label)
        label.snp_makeConstraints { (make) -> () in
            make.center.equalTo(label.superview!)
            return
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
    }

    func cancel() {
        delegate?.loginViewControllerDidCancel(self)
    }
}

protocol ClientPickerViewControllerDelegate {
    func clientPickerViewControllerDidCancel(clientPickerViewController: ClientPickerViewController) -> Void
    func clientPickerViewController(clientPickerViewController: ClientPickerViewController, didPickClients clients: [Client]) -> Void
}

/*!
The ClientPickerViewController displays a list of clients associated with the provided Account.
The user can select a number of devices and hit the Send button.
This viewcontroller does not implement any specific business logic that needs to happen with the selected clients.
That is up to it's delegate, who can listen for cancellation and success events.
*/

class ClientPickerViewController: UITableViewController {
    var profile: Profile?
    var clientPickerDelegate: ClientPickerViewControllerDelegate?
    
    var clients: [Client] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Send To Device", comment: "")
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadClients()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clients.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.font = UIFont(name: "FiraSans-Regular", size: 17)
        cell.textLabel?.text = NSLocalizedString("Send to ", comment: "") + clients[indexPath.row].name // TODO This needs a localized format string
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        clientPickerDelegate?.clientPickerViewController(self, didPickClients: [clients[indexPath.row]])
    }
    
    private func reloadClients() {
        profile?.clients.getAll(
            { response in
                self.clients = response
                dispatch_async(dispatch_get_main_queue()) {
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            },
            error: { err in
                // TODO: Figure out a good way to handle this.
                print("Error: could not load clients: ")
                println(err)
        })
    }
    
    func refresh() {
        reloadClients()
    }
    
    func cancel() {
        self.extensionContext!.completeRequestReturningItems(nil, completionHandler: nil)
    }
}

/*!
The ActionViewController is the initial viewcontroller that is presented (full screen) when the share extension is activated.
Depending on whether the user is logged in or not, this viewcontroller will present either a Login or ClientPicker.
*/

@objc(ActionViewController)
class ActionViewController: UINavigationController, ClientPickerViewControllerDelegate, LoginViewControllerDelegate
{
    var profile: Profile?
    var sharedItem: ShareItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ExtensionUtils.extractSharedItemFromExtensionContext(self.extensionContext, completionHandler: { (item, error) -> Void in
            if error == nil && item != nil {
                self.sharedItem = item
                
                if self.profile == nil {
                    let loginViewController = LoginViewController()
                    loginViewController.delegate = self
                    self.pushViewController(loginViewController, animated: false)
                } else {
                    let clientPickerViewController = ClientPickerViewController()
                    clientPickerViewController.clientPickerDelegate = self
                    clientPickerViewController.profile = self.profile
                    self.pushViewController(clientPickerViewController, animated: false)
                }
            } else {
                self.extensionContext!.completeRequestReturningItems([], completionHandler: nil);
            }
        })
    }

    func finish() {
        self.extensionContext!.completeRequestReturningItems(nil, completionHandler: nil)
    }

    func clientPickerViewController(clientPickerViewController: ClientPickerViewController, didPickClients clients: [Client]) {
        profile?.clients.sendItem(self.sharedItem!, toClients: clients)
        finish()
    }
    
    func clientPickerViewControllerDidCancel(clientPickerViewController: ClientPickerViewController) {
        finish()
    }
    
    func loginViewControllerDidCancel(loginViewController: LoginViewController) {
        finish()
    }
}
