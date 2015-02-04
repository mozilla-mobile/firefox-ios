/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

let LastUsedShareDestinationsKey = "LastUsedShareDestinations"

@objc(InitialViewController)
class InitialViewController: UIViewController, ShareControllerDelegate
{
    var shareDialogController: ShareDialogController!
    var profile: Profile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(white: 0.75, alpha: 0.65) // TODO: Is the correct color documented somewhere?
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        ExtensionUtils.extractSharedItemFromExtensionContext(self.extensionContext, completionHandler: { (item, error) -> Void in
            if error == nil && item != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.presentShareDialog(item!)
                }
            } else {
                self.extensionContext!.completeRequestReturningItems([], completionHandler: nil);
            }
        })
    }
    
    //
    
    func shareControllerDidCancel(shareController: ShareDialogController)
    {
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.shareDialogController.view.alpha = 0.0
        }, completion: { (Bool) -> Void in
            self.dismissShareDialog()
            self.extensionContext!.completeRequestReturningItems([], completionHandler: nil);
        })
    }

    func shareController(shareController: ShareDialogController, didShareItem item: ShareItem, toDestinations destinations: NSSet)
    {
        setLastUsedShareDestinations(destinations)
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.shareDialogController.view.alpha = 0.0
        }, completion: { (Bool) -> Void in
            self.dismissShareDialog()
            
            if destinations.containsObject(ShareDestinationReadingList) {
                self.shareToReadingList(item)
            }
            
            if destinations.containsObject(ShareDestinationBookmarks) {
                self.shareToBookmarks(item)
            }

            self.extensionContext!.completeRequestReturningItems([], completionHandler: nil);
        })
    }
    
    //
    
    func getLastUsedShareDestinations() -> NSSet {
        if let destinations = NSUserDefaults.standardUserDefaults().objectForKey(LastUsedShareDestinationsKey) as? NSArray {
            return NSSet(array: destinations)
        }
        return NSSet(object: ShareDestinationBookmarks)
    }
    
    func setLastUsedShareDestinations(destinations: NSSet) {
        NSUserDefaults.standardUserDefaults().setObject(destinations.allObjects, forKey: LastUsedShareDestinationsKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func presentShareDialog(item: ShareItem) {
        shareDialogController = ShareDialogController()
        shareDialogController.delegate = self
        shareDialogController.item = item
        shareDialogController.initialShareDestinations = getLastUsedShareDestinations()
        
        self.addChildViewController(shareDialogController)
        shareDialogController.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(shareDialogController.view)
        
        // Setup constraints for the dialog. We keep the dialog centered with 16 points of padding on both
        // sides. The dialog grows to max 380 points wide so that it does not look too big on landscape or
        // iPad devices.
        
        let views: NSDictionary = ["dialog": shareDialogController.view]
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(16@751)-[dialog(<=380@1000)]-(16@751)-|",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        
        let cx = NSLayoutConstraint(item: shareDialogController.view, attribute: NSLayoutAttribute.CenterX,
            relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
        cx.priority = 1000 // TODO: Why does UILayoutPriorityRequired give a linker error? SDK Bug?
        view.addConstraint(cx)
        
        view.addConstraint(NSLayoutConstraint(item: shareDialogController.view, attribute: NSLayoutAttribute.CenterY,
            relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0))
        
        // Fade the dialog in
        
        shareDialogController.view.alpha = 0.0
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.shareDialogController.view.alpha = 1.0
        }, completion: nil)
    }
    
    func dismissShareDialog() {
        shareDialogController.willMoveToParentViewController(nil)
        shareDialogController.view.removeFromSuperview()
        shareDialogController.removeFromParentViewController()
    }
    
    //
    
    func shareToReadingList(item: ShareItem) {
        // TODO: Discuss how to share to the (local) reading list
    }
    
    func shareToBookmarks(item: ShareItem) {
        if profile != nil { // TODO: We need to properly deal with this.
            profile!.bookmarks.shareItem(item)
        }
    }
}
