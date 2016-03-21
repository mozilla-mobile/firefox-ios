/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol MenuPageViewControllerDelegate: class {
    func menuPageViewController(menuPageViewController: MenuPageViewController, didSelectMenuItem menuItem: MenuItemView, atIndexPath indexPath: NSIndexPath)
}

public class MenuPageViewController: UIViewController {

    weak var delegate: MenuPageViewControllerDelegate?
    public private(set) var pageIndex: Int = 0
    public var numberOfItemsInRow:CGFloat = 0
    public var itemPadding: CGFloat = 0
    public var menuRowHeight: CGFloat = 0
    public var backgroundColor: UIColor = UIColor.clearColor() {
        didSet {
            view.backgroundColor = backgroundColor
        }
    }

    private let itemContainerView = UIView()
    private var items = [MenuItemView]()

    private var numberOfRows:CGFloat = 0
    private var rowHeight: CGFloat = 0

    var height: CGFloat {
        return itemPadding + (numberOfRows * (menuRowHeight + itemPadding))
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.addSubview(itemContainerView)
        numberOfRows = ceil(CGFloat(items.count) / numberOfItemsInRow)

        itemContainerView.restorationIdentifier = "ItemContainerView"
        itemContainerView.accessibilityIdentifier = "Menu.ItemContainerView"
        itemContainerView.snp_makeConstraints { make in
            make.edges.equalTo(view)
        }


    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        rowHeight = height / CGFloat(numberOfRows)

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

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setItems(items: [MenuItemView], forPageIndex index:Int) {
        self.items = items
        self.pageIndex = index
    }

    func menuItemWasSelected(sender: MenuItemView) {
        print("Menu item selected")
        guard let selectedItemIndex = items.indexOf(sender) else { return }
        delegate?.menuPageViewController(self, didSelectMenuItem: sender, atIndexPath: NSIndexPath(forItem: selectedItemIndex, inSection: pageIndex))
    }

}
