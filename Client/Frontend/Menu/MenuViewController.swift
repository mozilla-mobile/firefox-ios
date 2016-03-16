/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let maxNumberOfItemsPerPage = 6

class MenuViewController: UIViewController {

    let colours = [UIColor.magentaColor(), UIColor.brownColor(), UIColor.greenColor(), UIColor.orangeColor(), UIColor.redColor(), UIColor.yellowColor()]
    var menuConfig: MenuConfiguration

    init(withMenuConfig config: MenuConfiguration) {
        self.menuConfig = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.blueColor()

        // Do any additional setup after loading the view.
        let menuView = MenuView()
        self.view.addSubview(menuView)

        menuView.snp_makeConstraints { make in
            make.left.equalTo(view.snp_left).offset(24)
            make.right.equalTo(view.snp_right).offset(-24)
            make.bottom.equalTo(view.snp_bottom)
        }

        menuView.menuItemDataSource = self
        menuView.menuItemDelegate = self
        menuView.toolbarDelegate = self
        menuView.toolbarDataSource = self

        menuView.backgroundColor = UIColor.orangeColor()
        menuView.toolbar.backgroundColor = UIColor.cyanColor()
        menuView.menuFooterView.backgroundColor = UIColor.cyanColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
extension MenuViewController: MenuItemDelegate {
    func menuView(menu: MenuView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    }
}

extension MenuViewController: MenuItemDataSource {
    func numberOfPagesInMenuView(menuView: MenuView) -> Int {
        let menuItems = menuConfig.menuItems
        return Int(ceil(Double(menuItems.count) / Double(maxNumberOfItemsPerPage)))
    }

    func numberOfItemsPerRowInMenuView(menuView: MenuView) -> Int {
        return 3
    }

    func menuView(menuView: MenuView, numberOfItemsForPage page: Int) -> Int {
        let menuItems = menuConfig.menuItems
        let pageStartIndex = page * maxNumberOfItemsPerPage
        if (pageStartIndex + maxNumberOfItemsPerPage) > menuItems.count {
            return menuItems.count - pageStartIndex
        }
        return maxNumberOfItemsPerPage
    }

    func menuView(menuView: MenuView, viewForItemAtIndexPath indexPath: NSIndexPath) -> MenuItemView {
        let menuItemView = menuView.dequeueReusableMenuItemViewForIndexPath(indexPath)

        let menuItems = menuConfig.menuItems
        let menuItem = menuItems[indexPath.getMenuItemIndex()]

        menuItemView.setTitle(menuItem.title)
        menuItemView.titleLabel.font = UIFont.systemFontOfSize(12)
        menuItemView.titleLabel.textColor = UIColor.blackColor()
        menuItemView.backgroundColor = colours[indexPath.item]
        if let icon = menuItem.icon {
            menuItemView.setImage(icon)
        }

        return menuItemView
    }

    @objc private func didReceiveLongPress(recognizer: UILongPressGestureRecognizer) {
    }
}

extension MenuViewController: MenuToolbarDataSource {
    func numberOfToolbarItemsInMenuView(menuView: MenuView) -> Int {
        guard let menuToolbarItems = menuConfig.menuToolbarItems else { return 0}
        return menuToolbarItems.count
    }

    func menuView(menuView: MenuView, buttonForItemAtIndex index: Int) -> UIBarButtonItem {
        // this should never happen - if we don't have any toolbar items then we shouldn't get this far
        guard let menuToolbarItems = menuConfig.menuToolbarItems else {
            return UIBarButtonItem(title: nil, style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        }
        let item = menuToolbarItems[index]
        let toolbarItemView = UIBarButtonItem(image: item.icon, style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        return toolbarItemView
    }
}

extension MenuViewController: MenuToolbarItemDelegate {
    func menuView(menuView: MenuView, didSelectItemAtIndex index: Int) {
    }
}

extension NSIndexPath {
    func getMenuItemIndex() -> Int {
        return (section * maxNumberOfItemsPerPage) + row
    }
}
