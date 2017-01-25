/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let maxNumberOfItemsPerPage = 6

protocol MenuViewControllerDelegate: class {
    func menuViewControllerDidDismiss(_ menuViewController: MenuViewController)
    func shouldCloseMenu(_ menuViewController: MenuViewController, forRotationToNewSize size: CGSize, forTraitCollection traitCollection: UITraitCollection) -> Bool
}

enum MenuViewPresentationStyle {
    case popover
    case modal
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

    lazy var menuView: MenuView = MenuView(presentationStyle: self.presentationStyle)

    var appState: AppState {
        didSet {
            if !self.isBeingDismissed {
                menuConfig = menuConfig.menuForState(appState)
                self.reloadView()
            }
        }
    }

    var fixedWidth: CGFloat? {
        didSet {
            defer {
                menuView.setNeedsUpdateConstraints()
            }

            guard let fixedWidth = fixedWidth else {
                self.setupDefaultModalMenuConstraints()
                return
            }

            menuView.snp.remakeConstraints { make in
                make.centerX.equalTo(view)
                make.width.equalTo(fixedWidth).priority(50)
                make.bottom.equalTo(view)
            }
        }
    }

    fileprivate let popoverBackgroundColor = UIColor.black.withAlphaComponent(0.4)

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
        self.view.backgroundColor = popoverBackgroundColor.withAlphaComponent(0.0)
        popoverPresentationController?.backgroundColor = menuConfig.menuBackgroundColor()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tapToDismissMenu(_:)))
        gesture.delegate = self
        gesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(gesture)

        // Do any additional setup after loading the view.
        self.view.addSubview(menuView)

        menuView.menuItemDataSource = self
        menuView.menuItemDelegate = self
        menuView.toolbarDelegate = self
        menuView.toolbarDataSource = self

        menuView.toolbarColor = menuConfig.toolbarColor()
        menuView.toolbar.tintColor = menuConfig.toolbarTintColor()
        menuView.toolbar.layer.shadowColor = menuConfig.shadowColor().cgColor
        menuView.toolbar.layer.shadowOpacity = 0.4
        menuView.toolbar.layer.shadowRadius = 0

        menuView.menuColor = menuConfig.menuBackgroundColor()
        menuView.tintColor = menuConfig.menuTintColor()

        menuView.accessibilityIdentifier = "MenuViewController.menuView"

        switch presentationStyle {
        case .popover:
            menuView.toolbar.clipsToBounds = false
            // add a shadow to the tp[ of the toolbar
            menuView.toolbar.layer.shadowOffset = CGSize(width: 0, height: -2)
            menuView.snp.makeConstraints { make in
                make.top.left.right.equalTo(view)
            }
        case .modal:
            menuView.cornerRadius = CGSize(width: 5.0, height: 5.0)
            menuView.cornersToRound = [.topLeft, .topRight]
            menuView.toolbar.clipsToBounds = false
            // add a shadow to the bottom of the toolbar
            menuView.toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)

            menuView.openMenuImage.image = menuConfig.menuIcon()?.withRenderingMode(.alwaysTemplate)
            menuView.openMenuImage.tintColor = menuConfig.toolbarTintColor()
            menuView.openMenuImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapToDismissMenu(_:))))
            setupDefaultModalMenuConstraints()
        }
    }

    fileprivate func setupDefaultModalMenuConstraints() {
        menuView.snp.remakeConstraints { make in
            make.left.equalTo(view.snp.left).offset(24).priority(25)
            make.right.equalTo(view.snp.right).offset(-24).priority(25)
            make.bottom.equalTo(view.snp.bottom)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc fileprivate func tapToDismissMenu(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.ended {
            dismissMenu()
        }
    }

    fileprivate func dismissMenu() {
        view.backgroundColor = UIColor.clear
        self.dismiss(animated: true, completion: {
            self.view.backgroundColor = self.popoverBackgroundColor
            self.delegate?.menuViewControllerDidDismiss(self)
        })
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if delegate?.shouldCloseMenu(self, forRotationToNewSize: size, forTraitCollection: self.traitCollection) ?? false {
            self.dismiss(animated: false, completion: {
                self.delegate?.menuViewControllerDidDismiss(self)
            })
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if presentationStyle == .popover {
            self.preferredContentSize = CGSize(width: view.bounds.size.width, height: menuView.bounds.size.height)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.backgroundColor = popoverBackgroundColor

        if presentationStyle == .popover {
            self.preferredContentSize = CGSize(width: view.bounds.size.width, height: menuView.bounds.size.height)
        }
    }

    fileprivate func reloadView() {
        menuView.setNeedsReload()
    }

    fileprivate func performMenuAction(_ action: MenuAction) {
        // this is so that things can happen while the menu is dismissing, but not before the menu is dismissed
        // waiting for the menu to dismiss felt too long (menu dismissed, then thing happened)
        // whereas this way things happen as the menu is dismissing, but the menu is already dismissed
        // to performing actions that do things like open other modal views can still occur and they feel snappy
        DispatchQueue.main.async {
            self.actionDelegate?.performMenuAction(action, withAppState: self.appState)
        }
        dismissMenu()
    }

    fileprivate func performMenuAction(_ action: MenuAction, withAnimation animation: Animatable, onView view: UIView) {
        animation.animateFromView(view, offset: nil) { finished in
            self.performMenuAction(action)
        }
    }

}
extension MenuViewController: MenuItemDelegate {
    func menuView(_ menu: MenuView, didSelectItemAtIndexPath indexPath: IndexPath) {
        return self.menuView(menu, didPerformActionAtIndexPath: indexPath, animatedIfPossible: true) { $0.action }
    }

    func menuView(_ menuView: MenuView, didLongPressItemAtIndexPath indexPath: IndexPath) {
        return self.menuView(menuView, didPerformActionAtIndexPath: indexPath, animatedIfPossible: false) { $0.secondaryAction }
    }

    fileprivate func menuView(_ menu: MenuView, didPerformActionAtIndexPath indexPath: IndexPath, animatedIfPossible: Bool, withActionResolver actionFinder: (MenuItem) -> MenuAction?) {
        let menuItem = menuConfig.menuItems[indexPath.getMenuItemIndex()]
        guard let action = actionFinder(menuItem) else {
            return
        }
        let menuItemCell = self.menuView(menuView, menuItemCellForIndexPath: indexPath)

        if let icon = menuItem.selectedIconForState(appState) {
            menuItemCell.menuImageView.image = icon
        } else {
            menuItemCell.menuImageView.image = menuItemCell.menuImageView.image?.withRenderingMode(.alwaysTemplate)
            menuItemCell.menuImageView.tintColor = menuConfig.selectedItemTintColor()
        }

        guard let animation = menuItem.animation, animatedIfPossible else {
            return performMenuAction(action)
        }
        performMenuAction(action, withAnimation: animation, onView: menuItemCell.menuImageView)
    }
    
    func menuView(_ menuView: MenuView, shouldSelectItemAtIndexPath indexPath: IndexPath) -> Bool {
        let menuItem = menuConfig.menuItems[indexPath.getMenuItemIndex()]
        return !menuItem.isDisabled
    }

    func heightForRowsInMenuView(_ menuView: MenuView) -> CGFloat {
        // loop through the labels for the menu items and calculate the largest
        var largestLabel: CGFloat = 0
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.systemLayoutSizeFitting(UILayoutFittingCompressedSize).width, height: 0))
        label.font = menuConfig.menuFont()
        for item in menuConfig.menuItems {
            label.text = item.title
            let labelHeight = getLabelHeight(label)
            largestLabel = max(largestLabel, labelHeight + 13)
        }
        return max(menuConfig.minMenuRowHeight(), largestLabel)
    }

    func getLabelHeight(_ label: UILabel) -> CGFloat {

        guard let labelText = label.text else {
            return 0
        }
        let constraint = CGSize(width: label.frame.width > 0 ? label.frame.width : menuConfig.minMenuRowHeight() - 20, height: CGFloat.greatestFiniteMagnitude)
        let context = NSStringDrawingContext()
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraph.alignment = .center
        paragraph.allowsDefaultTighteningForTruncation = true
        let boundingBox = NSString(string: labelText).boundingRect(with: constraint, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: label.font, NSParagraphStyleAttributeName: paragraph], context: context).size
        return ceil(boundingBox.height)
    }
}

