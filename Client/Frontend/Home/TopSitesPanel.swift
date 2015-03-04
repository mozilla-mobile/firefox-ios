/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Storage

private let ThumbnailIdentifier = "Thumbnail"
private let RowIdentifier = "Row"
private let SeperatorKind = "seperator"
private let SeperatorIdentifier = "seperator"

class TopSitesPanel: UIViewController, UICollectionViewDelegate, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    var collection: UICollectionView!
    var datasource: TopSitesDataSource!
    let layout = TopSitesLayout()
    var profile: Profile! {
        didSet {
            profile.history.get(nil, complete: { (data) -> Void in
                self.datasource.data = data
                self.collection.reloadData()
            })
        }
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        layout.invalidateCaches()
        layout.setupForOrientation(toInterfaceOrientation)
        collection.setNeedsLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        datasource = TopSitesDataSource(data: Cursor(status: .Failure, msg: "Nothing loaded yet"))

        layout.registerClass(TopSitesSeperator.self, forDecorationViewOfKind: SeperatorKind)

        collection = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collection.backgroundColor = UIColor.whiteColor()
        collection.dataSource = datasource
        collection.delegate = self
        collection.registerClass(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailIdentifier)
        collection.registerClass(TopSitesRow.self, forCellWithReuseIdentifier: RowIdentifier)
        collection.keyboardDismissMode = .OnDrag
        view.addSubview(collection)
        collection.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let site = datasource.data[indexPath.item] as? Site {
            homePanelDelegate?.homePanel(self, didSelectURL: NSURL(string: site.url)!)
        }
    }
}

class TopSitesLayout: UICollectionViewLayout {
    var numRows: CGFloat = 3
    var numCols: CGFloat = 2
    let aspectRatio: CGFloat = 0.7

    var thumbWidth: CGFloat { return CGFloat(width / numCols) }
    var thumbHeight: CGFloat { return thumbWidth * aspectRatio }
    var count: Int {
        if let dataSource = self.collectionView?.dataSource as? TopSitesDataSource {
            return dataSource.data.count
        }
        return 0
    }
    var width: CGFloat { return self.collectionView?.frame.width ?? 0 }

    let ToolbarHeight: CGFloat = 44
    let StatusBarHeight: CGFloat = 20
    let RowHeight: CGFloat = 70

    var attrCache = [Int: UICollectionViewLayoutAttributes]()
    var thumbSecHeight: CGFloat { return width / numCols * numRows }

    override init() {
        super.init()
        setupForOrientation(UIApplication.sharedApplication().statusBarOrientation)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupForOrientation(orientation: UIInterfaceOrientation) {
        if orientation.isLandscape {
            numRows = 2
            numCols = 3
        } else {
            numRows = 3
            numCols = 2
        }
    }

    private func getIndexAtPosition(y: CGFloat) -> Int {
        if y < thumbSecHeight {
            let row = Int(y / thumbHeight)
            return min(count-1, max(0, row * Int(numCols)))
        }
        return min(count-1, max(0, Int((y - thumbSecHeight) / RowHeight + numRows * numCols)))
    }

    func invalidateCaches() {
        attrCache = [Int: UICollectionViewLayoutAttributes]()
    }

    override func collectionViewContentSize() -> CGSize {
        let c = CGFloat(count)
        let offset: CGFloat = ToolbarHeight + StatusBarHeight + CGFloat(ContainerHeight)

        if c <= numRows * numCols {
            let row = floor(Double(c / numCols))
        	return CGSize(width: width, height: CGFloat(row) * thumbHeight + offset)
        }

        let h = (c - numRows * numCols) * RowHeight
        return CGSize(width: width, height: numRows * thumbHeight + h + offset)
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        let start = getIndexAtPosition(rect.origin.y)
        let end = getIndexAtPosition(rect.origin.y + rect.height)

        var attrs = [UICollectionViewLayoutAttributes]()
        if start == -1 || end == -1 {
            return attrs
        }

        for i in start...end {
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            let attr = layoutAttributesForItemAtIndexPath(indexPath)
            attrs.append(attr)

            if CGFloat(i) >= (numRows * numCols)-1 {
                let decoration = layoutAttributesForDecorationViewOfKind(SeperatorKind, atIndexPath: indexPath)
                attrs.append(decoration)
            }
        }
        return attrs
    }

    override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let decoration = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)

        let h = ((CGFloat(indexPath.item + 1)) - numRows * numCols) * RowHeight
        decoration.frame = CGRect(x: 0,
            y: CGFloat(thumbHeight * numRows + h),
            width: width,
            height: 1)
        return decoration
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        if let cached = attrCache[indexPath.item] {
            return cached
        }

        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)

        let i = CGFloat(indexPath.item)
        if i < numRows * numCols {
            let row = floor(Double(i / numCols))
            let col = i % numCols
            attr.frame = CGRect(x: CGFloat(thumbWidth * col),
                y: CGFloat(row) * thumbHeight,
                width: thumbWidth,
                height: thumbHeight)
        } else {
            let h = CGFloat(i - numRows * numCols) * RowHeight
            attr.frame = CGRect(x: 0,
                y: CGFloat(thumbHeight * numRows + h),
                width: width,
                height: RowHeight)
        }

        attrCache[indexPath.item] = attr
        return attr
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}

class TopSitesDataSource: NSObject, UICollectionViewDataSource {
    var data: Cursor!

    init(data: Cursor) {
        self.data = data
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(RowIdentifier, forIndexPath: indexPath) as TopSitesRow
        if let site = data[indexPath.item] as? Site {
            if indexPath.item < 6 {
                var cell2 = collectionView.dequeueReusableCellWithReuseIdentifier(ThumbnailIdentifier, forIndexPath: indexPath) as ThumbnailCell
                cell2.textLabel.text = site.title
                cell.imageView.image = UIImage(named: "leaf")
                cell.imageView.contentMode = UIViewContentMode.Center
                return cell2
            } else {
                cell.textLabel.text = site.title
                cell.descriptionLabel.text = site.url
                if let icon = site.icon? {
                    cell.imageView.sd_setImageWithURL(NSURL(string: icon.url)!)
                } else {
                    cell.imageView.image = UIImage(named: "leaf")
                }
            }
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: SeperatorIdentifier, forIndexPath: indexPath) as UICollectionReusableView
    }
}

class TopSitesDelegate: NSObject, UICollectionViewDelegate {

}

