/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol MenuPageViewDelegate: class {
    func menuPageView(menuPageView: MenuPageView, didSelectMenuItem menuItem: MenuItemView, atIndexPath indexPath: NSIndexPath)
}

public class MenuPageView: UIView {

    weak var delegate: MenuPageViewDelegate?
    public var pageIndex: Int = 0 {
        didSet {
            self.setNeedsLayout()
        }
    }
    public var numberOfItemsInRow:CGFloat = 0 {
        didSet {
            numberOfRows = ceil(CGFloat(items.count) / numberOfItemsInRow)
        }
    }
    public var itemPadding: CGFloat = 0
    public var menuRowHeight: CGFloat = 0

    private let itemContainerView = UIView()
    private var items = [MenuItemView]() {
        didSet {
            numberOfRows = ceil(CGFloat(items.count) / numberOfItemsInRow)
        }
    }

    private var numberOfRows:CGFloat = 0
    private var rowHeight: CGFloat = 0

    var height: CGFloat {
        return itemPadding + (numberOfRows * (menuRowHeight + itemPadding))
    }

    init() {
        super.init(frame: CGRectZero)
        backgroundColor = UIColor.clearColor()
        // Do any additional setup after loading the view.
        addSubview(itemContainerView)

        itemContainerView.restorationIdentifier = "ItemContainerView"
        itemContainerView.accessibilityIdentifier = "Menu.ItemContainerView"
        itemContainerView.snp_makeConstraints { make in
            make.left.top.right.equalTo(self)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        rowHeight = self.bounds.size.height / CGFloat(numberOfRows)

        for (index, item) in items.enumerate() {
            itemContainerView.addSubview(item)
            item.accessibilityIdentifier = "Menu.\(item.menuTitleLabel.text)"

            // now properly lay out the cells
            let row:CGFloat = floor(CGFloat(index) / numberOfItemsInRow)
            let columnIndex = index - Int(row * numberOfItemsInRow)
            let columnMultiplier = CGFloat(columnIndex) / numberOfItemsInRow
            let rowOffset = row * rowHeight
            item.snp_makeConstraints { make in
                make.height.equalTo(rowHeight)
                make.width.equalTo(itemContainerView.snp_width).dividedBy(numberOfItemsInRow)
                if columnMultiplier > 0 {
                    make.left.equalTo(itemContainerView.snp_right).multipliedBy(columnMultiplier)
                } else {
                    make.left.equalTo(itemContainerView.snp_left)
                }
                make.top.equalTo(itemContainerView.snp_top).offset(rowOffset)
            }
        }
    }

    func setItems(items: [MenuItemView], forPageIndex index:Int) {
        self.items = items
        self.pageIndex = index
        self.setNeedsLayout()
    }

    func menuItemWasSelected(sender: MenuItemView) {
        print("Menu item selected")
        guard let selectedItemIndex = items.indexOf(sender) else { return }
        delegate?.menuPageView(self, didSelectMenuItem: sender, atIndexPath: NSIndexPath(forItem: selectedItemIndex, inSection: pageIndex))
    }

}