extension MenuViewController: MenuItemDataSource {
    func numberOfPagesInMenuView(_ menuView: MenuView) -> Int {
        let menuItems = menuConfig.menuItems
        return Int(ceil(Double(menuItems.count) / Double(maxNumberOfItemsPerPage)))
    }

    func numberOfItemsPerRowInMenuView(_ menuView: MenuView) -> Int {
        // return the minimum between the max number of items in the row and the actual number of items
        // for the first page. This allows us to set the number of items per row to be the correct 
        // value when the total number of items < max number of items in the row
        // but retain the correct value when scrolling to later pages.
        return min(menuConfig.numberOfItemsInRow, self.menuView(menuView, numberOfItemsForPage: 0))
    }

    func menuView(_ menuView: MenuView, numberOfItemsForPage page: Int) -> Int {
        let menuItems = menuConfig.menuItems
        let pageStartIndex = page * maxNumberOfItemsPerPage
        if (pageStartIndex + maxNumberOfItemsPerPage) > menuItems.count {
            return menuItems.count - pageStartIndex
        }
        return maxNumberOfItemsPerPage
    }

    func menuView(_ menuView: MenuView, menuItemCellForIndexPath indexPath: IndexPath) -> MenuItemCollectionViewCell {
        let cell = menuView.dequeueReusableCellForIndexPath(indexPath)
        assert(indexPath.getMenuItemIndex() < menuConfig.menuItems.count, "The menu item index \(indexPath.getMenuItemIndex()) should always be less than the number of menu items \(menuConfig.menuItems.count)")
        let menuItem = menuConfig.menuItems[indexPath.getMenuItemIndex()]
        cell.menuTitleLabel.text = menuItem.title
        cell.accessibilityLabel = menuItem.title
        cell.accessibilityIdentifier = menuItem.accessibilityIdentifier
        cell.menuTitleLabel.font = menuConfig.menuFont()
        
        let icon = menuItem.iconForState(appState)
        if menuItem.isDisabled {
            cell.menuTitleLabel.textColor = menuConfig.disabledItemTintColor()
            
            cell.menuImageView.image = icon?.withRenderingMode(.alwaysTemplate)
            cell.menuImageView.tintColor = menuConfig.disabledItemTintColor()
        } else {
            cell.menuTitleLabel.textColor = menuConfig.menuTintColor()
            cell.menuImageView.image = icon
        }

        return cell
    }
}

