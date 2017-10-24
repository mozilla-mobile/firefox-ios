/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

struct ShareDestination {
    let code: String
    let name: String
    let image: String
}

// TODO: See if we can do this with an Enum instead. Previous attempts failed because for example NSSet does not take (string) enum values.
let ShareDestinationBookmarks: String = "Bookmarks"
let ShareDestinationReadingList: String = "ReadingList"

let ShareDestinations = [
    ShareDestination(code: ShareDestinationReadingList, name: NSLocalizedString("Add to Reading List", tableName: "ShareTo", comment: "On/off toggle to select adding this url to your reading list"), image: "AddToReadingList"),
    ShareDestination(code: ShareDestinationBookmarks, name: NSLocalizedString("Add to Bookmarks", tableName: "ShareTo", comment: "On/off toggle to select adding this url to your bookmarks"), image: "AddToBookmarks")
]

protocol ShareControllerDelegate {
    func shareControllerDidCancel(_ shareController: ShareDialogController)
    func shareController(_ shareController: ShareDialogController, didShareItem item: ShareItem, toDestinations destinations: NSSet)
}

private struct ShareDialogControllerUX {
    static let CornerRadius: CGFloat = 4                                                            // Corner radius of the dialog

    static let NavigationBarTintColor = UIColor(rgb: 0xf37c00)                                      // Tint color changes the text color in the navigation bar
    static let NavigationBarCancelButtonFont = UIFont.systemFont(ofSize: UIFont.buttonFontSize)     // System default
    static let NavigationBarAddButtonFont = UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize)    // System default
    static let NavigationBarIconSize = 40                                                           // Width and height of the icon
    static let NavigationBarBottomPadding = 12

    static let ItemTitleFontMedium = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
    static let ItemTitleFont = UIFont.systemFont(ofSize: 15)
    static let ItemTitleMaxNumberOfLines = 2
    static let ItemTitleLeftPadding = 44
    static let ItemTitleRightPadding = 44
    static let ItemTitleBottomPadding = 12

    static let ItemLinkFont = UIFont.systemFont(ofSize: 12)
    static let ItemLinkMaxNumberOfLines = 3
    static let ItemLinkLeftPadding = 44
    static let ItemLinkRightPadding = 44
    static let ItemLinkBottomPadding = 14

    static let DividerColor = UIColor.lightGray                                              // Divider between the item and the table with destinations
    static let DividerHeight = 0.5

    static let TableRowHeight: CGFloat = 44                                                         // System default
    static let TableRowFont = UIFont.systemFont(ofSize: 14)
    static let TableRowFontMinScale: CGFloat = 0.8
    static let TableRowTintColor = UIColor(red: 0.427, green: 0.800, blue: 0.102, alpha: 1.0)           // Green tint for the checkmark
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

        self.view.backgroundColor = UIColor.white
        self.view.layer.cornerRadius = ShareDialogControllerUX.CornerRadius
        self.view.clipsToBounds = true

        // Setup the NavigationBar

        navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.tintColor = ShareDialogControllerUX.NavigationBarTintColor
        navBar.isTranslucent = false
        self.view.addSubview(navBar)

        // Setup the NavigationItem

        navItem = UINavigationItem()
        navItem.leftBarButtonItem = UIBarButtonItem(
            title: Strings.ShareToCancelButton,
            style: .plain,
            target: self,
            action: #selector(ShareDialogController.cancel)
        )
        navItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: ShareDialogControllerUX.NavigationBarCancelButtonFont], for: UIControlState())
        navItem.leftBarButtonItem?.accessibilityIdentifier = "ShareDialogController.navigationItem.leftBarButtonItem"

        navItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Add", tableName: "ShareTo", comment: "Add button in the share dialog"), style: UIBarButtonItemStyle.done, target: self, action: #selector(ShareDialogController.add))
        navItem.rightBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: ShareDialogControllerUX.NavigationBarAddButtonFont], for: UIControlState())

        let logo = UIImageView(image: UIImage(named: "Icon-Small"))
        logo.contentMode = UIViewContentMode.scaleAspectFit // TODO Can go away if icon is provided in correct size
        navItem.titleView = logo

        navBar.pushItem(navItem, animated: false)

        // Setup the title view

        let titleView = UILabel()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.numberOfLines = ShareDialogControllerUX.ItemTitleMaxNumberOfLines
        titleView.lineBreakMode = NSLineBreakMode.byTruncatingTail
        titleView.text = item.title
        titleView.font = ShareDialogControllerUX.ItemTitleFontMedium
        view.addSubview(titleView)

        // Setup the link view

        let linkView = UILabel()
        linkView.translatesAutoresizingMaskIntoConstraints = false
        linkView.numberOfLines = ShareDialogControllerUX.ItemLinkMaxNumberOfLines
        linkView.lineBreakMode = NSLineBreakMode.byTruncatingTail
        linkView.text = item.url
        linkView.font = ShareDialogControllerUX.ItemLinkFont
        view.addSubview(linkView)

        // Setup the icon

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(named: "defaultFavicon")
        view.addSubview(iconView)

        // Setup the divider

        let dividerView = UIView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = ShareDialogControllerUX.DividerColor
        view.addSubview(dividerView)

        // Setup the table with destinations

        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.isUserInteractionEnabled = true
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.dataSource = self
        tableView.isScrollEnabled = false
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
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: constraint, options: NSLayoutFormatOptions(), metrics: nil, views: views))
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ShareDestinations.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ShareDialogControllerUX.TableRowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGray : ShareDialogControllerUX.TableRowTextColor
        cell.textLabel?.font = ShareDialogControllerUX.TableRowFont
        cell.accessoryType = selectedShareDestinations.contains(ShareDestinations[indexPath.row].code) ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        cell.tintColor = ShareDialogControllerUX.TableRowTintColor
        cell.layoutMargins = UIEdgeInsets.zero
        cell.textLabel?.text = ShareDestinations[indexPath.row].name
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = ShareDialogControllerUX.TableRowFontMinScale
        cell.imageView?.image = UIImage(named: ShareDestinations[indexPath.row].image)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let code = ShareDestinations[indexPath.row].code
        if selectedShareDestinations.contains(code) {
            selectedShareDestinations.remove(code)
        } else {
            selectedShareDestinations.add(code)
        }
        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        
        navItem.rightBarButtonItem?.isEnabled = (selectedShareDestinations.count != 0)
    }
}
