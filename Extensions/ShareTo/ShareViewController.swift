/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

struct ShareDestination {
    let code: String
    let name: String
    let image: String
}

// TODO: See if we can do this with an Enum instead. Previous attempts failed because for example NSSet does not take (string) enum values.
let ShareDestinationBookmarks: NSString = "Bookmarks"
let ShareDestinationReadingList: NSString = "ReadingList"

let ShareDestinations = [
    ShareDestination(code: ShareDestinationBookmarks, name: NSLocalizedString("Add to Bookmarks",    comment: "On/off toggle to select adding this url to your bookmarks"), image: "bookmarkStar"),
    ShareDestination(code: ShareDestinationReadingList, name: NSLocalizedString("Add to Reading List", comment: "On/off toggle to select adding this url to your reading list"), image: "readingList")
]

protocol ShareControllerDelegate {
    func shareControllerDidCancel(shareController: ShareDialogController) -> Void
    func shareController(shareController: ShareDialogController, didShareItem item: ShareItem, toDestinations destinations: NSSet) -> Void
}

class ShareDialogController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var delegate: ShareControllerDelegate!
    var item: ShareItem!
    var initialShareDestinations: NSSet = NSSet(object: ShareDestinationBookmarks)
    
    var selectedShareDestinations: NSMutableSet = NSMutableSet()
    var navBar: UINavigationBar!
    var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedShareDestinations = NSMutableSet(set: initialShareDestinations)
        
        self.view.backgroundColor = UIColor.whiteColor()
        self.view.layer.cornerRadius = 8
        self.view.clipsToBounds = true
        
        // Setup the NavigationBar
        
        navBar = UINavigationBar()
        navBar.setTranslatesAutoresizingMaskIntoConstraints(false)
        navBar.barTintColor = UIColor.orangeColor()
        navBar.tintColor = UIColor.whiteColor()
        navBar.translucent = false
        self.view.addSubview(navBar)
        
        // Setup the NavigationItem
        
        navItem = UINavigationItem()
        navItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        navItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 17.0)!], forState: UIControlState.Normal)
        
        navItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.Done, target: self, action: "add")
        navItem.rightBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Medium", size: 17.0)!], forState: UIControlState.Normal)
        
        let size = 44.0 * 0.7
        let logo = UIImageView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        logo.image = UIImage(named: "flat-logo")
        logo.contentMode = UIViewContentMode.ScaleAspectFit
        navItem.titleView = logo
        
        navBar.pushNavigationItem(navItem, animated: false)
        
        // Setup the title view
        
        let titleView = UILabel()
        titleView.setTranslatesAutoresizingMaskIntoConstraints(false)
        titleView.numberOfLines = 3
        titleView.lineBreakMode = NSLineBreakMode.ByWordWrapping
        titleView.text = item.title
        titleView.font = UIFont(name: "HelveticaNeue-Medium", size: 12)
        view.addSubview(titleView)
        
        // Setup the link view
        
        let linkView = UILabel()
        linkView.setTranslatesAutoresizingMaskIntoConstraints(false)
        linkView.numberOfLines = 3
        linkView.lineBreakMode = NSLineBreakMode.ByWordWrapping
        linkView.text = item.url
        linkView.font = UIFont(name: "HelveticaNeue", size: 10)
        view.addSubview(linkView)
        
        // Setup the icon
        
        let iconView = UIImageView()
        iconView.setTranslatesAutoresizingMaskIntoConstraints(false)
        iconView.image = UIImage(named: "defaultFavicon")
        view.addSubview(iconView)
        
        // Setup the divider
        
        let dividerView = UIView()
        dividerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        dividerView.backgroundColor = UIColor.lightGrayColor()
        view.addSubview(dividerView)
        
        // Setup the table with destinations
        
        let tableView = UITableView()
        tableView.setTranslatesAutoresizingMaskIntoConstraints(false)
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.userInteractionEnabled = true
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.dataSource = self
        tableView.scrollEnabled = false
        view.addSubview(tableView)
        
        // Setup constraints
        
        let views = [
            "nav": navBar,
            "title": titleView,
            "link": linkView,
            "icon": iconView,
            "divider": dividerView,
            "table": tableView
        ]

        let leftPadding = 8
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[nav]|",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[nav]",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-\(leftPadding)-[title]-8-|",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[nav]-8-[title]",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-\(leftPadding)-[link]-8-|",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[title]-8-[link]",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[divider]|",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[divider(0.5)]",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[link]-8-[divider]",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[table]|",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[divider][table]",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[table(88)]|",
            options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
    }
    
    // UITabBarItem Actions that map to our delegate methods
    
    func cancel() {
        delegate?.shareControllerDidCancel(self)
    }
    
    func add() {
        delegate?.shareController(self, didShareItem: item, toDestinations: NSSet(set: selectedShareDestinations))
    }
    
    // UITableView Delegate and DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ShareDestinations.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGrayColor() : UIColor(red:0.733, green:0.729, blue:0.757, alpha:1.000)
        cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 17)
        cell.imageView?.transform = CGAffineTransformMakeScale(0.5, 0.5)
        cell.accessoryType = selectedShareDestinations.containsObject(ShareDestinations[indexPath.row].code) ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        cell.tintColor = UIColor(red:0.427, green:0.800, blue:0.102, alpha:1.0)
        cell.layoutMargins = UIEdgeInsetsZero
        cell.textLabel?.text = ShareDestinations[indexPath.row].name
        cell.imageView?.image = UIImage(named: ShareDestinations[indexPath.row].image)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        let code = ShareDestinations[indexPath.row].code
        if selectedShareDestinations.containsObject(code) {
            selectedShareDestinations.removeObject(code)
        } else {
            selectedShareDestinations.addObject(code)
        }
        tableView.reloadData()
        
        navItem.rightBarButtonItem?.enabled = (selectedShareDestinations.count != 0)
    }
}