extension MenuViewController: MenuToolbarDataSource {
    func numberOfToolbarItemsInMenuView(_ menuView: MenuView) -> Int {
        guard let menuToolbarItems = menuConfig.menuToolbarItems else { return 0 }
        return menuToolbarItems.count
    }

    func menuView(_ menuView: MenuView, buttonForItemAtIndex index: Int) -> UIView {
        // this should never happen - if we don't have any toolbar items then we shouldn't get this far
        guard let menuToolbarItems = menuConfig.menuToolbarItems else {
            return UIView()
        }
        let item = menuToolbarItems[index]
        let buttonImageView = UIImageView(image: item.iconForState(appState)?.withRenderingMode(.alwaysTemplate))
        buttonImageView.contentMode = .scaleAspectFit
        buttonImageView.accessibilityLabel = item.title
        buttonImageView.accessibilityIdentifier = item.accessibilityIdentifier
        return buttonImageView
    }
}

extension MenuViewController: MenuToolbarItemDelegate {
    func menuView(_ menuView: MenuView, didSelectItemAtIndex index: Int) {
        let menuToolbarItem = menuConfig.menuToolbarItems![index]
        return performMenuAction(menuToolbarItem.action)
    }

    func menuView(_ menuView: MenuView, didLongPressItemAtIndex index: Int) {
        let menuToolbarItem = menuConfig.menuToolbarItems![index]
        guard let action = menuToolbarItem.secondaryAction else {
            return
        }
        return performMenuAction(action)
    }
}

extension MenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let gestureView = gestureRecognizer.view
        let loc = touch.location(in: gestureView)
        guard let tappedView = gestureView?.hitTest(loc, with: nil), tappedView == view || tappedView == menuView.openMenuImage else {
            return false
        }

        return true
    }
}

private extension IndexPath {
    func getMenuItemIndex() -> Int {
        return (section * maxNumberOfItemsPerPage) + item
    }
}
