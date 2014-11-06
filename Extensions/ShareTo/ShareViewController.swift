// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Social
import MobileCoreServices

typealias ShareHandler = (url: NSURL, title: String?) -> Void
typealias ShareDestinationPickerCompletionHandler = (selectedItem: Int) -> Void

let SharedContainerIdentifier = "group.org.allizom.Client" // TODO: Can we grab this from the .entitlements file instead?
let LastSelectedShareDestinationDefault = "LastSelectedShareDestination"

class ShareDestination {
    var name: NSString = "";
    var callback: ShareHandler;

    init(name: NSString, callback: ShareHandler) {
        self.name = name;
        self.callback = callback;
    }

    func share(url: NSURL, title: String?) {
        callback(url: url, title: title);
    }
}

func BookmarkCallback(url: NSURL, title: String?) {
    NSLog("Share bookmark");
    let request = NSMutableURLRequest(URL: NSURL(string: "https://moz-syncapi.sateh.com/1.0/bookmarks")!)
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
    
    // Login().getKeychainUser(login.getUsername())
    let credentials = Credentials(username: "sarentz+syncapi@mozilla.com", password: "q1w2e3r4")
    let userPasswordString = "\(credentials.username!):\(credentials.password!)"
    let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
    let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(nil)
    let authString = "Basic \(base64EncodedCredential)"
    
    let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.Client.ShareToFirefox")
    configuration.HTTPAdditionalHeaders = ["Authorization" : authString]
    configuration.sharedContainerIdentifier = SharedContainerIdentifier
    
    let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    let task = session.dataTaskWithRequest(request)
    task.resume()
}

func ReaderCallback(url: NSURL, title: String?) {
    NSLog("Share reader");
    // Not implemented
}

let ShareDestinations = [
    ShareDestination(name: NSLocalizedString("Bookmarks",    comment: ""), callback: BookmarkCallback),
    ShareDestination(name: NSLocalizedString("Reading List", comment: ""), callback: ReaderCallback)
]

class ShareDestinationPickerViewController: UITableViewController
{
    var completionHandler: ShareDestinationPickerCompletionHandler?
    var selectedItem: Int?
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ShareDestinations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel.text = ShareDestinations[indexPath.row].name
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
    
    override func didSelectPost() {
        let accountManager = AccountManager()
//      if login.isLoggedIn() {
        fetchSharedURL({ (url, title, error) -> Void in
            if url != nil {
                let dest : ShareDestination = ShareDestinations[self.selectedItem];
                dest.share(url, title: title);
                self.extensionContext!.completeRequestReturningItems([], completionHandler: nil);
            }
        })
//      }
    }
    
    override func configurationItems() -> [AnyObject]! {
        var item = SLComposeSheetConfigurationItem();
        item.title = "Send to";
        item.value = ShareDestinations[selectedItem].name;
        item.tapHandler = {
            let vc = ShareDestinationPickerViewController()
            vc.completionHandler = { (selectedItem:Int) -> Void in
                NSUserDefaults.standardUserDefaults().setInteger(selectedItem, forKey: LastSelectedShareDestinationDefault)
                self.selectedItem = selectedItem
                item.value = ShareDestinations[selectedItem].name;
                self.reloadConfigurationItems()
                self.popConfigurationViewController()
            }
            self.pushConfigurationViewController(vc)
        }
        return [item]
    }
    
    override func loadPreviewView() -> UIView! {
        return nil
    }
}
