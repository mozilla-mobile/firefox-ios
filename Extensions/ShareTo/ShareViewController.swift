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
    ShareDestination(code: ShareDestinationReadingList, name: NSLocalizedString("Add to Reading List", comment: "On/off toggle to select adding this url to your reading list"), image: "AddToReadingList"),
    ShareDestination(code: ShareDestinationBookmarks, name: NSLocalizedString("Add to Bookmarks",    comment: "On/off toggle to select adding this url to your bookmarks"), image: "AddToBookmarks")
]

protocol ShareControllerDelegate {
    func shareControllerDidCancel(shareController: ShareDialogController) -> Void
    func shareController(shareController: ShareDialogController, didShareItem item: ShareItem, toDestinations destinations: NSSet) -> Void
}

private struct ShareDialogControllerUX {
    static let CornerRadius: CGFloat = 4                                                            // Corner radius of the dialog

    static let NavigationBarTintColor = UIColor(rgb: 0xf37c00)                                      // Tint color changes the text color in the navigation bar
    static let NavigationBarCancelButtonFont = UIFont.systemFontOfSize(UIFont.buttonFontSize())     // System default
    static let NavigationBarAddButtonFont = UIFont.boldSystemFontOfSize(UIFont.buttonFontSize())    // System default
    static let NavigationBarIconSize = 38                                                           // Width and height of the icon
    static let NavigationBarBottomPadding = 12

    static let ItemTitleFont = UIFont.systemFontOfSize(15, weight: UIFontWeightMedium)
    static let ItemTitleMaxNumberOfLines = 2
    static let ItemTitleLeftPadding = 44
    static let ItemTitleRightPadding = 44
    static let ItemTitleBottomPadding = 12

    static let ItemLinkFont = UIFont.systemFontOfSize(12)
    static let ItemLinkMaxNumberOfLines = 3
    static let ItemLinkLeftPadding = 44
    static let ItemLinkRightPadding = 44
    static let ItemLinkBottomPadding = 14

    static let DividerColor = UIColor.lightGrayColor()                                              // Divider between the item and the table with destinations
    static let DividerHeight = 0.5

    static let TableRowHeight: CGFloat = 44                                                         // System default
    static let TableRowFont = UIFont.systemFontOfSize(UIFont.labelFontSize())
    static let TableRowTintColor = UIColor(red:0.427, green:0.800, blue:0.102, alpha:1.0)           // Green tint for the checkmark
    static let TableRowTextColor = UIColor(rgb: 0x555555)

    static let TableHeight = 88                                                                     // Height of 2 standard 44px cells
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
        self.view.layer.cornerRadius = ShareDialogControllerUX.CornerRadius
        self.view.clipsToBounds = true

        // Setup the NavigationBar

        navBar = UINavigationBar()
        navBar.setTranslatesAutoresizingMaskIntoConstraints(false)
        navBar.tintColor = ShareDialogControllerUX.NavigationBarTintColor
        navBar.translucent = false
        self.view.addSubview(navBar)

        // Setup the NavigationItem

        navItem = UINavigationItem()
        navItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        navItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: ShareDialogControllerUX.NavigationBarCancelButtonFont], forState: UIControlState.Normal)

        navItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Add", comment: "Add button in the share dialog"), style: UIBarButtonItemStyle.Done, target: self, action: "add")
        navItem.rightBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: ShareDialogControllerUX.NavigationBarAddButtonFont], forState: UIControlState.Normal)

        let logo = UIImageView(frame: CGRect(x: 0, y: 0, width: ShareDialogControllerUX.NavigationBarIconSize, height: ShareDialogControllerUX.NavigationBarIconSize))
        logo.image = UIImage(named: "Icon-Small")
        logo.contentMode = UIViewContentMode.ScaleAspectFit // TODO Can go away if icon is provided in correct size
        navItem.titleView = logo

        navBar.pushNavigationItem(navItem, animated: false)

        // Setup the title view

        let titleView = UILabel()
        titleView.setTranslatesAutoresizingMaskIntoConstraints(false)
        titleView.numberOfLines = ShareDialogControllerUX.ItemTitleMaxNumberOfLines
        titleView.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        titleView.text = item.title
        titleView.font = ShareDialogControllerUX.ItemTitleFont
        view.addSubview(titleView)

        // Setup the link view

        let linkView = UILabel()
        linkView.setTranslatesAutoresizingMaskIntoConstraints(false)
        linkView.numberOfLines = ShareDialogControllerUX.ItemLinkMaxNumberOfLines
        linkView.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        linkView.text = item.url
        linkView.font = ShareDialogControllerUX.ItemLinkFont
        view.addSubview(linkView)

        // Setup the icon

        let iconView = UIImageView()
        iconView.setTranslatesAutoresizingMaskIntoConstraints(false)
        iconView.image = UIImage(named: "defaultFavicon")
        view.addSubview(iconView)

        // Setup the divider

        let dividerView = UIView()
        dividerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        dividerView.backgroundColor = ShareDialogControllerUX.DividerColor
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

        // TODO See Bug 1102516 - Use Snappy to define share extension layout constraints

        let constraints = [
            "H:|[nav]|",
            "V:|[nav]",

            "H:|-\(ShareDialogControllerUX.ItemTitleLeftPadding)-[title]-\(ShareDialogControllerUX.ItemTitleRightPadding)-|",
            "V:[nav]-\(ShareDialogControllerUX.NavigationBarBottomPadding)-[title]",

            "H:|-\(ShareDialogControllerUX.ItemLinkLeftPadding)-[link]-\(ShareDialogControllerUX.ItemLinkLeftPadding)-|",
            "V:[title]-\(ShareDialogControllerUX.ItemTitleBottomPadding)-[link]",

            "H:|[divider]|",
            "V:[divider(\(ShareDialogControllerUX.DividerHeight))]",
            "V:[link]-\(ShareDialogControllerUX.ItemLinkBottomPadding)-[divider]",

            "H:|[table]|",
            "V:[divider][table]",
            "V:[table(\(ShareDialogControllerUX.TableHeight))]|"
        ]

        for constraint in constraints {
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(constraint, options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        }
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
        return ShareDialogControllerUX.TableRowHeight
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGrayColor() : ShareDialogControllerUX.TableRowTextColor
        cell.textLabel?.font = ShareDialogControllerUX.TableRowFont
        cell.accessoryType = selectedShareDestinations.containsObject(ShareDestinations[indexPath.row].code) ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        cell.tintColor = ShareDialogControllerUX.TableRowTintColor
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
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        
        navItem.rightBarButtonItem?.enabled = (selectedShareDestinations.count != 0)
    }
}
