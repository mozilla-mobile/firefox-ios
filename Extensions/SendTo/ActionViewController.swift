// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import MobileCoreServices

class DevicesViewController: UITableViewController
{
    var clients: [Client] = []
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Clients.getAll { (clients) -> Void in
            self.clients = clients
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        title = NSLocalizedString("Send To Device", comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clients.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel.text = clients[indexPath.row].name
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let client = clients[indexPath.row]
        fetchSharedURL { (url, title, error) -> Void in
            Clients.sendURL(url.absoluteString!, toClient: client)
            self.extensionContext!.completeRequestReturningItems([], completionHandler: nil);
        }
    }
    
    func cancel() {
        self.extensionContext!.completeRequestReturningItems(nil, completionHandler: nil)
    }
    
    func fetchSharedURL(completionHandler: (NSURL!, String?, NSError!) -> Void) {
        var title : String? = nil;
        
        if let inputItems : [NSExtensionItem] = self.extensionContext!.inputItems as? [NSExtensionItem] {
            let item = inputItems[0]
            title = item.attributedContentText?.string as String?
            if let attachments = item.attachments as? [NSItemProvider] {
                attachments[0].loadItemForTypeIdentifier(kUTTypeURL, options:nil, completionHandler: { (obj, error) in
                    if error == nil {
                        completionHandler(obj as? NSURL, title, error)
                    } else {
                        completionHandler(nil, nil, error)
                    }
                })
            }
        }
    }
}

@objc(ActionViewController)
class ActionViewController: UINavigationController
{
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        pushViewController(DevicesViewController(), animated: false)
    }
}
