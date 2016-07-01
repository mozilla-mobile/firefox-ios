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
        openMenuImage.userInteractionEnabled = true
        openMenuImage.isAccessibilityElement = true
        openMenuImage.accessibilityTraits = UIAccessibilityTraitButton
        openMenuImage.accessibilityLabel =  NSLocalizedString("Menu.CloseMenu.AccessibilityLabel", value: "Close Menu", tableName: "Menu", comment: "Accessibility label describing the button that closes the menu when open")
        return openMenuImage
    }()

    lazy var menuFooterView: UIView = UIView()
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.hidesForSinglePage = true
        pageControl.addTarget(self, action: #selector(self.pageControlDidPage(_:)), forControlEvents: UIControlEvents.ValueChanged)
        return pageControl
    }()

    weak var toolbarDelegate: MenuToolbarItemDelegate?
    weak var toolbarDataSource: MenuToolbarDataSource?
    weak var menuItemDelegate: MenuItemDelegate?
    weak var menuItemDataSource: MenuItemDataSource?

    private let pagingCellReuseIdentifier = "PagingCellReuseIdentifier"

    private lazy var menuPagingLayout: PagingMenuItemCollectionViewLayout = {
        let layout = PagingMenuItemCollectionViewLayout()
        layout.interitemSpacing = self.itemPadding
        layout.lineSpacing = self.itemPadding
        return layout
    }()

    private lazy var menuPagingView: UICollectionView = {
        let pagingView = UICollectionView(frame: CGRectZero, collectionViewLayout: self.menuPagingLayout)
        pagingView.registerClass(MenuItemCollectionViewCell.self, forCellWithReuseIdentifier: self.pagingCellReuseIdentifier)
        pagingView.dataSource = self
        pagingView.delegate = self
        pagingView.showsHorizontalScrollIndicator = false
        pagingView.pagingEnabled = true
        pagingView.backgroundColor = UIColor.clearColor()
        pagingView.accessibilityIdentifier = "Menu.Items.CollectionView"
        return pagingView
    }()

    private var menuContainerView = UIView()

    private var presentationStyle: MenuViewPresentationStyle

    var cornersToRound: UIRectCorner?
    var cornerRadius: CGSize?

    var menuColor: UIColor = UIColor.clearColor() {
        didSet {
            menuContainerView.backgroundColor = menuColor
            menuFooterView.backgroundColor = menuColor
        }
    }

    var toolbarColor: UIColor = UIColor.whiteColor() {
        didSet {
            toolbar.backgroundColor = toolbarColor
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
            pageControl.currentPageIndicatorTintColor = tintColor
            pageControl.pageIndicatorTintColor = tintColor.colorWithAlphaComponent(0.25)
        }
    }

    var toolbarHeight: Float = 40.0 {
        didSet {
            self.setNeedsLayout()
        }
    }

    var menuRowHeight: Float = 0 {
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

    var menuFooterHeight: CGFloat = 44 {
        didSet {
            self.setNeedsLayout()
        }
    }

    var nextPageIndex: Int?

    private var needsReload: Bool = true

    private var toolbarItems = [UIBarButtonItem]()

    init(presentationStyle: MenuViewPresentationStyle) {
        self.presentationStyle = presentationStyle

        super.init(frame: CGRectZero)

        self.addSubview(menuContainerView)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(menuLongPressed))
        menuPagingView.addGestureRecognizer(longPress)

        menuContainerView.addSubview(menuPagingView)
        menuContainerView.addSubview(pageControl)
        self.addSubview(toolbar)

        switch presentationStyle {
        case .Modal:
            addFooter()
            toolbar.snp_makeConstraints { make in
                make.height.equalTo(toolbarHeight)
                make.top.left.right.equalTo(self)
            }
            menuContainerView.snp_makeConstraints { make in
                make.top.equalTo(toolbar.snp_bottom)
                make.left.right.equalTo(self)
                make.bottom.equalTo(menuFooterView.snp_top)
            }

            menuPagingView.snp_makeConstraints { make in
                make.top.left.right.equalTo(menuContainerView)
                make.bottom.equalTo(pageControl.snp_top)
                make.height.equalTo(0)
            }

            pageControl.snp_makeConstraints { make in
                make.bottom.equalTo(menuContainerView)
                make.centerX.equalTo(self)
            }

        case .Popover:
            menuContainerView.snp_makeConstraints { make in
                make.bottom.equalTo(toolbar.snp_top)
                make.left.right.top.equalTo(self)
            }

            menuPagingView.snp_makeConstraints { make in
                make.top.left.right.equalTo(menuContainerView)
                make.bottom.equalTo(pageControl.snp_top).offset(-itemPadding)
                make.height.equalTo(0)
            }
            pageControl.snp_makeConstraints { make in
                make.bottom.equalTo(menuContainerView)
                make.centerX.equalTo(self)
            }
            toolbar.snp_makeConstraints { make in
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
        openMenuImage.snp_makeConstraints { make in
            make.center.equalTo(menuFooterView)
        }
    }

    @objc func pageControlDidPage(sender: AnyObject) {
        let pageSize = menuPagingView.bounds.size
        let xOffset = pageSize.width * CGFloat(pageControl.currentPage)
        menuPagingView.setContentOffset(CGPointMake(xOffset,0) , animated: true)
    }

    @objc private func toolbarButtonSelected(sender: UIView) {
        guard let selectedItemIndex = toolbarItems.indexOf({ $0.customView == sender }) else {
            return
        }
        toolbarDelegate?.menuView(self, didSelectItemAtIndex: selectedItemIndex)
    }

    @objc private func toolbarButtonTapped(gesture: UIGestureRecognizer) {
        guard let view = gesture.view else { return }
        toolbarButtonSelected(view)
    }

    @objc private func toolbarLongPressed(recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .Began else {
            return
        }
        let view = recognizer.view
        guard let index = toolbarItems.indexOf({ $0.customView == view }) else {
            return
        }
        toolbarDelegate?.menuView(self, didLongPressItemAtIndex: index)
    }

    @objc private func menuLongPressed(recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .Began else {
            return
        }

        let point = recognizer.locationInView(menuPagingView)
        guard let indexPath = menuPagingView.indexPathForItemAtPoint(point) else {
            return
        }

        menuItemDelegate?.menuView(self, didLongPressItemAtIndexPath: indexPath)
    }

    // MARK : Menu Cell Management and Recycling
    func reloadData() {
        toolbarItems.removeAll()
        toolbar.items?.removeAll()

        loadToolbar()
        loadMenu()

        needsReload = false
    }

    private func loadToolbar() {
        guard let toolbarDataSource = toolbarDataSource else { return }
        let numberOfToolbarItems = toolbarDataSource.numberOfToolbarItemsInMenuView(self)
        for index in 0..<numberOfToolbarItems {
            let toolbarItemView = toolbarDataSource.menuView(self, buttonForItemAtIndex: index)
            if let buttonView = toolbarItemView as? UIButton {
                buttonView.addTarget(self, action: #selector(self.toolbarButtonSelected(_:)), forControlEvents: .TouchUpInside)
            } else {
                toolbarItemView.userInteractionEnabled = true
                toolbarItemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.toolbarButtonTapped(_:))))
            }

            toolbarItemView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(toolbarLongPressed)))

            let toolbarButton = UIBarButtonItem(customView: toolbarItemView)
            toolbarButton.accessibilityLabel = toolbarItemView.accessibilityLabel
            toolbarButton.isAccessibilityElement = true
            toolbarButton.accessibilityTraits = UIAccessibilityTraitButton
            toolbarItems.append(toolbarButton)
        }
    }

    private func loadMenu() {
        let numberOfPages = menuItemDataSource?.numberOfPagesInMenuView(self) ?? 0
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = currentPageIndex
        menuPagingView.reloadData()
    }

    func setNeedsReload() {
        if !needsReload {
            needsReload = true
            setNeedsLayout()
        }
    }

    private func reloadDataIfNeeded() {
        if needsReload {
            reloadData()
        }
    }

    // MARK : Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        reloadDataIfNeeded()
        layoutToolbar()
        layoutMenu()
        layoutFooter()
        roundCorners()
    }

    func roundCorners() {
        guard let cornersToRound = cornersToRound,
            cornerRadius = cornerRadius else { return }
        // if we have no toolbar items, we won't display a toolbar so we should round the corners of the menuContainerView
        if toolbarItems.count == 0 {
            menuContainerView.addRoundedCorners(cornersToRound: cornersToRound, cornerRadius: cornerRadius, color: menuColor)
        } else {
            toolbar.cornerRadius = cornerRadius
            toolbar.cornersToRound = cornersToRound
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
        menuContainerView.backgroundColor = menuColor
        let numberOfItemsInRow = CGFloat(menuItemDataSource?.numberOfItemsPerRowInMenuView(self) ?? 0)
        menuPagingLayout.maxNumberOfItemsPerPageRow = Int(numberOfItemsInRow)

        menuPagingLayout.menuRowHeight = CGFloat(menuItemDelegate?.heightForRowsInMenuView(self) ?? 0)
        menuRowHeight = Float(menuPagingLayout.menuRowHeight)

        menuPagingView.snp_updateConstraints { make in
            let numberOfRows: CGFloat
            if let maxNumberOfItemsForPage = self.menuItemDataSource?.menuView(self, numberOfItemsForPage: 0) {
                numberOfRows = ceil(CGFloat(maxNumberOfItemsForPage) / numberOfItemsInRow)
            } else {
                numberOfRows = 0
            }
            let menuHeight = itemPadding + (numberOfRows * (CGFloat(self.menuRowHeight) + itemPadding))
            make.height.equalTo(menuHeight)
        }
    }

    private func layoutFooter() {
        menuFooterView.snp_updateConstraints{ make in
            make.height.equalTo(menuFooterHeight)
        }
    }
}

extension MenuView: UICollectionViewDataSource {

    func dequeueReusableCellForIndexPath(indexPath: NSIndexPath) -> MenuItemCollectionViewCell {
        return self.menuPagingView.dequeueReusableCellWithReuseIdentifier(pagingCellReuseIdentifier, forIndexPath: indexPath) as! MenuItemCollectionViewCell
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return menuItemDataSource?.numberOfPagesInMenuView(self) ?? 0
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuItemDataSource?.menuView(self, numberOfItemsForPage: section) ?? 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let dataSource = menuItemDataSource else {
            return collectionView.dequeueReusableCellWithReuseIdentifier(pagingCellReuseIdentifier, forIndexPath: indexPath)
        }

        return dataSource.menuView(self, menuItemCellForIndexPath: indexPath)
    }
}

extension MenuView: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        menuItemDelegate?.menuView(self, didSelectItemAtIndexPath: indexPath)
    }
}

extension MenuView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let pageSize = menuPagingView.bounds.size
        let selectedPageIndex = Int(floor((scrollView.contentOffset.x-pageSize.width/2)/pageSize.width))+1
        pageControl.currentPage = Int(selectedPageIndex)
    }
}
