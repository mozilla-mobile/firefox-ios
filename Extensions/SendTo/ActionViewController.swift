// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import MobileCoreServices

let SharedContainerIdentifier = "group.org.allizom.Client" // TODO: Can we grab this from the .entitlements file instead?

func pushUrl(url: String, #title: String, toClient client: Client) {
    let request = NSMutableURLRequest(URL: NSURL(string: "https://moz-syncapi.sateh.com/1.0/clients/" + client.id + "/tab")!)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.HTTPMethod = "POST"
    
    var object = NSMutableDictionary()
    object["url"] = url
    object["title"] = title
    
    var jsonError: NSError?
    let data = NSJSONSerialization.dataWithJSONObject(object, options: nil, error: &jsonError)
    if data != nil {
        request.HTTPBody = data
    }
    
    let userPasswordString = "sarentz+syncapi@mozilla.com:q1w2e3r4"
    let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
    let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(nil)
    let authString = "Basic \(base64EncodedCredential)"
    
    let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.allizom.Client.SendTo")
    configuration.HTTPAdditionalHeaders = ["Authorization" : authString]
    configuration.sharedContainerIdentifier = SharedContainerIdentifier
    
    let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    let task = session.dataTaskWithRequest(request)
    task.resume()
}

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
            pushUrl(url.absoluteString!, title: "", toClient: client)
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
                attachments[0].loadItemForTypeIdentifier(kUTTypeURL as NSString, options:nil, completionHandler: { (obj, error) in
                    completionHandler(obj as? NSURL, title, error)
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
