/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let maxNumberOfItemsPerPage = 6

protocol MenuViewControllerDelegate: class {
    func menuViewControllerDidDismiss(menuViewController: MenuViewController)
    func shouldCloseMenu(menuViewController: MenuViewController, forTraitCollection traitCollection: UITraitCollection) -> Bool
}

enum MenuViewPresentationStyle {
    case Popover
    case Modal
}

class MenuViewController: UIViewController {

    var menuConfig: MenuConfiguration
    var presentationStyle: MenuViewPresentationStyle
    weak var delegate: MenuViewControllerDelegate?
    weak var actionDelegate: MenuActionDelegate?

    var menuTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            self.transitioningDelegate = menuTransitionDelegate
        }
    }

    var menuView: MenuView!

    var appState: AppState {
        didSet {
            menuConfig = menuConfig.menuForState(appState)
            self.reloadView()
        }
    }

    private let popoverBackgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)

    init(withAppState appState: AppState, presentationStyle: MenuViewPresentationStyle) {
        self.appState = appState
        menuConfig = AppMenuConfiguration(appState: appState)
        self.presentationStyle = presentationStyle

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = popoverBackgroundColor.colorWithAlphaComponent(0.0)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tapToDismissMenu(_:)))
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

        menuView.toolbar.backgroundColor = menuConfig.toolbarColor()
        menuView.toolbar.tintColor = menuConfig.toolbarTintColor()
        menuView.toolbar.layer.shadowColor = menuConfig.shadowColor().CGColor
        menuView.toolbar.layer.shadowOpacity = 0.4
        menuView.toolbar.layer.shadowRadius = 0

        menuView.menuColor = menuConfig.menuBackgroundColor()
        menuView.tintColor = menuConfig.menuTintColor()

        switch presentationStyle {
        case .Popover:
            menuView.toolbar.clipsToBounds = false
            // add a shadow to the tp[ of the toolbar
            menuView.toolbar.layer.shadowOffset = CGSize(width: 0, height: -2)
            menuView.snp_makeConstraints { make in
                make.top.left.right.equalTo(view)
            }
        case .Modal:
            menuView.toolbar.cornerRadius = CGSizeMake(5.0,5.0)
            menuView.toolbar.cornersToRound = [.TopLeft, .TopRight]
            menuView.toolbar.clipsToBounds = false
            // add a shadow to the bottom of the toolbar
            menuView.toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)

            menuView.openMenuImage.image = menuConfig.menuIcon()?.imageWithRenderingMode(.AlwaysTemplate)
            menuView.openMenuImage.tintColor = menuConfig.toolbarTintColor()
            menuView.openMenuImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapToDismissMenu(_:))))

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

    @objc private func tapToDismissMenu(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            dismissMenu()
        }
    }

    private func dismissMenu() {
        view.backgroundColor = UIColor.clearColor()
        self.dismissViewControllerAnimated(true, completion: {
            self.view.backgroundColor = self.popoverBackgroundColor
            self.delegate?.menuViewControllerDidDismiss(self)
        })
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        if delegate?.shouldCloseMenu(self, forTraitCollection: self.traitCollection) ?? false {
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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.view.backgroundColor = popoverBackgroundColor
    }

    private func reloadView() {
        menuView.setNeedsReload()
    }

    private func performMenuAction(action: MenuAction) {
        // this is so that things can happen while the menu is dismissing, but not before the menu is dismissed
        // waiting for the menu to dismiss felt too long (menu dismissed, then thing happened)
        // whereas this way things happen as the menu is dismissing, but the menu is already dismissed
        // to performing actions that do things like open other modal views can still occur and they feel snappy
        dispatch_async(dispatch_get_main_queue()) {
            self.actionDelegate?.performMenuAction(action, withAppState: self.appState)
        }
        dismissMenu()
    }

    private func performMenuAction(action: MenuAction, withAnimation animation: Animatable, onView view: UIView) {
        animation.animateFromView(view, offset: nil) { finished in
            self.performMenuAction(action)
        }
    }

}
extension MenuViewController: MenuItemDelegate {
    func menuView(menu: MenuView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let menuItem = menuConfig.menuItems[indexPath.getMenuItemIndex()]
        let menuItemCell = self.menuView(menuView, menuItemCellForIndexPath: indexPath)

        if let icon = menuItem.selectedIconForState(appState) {
            menuItemCell.menuImageView.image = icon
        } else {
            menuItemCell.menuImageView.image = menuItemCell.menuImageView.image?.imageWithRenderingMode(.AlwaysTemplate)
            menuItemCell.menuImageView.tintColor = menuConfig.selectedItemTintColor()
        }

        guard let animation = menuItem.animation else {
            return performMenuAction(menuItem.action)
        }
        performMenuAction(menuItem.action, withAnimation: animation, onView: menuItemCell.menuImageView)
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
        assert(indexPath.getMenuItemIndex() < menuConfig.menuItems.count, "The menu item index \(indexPath.getMenuItemIndex()) should always be less than the number of menu items \(menuConfig.menuItems.count)")
        let menuItem = menuConfig.menuItems[indexPath.getMenuItemIndex()]
        cell.menuTitleLabel.text = menuItem.title
        cell.accessibilityLabel = menuItem.title
        cell.menuTitleLabel.font = menuConfig.menuFont()
        cell.menuTitleLabel.textColor = menuConfig.menuTintColor()
        if let icon = menuItem.iconForState(appState) {
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

    func menuView(menuView: MenuView, buttonForItemAtIndex index: Int) -> UIView {
        // this should never happen - if we don't have any toolbar items then we shouldn't get this far
        guard let menuToolbarItems = menuConfig.menuToolbarItems else {
            return UIView()
        }
        let item = menuToolbarItems[index]
        let buttonImageView = UIImageView(image: item.iconForState(appState)?.imageWithRenderingMode(.AlwaysTemplate))
        buttonImageView.contentMode = .ScaleAspectFit
        buttonImageView.accessibilityLabel = item.title
        return buttonImageView
    }
}

extension MenuViewController: MenuToolbarItemDelegate {
    func menuView(menuView: MenuView, didSelectItemAtIndex index: Int) {
        let menuToolbarItem = menuConfig.menuToolbarItems![index]
        return performMenuAction(menuToolbarItem.action)
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
        return (section * maxNumberOfItemsPerPage) + item
    }
}
