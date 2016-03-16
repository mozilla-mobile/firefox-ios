/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MenuView: UIView {

    var toolbar: RoundedToolbar
    private let menuItemPageController = MenuPagingViewController()

    var openMenuImage: UIImageView
    var menuFooterView: UIView

    var toolbarDelegate: MenuToolbarItemDelegate?
    var toolbarDataSource: MenuToolbarDataSource?
    var menuItemDelegate: MenuItemDelegate?
    var menuItemDataSource: MenuItemDataSource?

    var toolbarHeight: Float = 40.0 {
        didSet {
            self.setNeedsLayout()
        }
    }

    var menuRowHeight: Float = 65.0 {
        didSet {
            self.setNeedsLayout()
        }
    }

    var itemPadding: CGFloat = 10.0 {
        didSet {
            self.setNeedsLayout()
        }
    }

    var currentPageIndex: Int = 0 {
        didSet {
            needsReload = true
            self.setNeedsLayout()
        }
    }

    var menuFooterHeight: CGFloat = 40 {
        didSet {
            self.setNeedsLayout()
        }
    }

    var nextPageIndex: Int?

    private var needsReload: Bool = true

    private var cachedItems = [NSIndexPath: MenuItemView]()
    private var reusableItems = [MenuItemView]()
    private var toolbarItems = [UIBarButtonItem]()

    init() {
        toolbar = RoundedToolbar()
        toolbar.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        menuFooterView = UIView()
        openMenuImage = UIImageView()

        super.init(frame: CGRectZero)

        toolbar.cornersToRound = [.TopLeft, .TopRight]
        self.addSubview(toolbar)
        toolbar.snp_makeConstraints { make in
            make.height.equalTo(toolbarHeight)
            make.top.left.right.equalTo(self)
        }

        self.addSubview(menuFooterView)
        // so it always displays the colour of the background
        menuFooterView.backgroundColor = UIColor.clearColor()
        menuFooterView.snp_makeConstraints { make in
            make.height.equalTo(menuFooterHeight)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
        }

        menuFooterView.addSubview(openMenuImage)
        openMenuImage.snp_makeConstraints { make in
            make.center.equalTo(menuFooterView)
            make.height.equalTo(menuFooterView)
        }

        let pageControllerView = menuItemPageController.view
        self.addSubview(pageControllerView)
        pageControllerView.snp_makeConstraints { make in
            make.top.equalTo(toolbar.snp_bottom)
            make.left.right.equalTo(self)
            make.bottom.equalTo(menuFooterView.snp_top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }



    override func layoutSubviews() {
        reloadDataIfNeeded()
        layoutToolbar()
        layoutMenu()
        layoutFooter()
        super.layoutSubviews()
    }

    func reloadData() {
        cachedItems.keys.forEach { path in
            cachedItems[path]?.removeFromSuperview()
        }
        cachedItems.removeAll()

        reusableItems.forEach {
            $0.removeFromSuperview()
        }
        reusableItems.removeAll()

        toolbarItems.removeAll()
        toolbar.items?.removeAll()

        loadToolbar()
        loadMenu()

        needsReload = false
    }

    func dequeueReusableMenuItemViewForIndexPath(indexPath: NSIndexPath) -> MenuItemView {
        if let existingView = cachedItems[indexPath] {
            return existingView
        }

        let view = reusableItems.last == nil ? MenuItemView() : reusableItems.removeLast()
        cachedItems[indexPath] = view
        return view
    }

    private func loadToolbar() {
        guard let toolbarDataSource = toolbarDataSource else { return }
        let numberOfToolbarItems = toolbarDataSource.numberOfToolbarItemsInMenuView(self)
        for index in 0..<numberOfToolbarItems {
            let toolbarButton = toolbarDataSource.menuView(self, buttonForItemAtIndex: index)
            toolbarButton.target = self
            toolbarButton.action = "toolbarButtonSelected:"
            toolbarItems.append(toolbarButton)
        }
    }

    private func loadMenu() {
        let numberOfPages = menuItemDataSource?.numberOfPagesInMenuView(self) ?? 0

        for pageIndex in 0..<numberOfPages {
            loadMenuForPageIndex(pageIndex)
        }
    }

    private func loadMenuForPageIndex(pageIndex: Int) {
        guard let itemDataSource = menuItemDataSource else { return }

        let numberOfItemsForPage = itemDataSource.menuView(self, numberOfItemsForPage: pageIndex)
        for index in 0..<numberOfItemsForPage {
            let indexPath = NSIndexPath(forItem: index, inSection: pageIndex)
            cachedItems[indexPath] = itemDataSource.menuView(self, viewForItemAtIndexPath: indexPath)
        }

    }

    func setNeedsReload() {
        needsReload = true
        setNeedsLayout()
    }

    private func reloadDataIfNeeded() {
        if needsReload {
            reloadData()
        }
    }

    private func layoutToolbar() {
        var displayToolbarItems = [UIBarButtonItem]()
        for (index, item) in toolbarItems.enumerate() {
            displayToolbarItems.append(item)
            if index < toolbarItems.count-1 {
                displayToolbarItems.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil))
            }
        }
        if displayToolbarItems.count == 0 {
            toolbar.snp_updateConstraints { make in
                make.height.equalTo(0)
            }
        } else {
            toolbar.snp_updateConstraints { make in
                make.height.equalTo(toolbarHeight)
            }
            toolbar.setItems(displayToolbarItems, animated: false)
        }
    }


    private func layoutMenu() {
        // make a copy of cached items
        var availableItems = cachedItems
        cachedItems.removeAll()

        menuItemPageController.viewControllers = []
        // get views for the previous page, if there is one
        for pageIndex in 0..<(menuItemDataSource?.numberOfPagesInMenuView(self) ?? 0) {
            layoutPage(pageIndex, availableItems: &availableItems)
        }

        // add any unused views to reusable items
        for item in availableItems.values {
            item.prepareForReuse()
            reusableItems.append(item)
        }
        availableItems.removeAll()
    }

    private func layoutPage(pageIndex: Int, inout availableItems: [NSIndexPath: MenuItemView]) {
        guard let itemDataSource = menuItemDataSource else { return }

        let numberOfPages = itemDataSource.numberOfPagesInMenuView(self)

        if pageIndex < 0 || pageIndex >= numberOfPages { return }

        let numberOfItemsForPage = itemDataSource.menuView(self, numberOfItemsForPage: pageIndex)

        for index in 0..<numberOfItemsForPage {
            let indexPath = NSIndexPath(forItem: index, inSection: pageIndex)
            guard let item = availableItems[indexPath] else { continue }
            cachedItems[indexPath] = item
            availableItems.removeValueForKey(indexPath)
        }

        menuItemPageController.viewControllers.append(menuPageControllerForPageIndex(pageIndex))

    }

    private func layoutFooter() {
        menuFooterView.snp_updateConstraints{ make in
            make.height.equalTo(menuFooterHeight)
        }
    }

    @objc private func toolbarButtonSelected(sender: UIBarButtonItem) {
        guard let selectedButtonIndex = toolbarItems.indexOf(sender) else { return }
        toolbarDelegate?.menuView(self, didSelectItemAtIndex: selectedButtonIndex)
    }
    
    func indexPathForView(itemView: MenuItemView) -> NSIndexPath? {
        return (cachedItems as NSDictionary).allKeysForObject(itemView).first as? NSIndexPath
    }
}

