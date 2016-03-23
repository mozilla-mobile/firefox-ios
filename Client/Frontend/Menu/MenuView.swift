/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MenuView: UIView {

    lazy var toolbar: RoundedToolbar = {
        let toolbar = RoundedToolbar()
        toolbar.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        return toolbar
    }()

    lazy var openMenuImage: UIImageView = {
        let openMenuImage = UIImageView()
        openMenuImage.contentMode = UIViewContentMode.ScaleAspectFit
        return openMenuImage
    }()

    lazy var menuFooterView: UIView = UIView()
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.hidesForSinglePage = true
        pageControl.addTarget(self, action: "pageControlDidPage:", forControlEvents: UIControlEvents.ValueChanged)
        return pageControl
    }()

    var toolbarDelegate: MenuToolbarItemDelegate?
    var toolbarDataSource: MenuToolbarDataSource?
    var menuItemDelegate: MenuItemDelegate?
    var menuItemDataSource: MenuItemDataSource?

    private let pagingCellReuseIdentifier = "PagingCellReuseIdentifier"

    private lazy var menuPagingLayout: UICollectionViewFlowLayout = {
        let layout = TopAlignedCollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        return layout
    }()

    private lazy var menuPagingView: UICollectionView = {
        let pagingView = UICollectionView(frame: CGRectZero, collectionViewLayout: self.menuPagingLayout)
        pagingView.registerClass(MenuPageCollectionViewCell.self, forCellWithReuseIdentifier: self.pagingCellReuseIdentifier)
        pagingView.dataSource = self
        pagingView.delegate = self
        pagingView.showsHorizontalScrollIndicator = false
        pagingView.pagingEnabled = true
        return pagingView
    }()

    private var presentationStyle: MenuViewPresentationStyle

    private var menuColor: UIColor = UIColor.clearColor() {
        didSet {
            menuPagingView.backgroundColor = menuColor
            pageControl.backgroundColor = menuColor
            menuFooterView.backgroundColor = menuColor
        }
    }

    override var backgroundColor: UIColor! {
        didSet {
            menuColor = backgroundColor
        }
    }
    
    override var tintColor: UIColor! {
        didSet {
            menuPagingView.tintColor = tintColor
        }
    }

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

    init(presentationStyle: MenuViewPresentationStyle) {
        self.presentationStyle = presentationStyle

        super.init(frame: CGRectZero)

        self.addSubview(menuPagingView)
        self.addSubview(pageControl)
        self.addSubview(toolbar)

        switch presentationStyle {
        case .Modal:
            addFooter()
            toolbar.snp_makeConstraints { make in
                make.height.equalTo(toolbarHeight)
                make.top.left.right.equalTo(self)
            }

            menuPagingView.snp_makeConstraints { make in
                make.top.equalTo(toolbar.snp_bottom)
                make.left.right.equalTo(self)
                make.bottom.equalTo(pageControl.snp_top)
                make.height.equalTo(100)
            }

            pageControl.snp_makeConstraints { make in
                make.bottom.equalTo(menuFooterView.snp_top)
                make.centerX.equalTo(self)
            }

        case .Popover:
            menuPagingView.snp_makeConstraints { make in
                make.top.left.right.equalTo(self)
            }
            pageControl.snp_makeConstraints { make in
                make.top.equalTo(menuPagingView.snp_bottom)
                make.centerX.equalTo(self)
            }
            toolbar.snp_makeConstraints { make in
                make.top.equalTo(pageControl.snp_bottom)
                make.height.equalTo(toolbarHeight)
                make.bottom.left.right.equalTo(self)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addFooter() {
        self.addSubview(menuFooterView)
        // so it always displays the colour of the background
        menuFooterView.backgroundColor = UIColor.clearColor()
        menuFooterView.snp_makeConstraints { make in
            make.height.equalTo(menuFooterHeight)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
        }

        menuFooterView.addSubview(openMenuImage)
        openMenuImage.accessibilityLabel = NSLocalizedString("Close Menu", tableName: "Menu", comment: "Accessibility Label attached to the button for closing the menu")
        openMenuImage.snp_makeConstraints { make in
            make.center.equalTo(menuFooterView)
            make.height.equalTo(menuFooterView)
        }
    }

    @objc func pageControlDidPage(sender: AnyObject) {
        let pageSize = menuPagingView.bounds.size
        let xOffset = pageSize.width * CGFloat(pageControl.currentPage)
        menuPagingView.setContentOffset(CGPointMake(xOffset,0) , animated: true)
    }

    @objc private func toolbarButtonSelected(sender: UIBarButtonItem) {
        guard let selectedButtonIndex = toolbarItems.indexOf(sender) else { return }
        toolbarDelegate?.menuView(self, didSelectItemAtIndex: selectedButtonIndex)
    }

    func indexPathForView(itemView: MenuItemView) -> NSIndexPath? {
        return (cachedItems as NSDictionary).allKeysForObject(itemView).first as? NSIndexPath
    }


    // MARK : Menu Cell Management and Recycling
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
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = currentPageIndex

        loadMenuForPageIndex(currentPageIndex)
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

    // MARK : Layout

    override func layoutSubviews() {
        reloadDataIfNeeded()
        layoutToolbar()
        layoutMenu()
        layoutFooter()
        super.layoutSubviews()
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
        let menuHeight = self.collectionView(menuPagingView, layout: self.menuPagingLayout, sizeForItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0)).height
        menuPagingView.snp_updateConstraints { make in
            make.height.equalTo(menuHeight)
        }
        // make a copy of cached items
        var availableItems = cachedItems
        cachedItems.removeAll()

        // get views for the current page and if there is one, the previous and subsequent pages
        layoutPage(currentPageIndex, availableItems: &availableItems)

        // add any unused views to reusable items
        for item in availableItems.values {
            item.prepareForReuse()
            reusableItems.append(item)
        }
        availableItems.removeAll()
    }

    private func layoutPage(pageIndex: Int, inout availableItems: [NSIndexPath: MenuItemView]) {
        let numberOfItemsForPage = menuItemDataSource?.menuView(self, numberOfItemsForPage: pageIndex) ?? 0

        for index in 0..<numberOfItemsForPage {
            let indexPath = NSIndexPath(forItem: index, inSection: pageIndex)
            guard let item = availableItems[indexPath] else { continue }
            cachedItems[indexPath] = item
            availableItems.removeValueForKey(indexPath)
        }
    }

    private func layoutFooter() {
        menuFooterView.snp_updateConstraints{ make in
            make.height.equalTo(menuFooterHeight)
        }
    }
}

extension  MenuView: MenuPageViewDelegate {
    func menuPageView(menuPageView: MenuPageView, didSelectMenuItem menuItem: MenuItemView, atIndexPath indexPath: NSIndexPath) {
        menuItemDelegate?.menuView(self, didSelectItemAtIndexPath: indexPath)
    }
}

extension MenuView: UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfPagesInView = menuItemDataSource?.numberOfPagesInMenuView(self) ?? 0
        return numberOfPagesInView
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(pagingCellReuseIdentifier, forIndexPath: indexPath) as! MenuPageCollectionViewCell
        cell.pageView.setItems(itemsForPageIndex(indexPath.row), forPageIndex: indexPath.row)
        cell.pageView.delegate = self
        cell.pageView.numberOfItemsInRow = CGFloat(menuItemDataSource?.numberOfItemsPerRowInMenuView(self) ?? 0)
        cell.pageView.itemPadding = itemPadding
        cell.pageView.menuRowHeight = CGFloat(menuRowHeight)
        return cell
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
}

extension MenuView: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let items = itemsForPageIndex(indexPath.row)
        let numberOfRows = ceil(CGFloat(items.count) / CGFloat(menuItemDataSource?.numberOfItemsPerRowInMenuView(self) ?? 0))
        let menuHeight = itemPadding + (numberOfRows * (CGFloat(menuRowHeight) + itemPadding))
        let size = CGSizeMake(collectionView.bounds.size.width - itemPadding, menuHeight)
        return size
    }

}

extension MenuView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let pageSize = menuPagingView.bounds.size
        let selectedPageIndex = Int(floor((scrollView.contentOffset.x-pageSize.width/2)/pageSize.width))+1
        pageControl.currentPage = Int(selectedPageIndex)
    }
}
