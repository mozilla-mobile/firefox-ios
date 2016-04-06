/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let maxNumberOfItemsPerPage = 6

enum MenuViewPresentationStyle {
    case Popover
    case Modal
}

class MenuViewController: UIViewController {

    var menuConfig: MenuConfiguration
    var presentationStyle: MenuViewPresentationStyle

    var menuView: MenuView!

    private let isPrivate = false

    private let popoverBackgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)

    init(withMenuConfig config: MenuConfiguration, presentationStyle: MenuViewPresentationStyle) {
        self.menuConfig = config
        self.presentationStyle = presentationStyle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissMenu(_:)))
        gesture.delegate = self
        gesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(gesture)

        // Do any additional setup after loading the view.
        menuView = MenuView(presentationStyle: self.presentationStyle)
        self.view.addSubview(menuView)

        menuView.menuItemDataSource = self
        menuView.menuItemDelegate = self
        menuView.toolbarDelegate = self
        menuView.toolbarDataSource = self

        menuView.toolbar.backgroundColor = menuConfig.toolbarColourForMode(isPrivate: isPrivate)
        menuView.toolbar.tintColor = menuConfig.toolbarTintColorForMode(isPrivate: isPrivate)
        menuView.toolbar.layer.shadowColor = isPrivate ? UIColor.darkGrayColor().CGColor : UIColor.lightGrayColor().CGColor
        menuView.toolbar.layer.shadowOpacity = 0.4
        menuView.toolbar.layer.shadowRadius = 0

        menuView.backgroundColor = menuConfig.menuBackgroundColorForMode(isPrivate: isPrivate)
        menuView.tintColor = menuConfig.menuTintColorForMode(isPrivate: isPrivate)

        switch presentationStyle {
        case .Popover:
            self.view.backgroundColor = UIColor.clearColor()
            menuView.toolbar.clipsToBounds = false
            // add a shadow to the tp[ of the toolbar
            menuView.toolbar.layer.shadowOffset = CGSize(width: 0, height: -2)
            menuView.snp_makeConstraints { make in
                make.top.left.right.equalTo(view)
            }
        case .Modal:
            self.view.backgroundColor = popoverBackgroundColor
            menuView.toolbar.cornerRadius = CGSizeMake(5.0,5.0)
            menuView.toolbar.cornersToRound = [.TopLeft, .TopRight]
            menuView.toolbar.clipsToBounds = false
            // add a shadow to the bottom of the toolbar
            menuView.toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)

            menuView.openMenuImage.image = MenuConfiguration.menuIconForMode(isPrivate: isPrivate)
            menuView.openMenuImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissMenu(_:))))

            menuView.snp_makeConstraints { make in
                make.left.equalTo(view.snp_left).offset(24)
                make.right.equalTo(view.snp_right).offset(-24)
                make.bottom.equalTo(view.snp_bottom)
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func dismissMenu(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            view.backgroundColor = UIColor.clearColor()
            self.dismissViewControllerAnimated(true, completion: {
                self.view.backgroundColor = self.popoverBackgroundColor
            })
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        if UI_USER_INTERFACE_IDIOM() == .Phone &&
            (self.traitCollection.horizontalSizeClass == .Compact && traitCollection.verticalSizeClass == .Regular) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if presentationStyle == .Popover {
            self.preferredContentSize = CGSizeMake(view.bounds.size.width, menuView.bounds.size.height)
        }
        self.popoverPresentationController?.backgroundColor = self.popoverBackgroundColor
    }

}
extension MenuViewController: MenuItemDelegate {
    func menuView(menu: MenuView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let selectedMenuItem = menuConfig.menuItems[indexPath.getMenuItemIndex()]
        print("Selected menu item '\(selectedMenuItem.title)")
    }
}

extension MenuViewController: MenuItemDataSource {
    func numberOfPagesInMenuView(menuView: MenuView) -> Int {
        let menuItems = menuConfig.menuItems
        return Int(ceil(Double(menuItems.count) / Double(maxNumberOfItemsPerPage)))
    }

    func numberOfItemsPerRowInMenuView(menuView: MenuView) -> Int {
        return menuConfig.numberOfItemsInRow
    }

    func menuView(menuView: MenuView, numberOfItemsForPage page: Int) -> Int {
        let menuItems = menuConfig.menuItems
        let pageStartIndex = page * maxNumberOfItemsPerPage
        if (pageStartIndex + maxNumberOfItemsPerPage) > menuItems.count {
            return menuItems.count - pageStartIndex
        }
        return maxNumberOfItemsPerPage
    }

    func menuView(menuView: MenuView, menuItemCellForIndexPath indexPath: NSIndexPath) -> MenuItemCollectionViewCell {
        let cell = menuView.dequeueReusableCellForIndexPath(indexPath)
        let menuItem = menuConfig.menuItems[indexPath.getMenuItemIndex()]
        cell.menuTitleLabel.text = menuItem.title
        cell.accessibilityLabel = menuItem.title
        cell.menuTitleLabel.font = menuConfig.menuFont()
        cell.menuTitleLabel.textColor = menuConfig.menuTintColorForMode(isPrivate: isPrivate)
        if let icon = menuItem.iconForMode(isPrivate: isPrivate) {
            cell.menuImageView.image = icon
        }
        return cell
    }

    @objc private func didReceiveLongPress(recognizer: UILongPressGestureRecognizer) {
    }
}

extension MenuViewController: MenuToolbarDataSource {
    func numberOfToolbarItemsInMenuView(menuView: MenuView) -> Int {
        guard let menuToolbarItems = menuConfig.menuToolbarItems else { return 0 }
        return menuToolbarItems.count
    }

    func menuView(menuView: MenuView, buttonForItemAtIndex index: Int) -> UIBarButtonItem {
        // this should never happen - if we don't have any toolbar items then we shouldn't get this far
        guard let menuToolbarItems = menuConfig.menuToolbarItems else {
            return UIBarButtonItem(title: nil, style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        }
        let item = menuToolbarItems[index]
        let toolbarItemView = UIBarButtonItem(image: item.icon, style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        toolbarItemView.accessibilityLabel = item.title
        return toolbarItemView
    }
}

extension MenuViewController: MenuToolbarItemDelegate {
    func menuView(menuView: MenuView, didSelectItemAtIndex index: Int) {
        let selectedMenuItem = menuConfig.menuToolbarItems![index]
        print("Selected menu item '\(selectedMenuItem.title)")
    }
}

extension MenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        let gestureView = gestureRecognizer.view
        let loc = touch.locationInView(gestureView)
        guard let tappedView = gestureView?.hitTest(loc, withEvent: nil) where tappedView == view || tappedView == menuView.openMenuImage else {
            return false
        }

        return true
    }
}

private extension NSIndexPath {
    func getMenuItemIndex() -> Int {
        return (section * maxNumberOfItemsPerPage) + row
    }
}