extension  MenuView: MenuPageViewControllerDelegate {
    func menuPageViewController(menuItemViewController: MenuPageViewController, didSelectMenuItem menuItem: MenuItemView, atIndexPath indexPath: NSIndexPath) {
        menuItemDelegate?.menuView(self, didSelectItemAtIndexPath: indexPath)
    }
}

extension MenuView: UIPageViewControllerDataSource {

    func menuPageControllerForPageIndex(pageIndex: Int) -> MenuPageViewController {
        let menuVC = MenuPageViewController()
        menuVC.setItems(itemsForPageIndex(pageIndex), forPageIndex: pageIndex)
        menuVC.delegate = self
        menuVC.numberOfItemsInRow = CGFloat(menuItemDataSource?.numberOfItemsPerRowInMenuView(self) ?? 0)
        menuVC.itemPadding = itemPadding
        menuVC.menuRowHeight = CGFloat(menuRowHeight)
        return menuVC
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let nextPageIndex = (viewController as! MenuPageViewController).pageIndex + 1
        if nextPageIndex < (menuItemDataSource?.numberOfPagesInMenuView(self) ?? 0) {
            return menuPageControllerForPageIndex(nextPageIndex)
        }
        return nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let previousPageIndex = (viewController as! MenuPageViewController).pageIndex - 1
        if previousPageIndex >= 0 {
            return menuPageControllerForPageIndex(previousPageIndex)
        }
        return nil
    }

    private func itemsForPageIndex(pageIndex: Int) -> [MenuItemView] {

        var itemsForPageIndex = [MenuItemView]()
        let numberOfItemsForPage = menuItemDataSource?.menuView(self, numberOfItemsForPage: pageIndex) ?? 0
        for index in 0..<numberOfItemsForPage {
            let indexPath = NSIndexPath(forItem: index, inSection: pageIndex)
            if let view = cachedItems[indexPath] ?? menuItemDataSource?.menuView(self, viewForItemAtIndexPath: indexPath) {
                if cachedItems[indexPath] == nil {
                    cachedItems[indexPath] = view
                }

                itemsForPageIndex.append(view)
            }
        }

        return itemsForPageIndex
    }

    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return (menuItemDataSource?.numberOfPagesInMenuView(self) ?? 0)
    }

    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return currentPageIndex + 1
    }
}

extension MenuView: UIPageViewControllerDelegate {

    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        guard let nextVC = pendingViewControllers.first as? MenuPageViewController else { return }
        nextPageIndex = nextVC.pageIndex
    }

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        defer {
            nextPageIndex = nil
        }

        guard completed, let nextIndex = nextPageIndex else { return }
        currentPageIndex = nextIndex
    }

}

extension UIPageViewController {
    func getScrollView() -> UIScrollView? {
        for subview in view.subviews {
            if subview is UIScrollView {
                return subview as? UIScrollView
            }
        }
        
        return nil
    }
}
