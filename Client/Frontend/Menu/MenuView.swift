//
//  MenuView.swift
//  Client
//
//  Created by Emily Toop on 3/10/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class MenuView: UIView {

    private var toolbar: UIToolbar
    private var menuItemViewContainer: UIView

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

    var nextPageIndex: Int?

    private var needsReload: Bool = true

    private var cachedItems = [NSIndexPath: MenuItemView]()
    private var reusableItems = [MenuItemView]()
    private var toolbarItems = [UIBarButtonItem]()

    init() {
        toolbar = UIToolbar()
        toolbar.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        menuItemViewContainer = UIView()

        super.init(frame: CGRectZero)

        self.backgroundColor = UIColor.cyanColor()

        self.addSubview(toolbar)
        toolbar.snp_makeConstraints { make in
            make.top.left.right.equalTo(self)
        }

        self.addSubview(menuItemViewContainer)
        menuItemViewContainer.snp_makeConstraints { make in
            make.top.equalTo(toolbar.snp_bottom).inset(-itemPadding)
            make.left.right.bottom.equalTo(self).inset(itemPadding)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }



    override func layoutSubviews() {
        reloadDataIfNeeded()
        layoutToolbar()
        layoutMenu()
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
        let lastPageIndex = currentPageIndex - 1
        if lastPageIndex >= 0 {
            loadMenuForPageIndex(lastPageIndex)
        }

        loadMenuForPageIndex(currentPageIndex)

        let nextPageIndex = currentPageIndex + 1
        if nextPageIndex < menuItemDataSource?.numberOfPagesInMenuView(self) ?? 0 {
            loadMenuForPageIndex(nextPageIndex)
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

        // get views for the previous page, if there is one
        for pageIndex in currentPageIndex-1...currentPageIndex+1 {
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

        menuItemViewContainer.backgroundColor = UIColor.purpleColor()

        guard let itemDataSource = menuItemDataSource else { return }

        let numberOfPages = itemDataSource.numberOfPagesInMenuView(self)

        if pageIndex < 0 || pageIndex >= numberOfPages { return }

        let numberOfItemsForPage = itemDataSource.menuView(self, numberOfItemsForPage: pageIndex)
        let numberOfItemsInRow = itemDataSource.numberOfItemsPerRowInMenuView(self)

        let numberOfRows = ceil(CGFloat(numberOfItemsForPage) / CGFloat(numberOfItemsInRow))
        let height = itemPadding + (CGFloat(numberOfRows) * (CGFloat(menuRowHeight) + itemPadding))
        menuItemViewContainer.snp_updateConstraints { make in
            make.height.equalTo(height)
        }

        for index in 0..<numberOfItemsForPage {
            let indexPath = NSIndexPath(forItem: index, inSection: pageIndex)
            guard let item = availableItems[indexPath] else { continue }
            cachedItems[indexPath] = item
            menuItemViewContainer.addSubview(item)

            // now properly lay out the cells
            let row = floor(CGFloat(index) / CGFloat(numberOfItemsInRow))
            let columnIndex = index - (Int(row) * numberOfItemsInRow)
            let columnMultiplier = CGFloat(columnIndex)/CGFloat(numberOfItemsInRow)
            let rowMultiplier = CGFloat(row) / CGFloat(numberOfRows)
            item.snp_makeConstraints { make in
                make.height.greaterThanOrEqualTo(menuItemViewContainer.snp_height).dividedBy(numberOfRows)
                make.width.greaterThanOrEqualTo(menuItemViewContainer.snp_width).dividedBy(numberOfItemsInRow)
                if columnMultiplier > 0 {
                    make.left.equalTo(menuItemViewContainer.snp_right).multipliedBy(columnMultiplier)
                } else {
                    make.left.equalTo(menuItemViewContainer.snp_left)
                }

                if rowMultiplier > 0 {
                    make.top.equalTo(menuItemViewContainer.snp_bottom).multipliedBy(rowMultiplier)
                } else {
                    make.top.equalTo(menuItemViewContainer.snp_top)
                }
            }
            availableItems.removeValueForKey(indexPath)
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
