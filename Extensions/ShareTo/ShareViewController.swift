// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Social

typealias ShareDestinationPickerCompletionHandler = (selectedItem: Int) -> Void

let SharedContainerIdentifier = "group.Client" // TODO: Can we grab this from the .entitlements file instead?
let LastSelectedShareDestinationDefault = "LastSelectedShareDestination"

let ShareDestinations = [
    NSLocalizedString("Add to my Mobile Bookmarks", comment: ""),
    NSLocalizedString("Add to my Reading List", comment: "")
]

class ShareDestinationPickerViewController: UITableViewController
{
    var completionHandler: ShareDestinationPickerCompletionHandler?
    var selectedItem: Int?
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel.text = ShareDestinations[indexPath.row]
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        completionHandler?(selectedItem: indexPath.row)
    }
}

struct SharedBookmark {
    var url: String
    var title: String
}

func findViewInSubviews(view: UIView, test: (UIView) -> Bool) -> UIView? {
    for v in view.subviews as [UIView] {
        if test(v) {
            return v
        }
        if let r = findViewInSubviews(v, test) {
            return r
        }
    }
    return nil
}

class ShareViewController: SLComposeServiceViewController, NSURLSessionDelegate
{
    var selectedItem = 0
    var configurationItem = SLComposeSheetConfigurationItem()
    var logo: UIImageView?
    
    func findNavigationBar() -> UINavigationBar? {
        return findViewInSubviews(view, { (v) -> Bool in
            return (v as? UINavigationBar) != nil
        }) as? UINavigationBar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        navigationController?.navigationBar.backgroundColor = UIColor.orangeColor()
        
        if let navigationBar = findNavigationBar() {
            logo = UIImageView(image: UIImage(named: "flat-logo"))
            navigationBar.addSubview(logo!)
        }
        
        selectedItem = NSUserDefaults.standardUserDefaults().integerForKey(LastSelectedShareDestinationDefault)
        
        configurationItem.title = ShareDestinations[selectedItem]
        configurationItem.tapHandler = {
            let vc = ShareDestinationPickerViewController()
            vc.completionHandler = { (selectedItem:Int) -> Void in
                NSUserDefaults.standardUserDefaults().setInteger(selectedItem, forKey: LastSelectedShareDestinationDefault)
                self.selectedItem = selectedItem
                self.configurationItem.title = ShareDestinations[selectedItem]
                self.reloadConfigurationItems()
                self.popConfigurationViewController()
            }
            self.pushConfigurationViewController(vc)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if logo != nil {
            let navigationBar: UINavigationBar = view.subviews[2].subviews[2] as UINavigationBar
            if navigationBar.frame.height < 44 { // TODO: Is there a better way to detect the smaller navigation bar?
                logo?.frame = CGRect(x: (navigationBar.frame.width/2)-16, y: 4, width: 24, height: 24)
            } else {
                logo?.frame = CGRect(x: (navigationBar.frame.width/2)-16, y: 6, width: 32, height: 32)
            }
            logo?.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin
        }
    }
    
    override func isContentValid() -> Bool {
        return true
    }
    
    func shareBookmark(bookmark: SharedBookmark, credentials: Credentials) {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://moz-syncapi.sateh.com/1.0/bookmarks")!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.HTTPMethod = "POST"
        
        var object = NSMutableDictionary()
        object["url"] = bookmark.url
        object["title"] = bookmark.title
        
        var jsonError: NSError?
        let data = NSJSONSerialization.dataWithJSONObject(object, options: nil, error: &jsonError)
        if data != nil {
            request.HTTPBody = data
        }
        
        let userPasswordString = "\(credentials.username!):\(credentials.password!)"
        let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(nil)
        let authString = "Basic \(base64EncodedCredential)"
        
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.Client.ShareToFirefox")
        configuration.HTTPAdditionalHeaders = ["Authorization" : authString]
        configuration.sharedContainerIdentifier = SharedContainerIdentifier
        
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        let task = session.dataTaskWithRequest(request)
        task.resume()
    }
    
    func fetchSharedURL(completionHandler: (NSURL!, NSError!) -> Void) {
        if let inputItems : [NSExtensionItem] = self.extensionContext!.inputItems as? [NSExtensionItem] {
            let item = inputItems[0]
            if let attachments = item.attachments as? [NSItemProvider] {
                attachments[0].loadItemForTypeIdentifier("public.url", options:nil, completionHandler: { (obj, error) in
                    completionHandler(obj as? NSURL, error)
                })
            }
        }
    }
    
    override func didSelectPost() {
        let login = Login()
//        if login.isLoggedIn() {
            fetchSharedURL({ (url, error) -> Void in
                if url != nil {
                    let sharedBookmark = SharedBookmark(url: url.absoluteString!, title: self.textView.text)
                    let credentials = Credentials(username: "sarentz+syncapi@mozilla.com", password: "q1w2e3r4") // Login().getKeychainUser(login.getUsername())
                    self.shareBookmark(sharedBookmark, credentials: credentials)
                    self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
                }
            })
//        }
    }
    
    override func configurationItems() -> [AnyObject]! {
        return [configurationItem]
    }
    
    override func loadPreviewView() -> UIView! {
        return nil
    }
}
