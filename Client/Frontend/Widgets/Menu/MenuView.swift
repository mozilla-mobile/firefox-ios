/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MenuView: UIView {

    lazy var toolbar: RoundedToolbar = {
        let toolbar = RoundedToolbar()
        toolbar.setContentHuggingPriority(UILayoutPriorityRequired, for: UILayoutConstraintAxis.vertical)
        toolbar.contentMode = .redraw
        return toolbar
    }()

    lazy var openMenuImage: UIImageView = {
        let openMenuImage = UIImageView()
        openMenuImage.contentMode = UIViewContentMode.scaleAspectFit
        openMenuImage.isUserInteractionEnabled = true
        openMenuImage.isAccessibilityElement = true
        openMenuImage.accessibilityTraits = UIAccessibilityTraitButton
        openMenuImage.accessibilityLabel =  NSLocalizedString("Menu.CloseMenu.AccessibilityLabel", tableName: "Menu", value: "Close Menu", comment: "Accessibility label describing the button that closes the menu when open")
        return openMenuImage
    }()

    lazy var menuFooterView: UIView = UIView()
    fileprivate lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.hidesForSinglePage = true
        pageControl.addTarget(self, action: #selector(self.pageControlDidPage(_:)), for: UIControlEvents.valueChanged)
        return pageControl
    }()

    weak var toolbarDelegate: MenuToolbarItemDelegate?
    weak var toolbarDataSource: MenuToolbarDataSource?
    weak var menuItemDelegate: MenuItemDelegate?
    weak var menuItemDataSource: MenuItemDataSource?

    fileprivate let pagingCellReuseIdentifier = "PagingCellReuseIdentifier"

    fileprivate lazy var menuPagingLayout: PagingMenuItemCollectionViewLayout = {
        let layout = PagingMenuItemCollectionViewLayout()
        layout.interitemSpacing = self.itemPadding
        layout.lineSpacing = self.itemPadding
        return layout
    }()

    fileprivate lazy var menuPagingView: UICollectionView = {
        let pagingView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.menuPagingLayout)
        pagingView.register(MenuItemCollectionViewCell.self, forCellWithReuseIdentifier: self.pagingCellReuseIdentifier)
        pagingView.dataSource = self
        pagingView.delegate = self
        pagingView.showsHorizontalScrollIndicator = false
        pagingView.isPagingEnabled = true
        pagingView.backgroundColor = UIColor.clear
        return pagingView
    }()

    fileprivate var menuContainerView = UIView()

    fileprivate var presentationStyle: MenuViewPresentationStyle

    var cornersToRound: UIRectCorner?
    var cornerRadius: CGSize?

    var menuColor: UIColor = UIColor.clear {
        didSet {
            menuContainerView.backgroundColor = menuColor
            menuFooterView.backgroundColor = menuColor
        }
    }

    var toolbarColor: UIColor = UIColor.white {
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
            pageControl.pageIndicatorTintColor = tintColor.withAlphaComponent(0.25)
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

    fileprivate var needsReload: Bool = true

    fileprivate var toolbarItems = [UIBarButtonItem]()

    init(presentationStyle: MenuViewPresentationStyle) {
        self.presentationStyle = presentationStyle

        super.init(frame: CGRect.zero)

        self.addSubview(menuContainerView)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(menuLongPressed))
        menuPagingView.addGestureRecognizer(longPress)

        menuContainerView.addSubview(menuPagingView)
        menuContainerView.addSubview(pageControl)
        self.addSubview(toolbar)

        switch presentationStyle {
        case .modal:
            addFooter()
            toolbar.snp.makeConstraints { make in
                make.height.equalTo(toolbarHeight)
                make.top.left.right.equalTo(self)
            }
            menuContainerView.snp.makeConstraints { make in
                make.top.equalTo(toolbar.snp.bottom)
                make.left.right.equalTo(self)
                make.bottom.equalTo(menuFooterView.snp.top)
            }

            menuPagingView.snp.makeConstraints { make in
                make.top.left.right.equalTo(menuContainerView)
                make.bottom.equalTo(pageControl.snp.top)
                make.height.equalTo(0)
            }

            pageControl.snp.makeConstraints { make in
                make.bottom.equalTo(menuContainerView)
                make.centerX.equalTo(self)
            }

        case .popover:
            menuContainerView.snp.makeConstraints { make in
                make.bottom.equalTo(toolbar.snp.top)
                make.left.right.top.equalTo(self)
            }

            menuPagingView.snp.makeConstraints { make in
                make.top.left.right.equalTo(menuContainerView)
                make.bottom.equalTo(pageControl.snp.top).offset(-itemPadding)
                make.height.equalTo(0)
            }
            pageControl.snp.makeConstraints { make in
                make.bottom.equalTo(menuContainerView)
                make.centerX.equalTo(self)
            }
            toolbar.snp.makeConstraints { make in
                make.height.equalTo(toolbarHeight)
                make.bottom.left.right.equalTo(self)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func addFooter() {
        self.addSubview(menuFooterView)
        // so it always displays the colour of the background
        menuFooterView.backgroundColor = UIColor.clear
        menuFooterView.snp.makeConstraints { make in
            make.height.equalTo(menuFooterHeight)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self)
        }

        menuFooterView.addSubview(openMenuImage)
        openMenuImage.snp.makeConstraints { make in
            make.center.equalTo(menuFooterView)
        }
    }

    @objc func pageControlDidPage(_ sender: AnyObject) {
        let pageSize = menuPagingView.bounds.size
        let xOffset = pageSize.width * CGFloat(pageControl.currentPage)
        menuPagingView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: true)
    }

    @objc fileprivate func toolbarButtonSelected(_ sender: UIView) {
        guard let selectedItemIndex = toolbarItems.index(where: { $0.customView == sender }) else {
            return
        }
        toolbarDelegate?.menuView(self, didSelectItemAtIndex: selectedItemIndex)
    }

    @objc fileprivate func toolbarButtonTapped(_ gesture: UIGestureRecognizer) {
        guard let view = gesture.view else { return }
        toolbarButtonSelected(view)
    }

    @objc fileprivate func toolbarLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else {
            return
        }
        let view = recognizer.view
        guard let index = toolbarItems.index(where: { $0.customView == view }) else {
            return
        }
        toolbarDelegate?.menuView(self, didLongPressItemAtIndex: index)
    }

    @objc fileprivate func menuLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else {
            return
        }

        let point = recognizer.location(in: menuPagingView)
        guard let indexPath = menuPagingView.indexPathForItem(at: point) else {
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

    fileprivate func loadToolbar() {
        guard let toolbarDataSource = toolbarDataSource else { return }
        let numberOfToolbarItems = toolbarDataSource.numberOfToolbarItemsInMenuView(self)
        for index in 0..<numberOfToolbarItems {
            let toolbarItemView = toolbarDataSource.menuView(self, buttonForItemAtIndex: index)
            if let buttonView = toolbarItemView as? UIButton {
                buttonView.addTarget(self, action: #selector(self.toolbarButtonSelected(_:)), for: .touchUpInside)
            } else {
                toolbarItemView.isUserInteractionEnabled = true
                toolbarItemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.toolbarButtonTapped(_:))))
            }

            toolbarItemView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(toolbarLongPressed)))

            let toolbarButton = UIBarButtonItem(customView: toolbarItemView)
            toolbarButton.accessibilityLabel = toolbarItemView.accessibilityLabel
            toolbarButton.isAccessibilityElement = true
            toolbarButton.accessibilityTraits = UIAccessibilityTraitButton
            toolbarButton.accessibilityIdentifier = toolbarItemView.accessibilityIdentifier
            toolbarItems.append(toolbarButton)
        }
    }

    fileprivate func loadMenu() {
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

    fileprivate func reloadDataIfNeeded() {
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
            let cornerRadius = cornerRadius else { return }
        // if we have no toolbar items, we won't display a toolbar so we should round the corners of the menuContainerView
        if toolbarItems.count == 0 {
            menuContainerView.addRoundedCorners(cornersToRound, cornerRadius: cornerRadius, color: menuColor)
        } else {
            toolbar.cornerRadius = cornerRadius
            toolbar.cornersToRound = cornersToRound
        }
    }

    fileprivate func layoutToolbar() {
        var displayToolbarItems = [UIBarButtonItem]()
        for (index, item) in toolbarItems.enumerated() {
            displayToolbarItems.append(item)
            if index < toolbarItems.count-1 {
                displayToolbarItems.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil))
            }
        }
        if displayToolbarItems.count == 0 {
            toolbar.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        } else {
            toolbar.snp.updateConstraints { make in
                make.height.equalTo(toolbarHeight)
            }
            toolbar.setItems(displayToolbarItems, animated: false)
        }
        toolbar.backgroundColor = toolbarColor
    }

    fileprivate func layoutMenu() {
        menuContainerView.backgroundColor = menuColor
        let numberOfItemsInRow = CGFloat(menuItemDataSource?.numberOfItemsPerRowInMenuView(self) ?? 0)
        menuPagingLayout.maxNumberOfItemsPerPageRow = Int(numberOfItemsInRow)

        menuPagingLayout.menuRowHeight = CGFloat(menuItemDelegate?.heightForRowsInMenuView(self) ?? 0)
        menuRowHeight = Float(menuPagingLayout.menuRowHeight)

        menuPagingView.snp.updateConstraints { make in
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

    fileprivate func layoutFooter() {
        menuFooterView.snp.updateConstraints { make in
            make.height.equalTo(menuFooterHeight)
        }
    }
}

extension MenuView: UICollectionViewDataSource {

    func dequeueReusableCellForIndexPath(_ indexPath: IndexPath) -> MenuItemCollectionViewCell {
        return self.menuPagingView.dequeueReusableCell(withReuseIdentifier: pagingCellReuseIdentifier, for: indexPath) as! MenuItemCollectionViewCell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return menuItemDataSource?.numberOfPagesInMenuView(self) ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuItemDataSource?.menuView(self, numberOfItemsForPage: section) ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let dataSource = menuItemDataSource else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: pagingCellReuseIdentifier, for: indexPath)
        }

        return dataSource.menuView(self, menuItemCellForIndexPath: indexPath)
    }
}

extension MenuView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        menuItemDelegate?.menuView(self, didSelectItemAtIndexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return menuItemDelegate?.menuView(self, shouldSelectItemAtIndexPath: indexPath) ?? false
    }
}

extension MenuView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageSize = menuPagingView.bounds.size
        let selectedPageIndex = Int(floor((scrollView.contentOffset.x-pageSize.width/2)/pageSize.width))+1
        pageControl.currentPage = Int(selectedPageIndex)
    }
}
