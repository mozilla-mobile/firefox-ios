/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Storage

private let ThumbnailIdentifier = "Thumbnail"
private let RowIdentifier = "Row"
private let SeparatorKind = "separator"
private let SeparatorIdentifier = "separator"
private let DefaultImage = "defaultFavicon"

class TopSitesPanel: UIViewController, UICollectionViewDelegate, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?

    private var collection: UICollectionView!
    private var dataSource: TopSitesDataSource!
    private let layout = TopSitesLayout()

    var profile: Profile! {
        didSet {
            profile.history.get(nil, complete: { (data) -> Void in
                self.dataSource.data = data
                self.collection.reloadData()
            })
        }
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        layout.setupForOrientation(toInterfaceOrientation)
        collection.setNeedsLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = TopSitesDataSource(data: Cursor(status: .Failure, msg: "Nothing loaded yet"))

        layout.registerClass(TopSitesSeparator.self, forDecorationViewOfKind: SeparatorKind)

        collection = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collection.backgroundColor = UIColor.whiteColor()
        collection.delegate = self
        collection.dataSource = dataSource
        collection.registerClass(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailIdentifier)
        collection.registerClass(TwoLineCollectionViewCell.self, forCellWithReuseIdentifier: RowIdentifier)
        collection.keyboardDismissMode = .OnDrag
        view.addSubview(collection)
        collection.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let site = dataSource?.data[indexPath.item] as? Site {
            homePanelDelegate?.homePanel(self, didSelectURL: NSURL(string: site.url)!)
        }
    }
}

private class TopSitesLayout: UICollectionViewLayout {
    private let ToolbarHeight: CGFloat = 44
    private let StatusBarHeight: CGFloat = 20
    private let RowHeight: CGFloat = 58
    private let AspectRatio: CGFloat = 0.7

    private var numRows: CGFloat = 3
    private var numCols: CGFloat = 2
    private var width: CGFloat { return self.collectionView?.frame.width ?? 0 }
    private var thumbnailWidth: CGFloat { return CGFloat(width / numCols) }
    private var thumbnailHeight: CGFloat { return thumbnailWidth * AspectRatio }

    private var count: Int {
        if let dataSource = self.collectionView?.dataSource as? TopSitesDataSource {
            return dataSource.data.count
        }
        return 0
    }

    override init() {
        super.init()
        setupForOrientation(UIApplication.sharedApplication().statusBarOrientation)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupForOrientation(orientation: UIInterfaceOrientation) {
        if orientation.isLandscape {
            numRows = 2
            numCols = 3
        } else {
            numRows = 3
            numCols = 2
        }
    }

    private func getIndexAtPosition(#y: CGFloat) -> Int {
        let thumbnailSectionHeight: CGFloat = thumbnailWidth * numRows

        if y < thumbnailSectionHeight {
            let row = Int(y / thumbnailHeight)
            return min(count - 1, max(0, row * Int(numCols)))
        }
        return min(count - 1, max(0, Int((y - thumbnailSectionHeight) / RowHeight + numRows * numCols)))
    }

    override func collectionViewContentSize() -> CGSize {
        let c = CGFloat(count)
        let offset: CGFloat = ToolbarHeight + StatusBarHeight + HomePanelButtonContainerHeight

        if c <= numRows * numCols {
            let row = floor(Double(c / numCols))
            return CGSize(width: width, height: CGFloat(row) * thumbnailHeight + offset)
        }

        let h = (c - numRows * numCols) * RowHeight
        return CGSize(width: width, height: numRows * thumbnailHeight + h + offset)
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        let start = getIndexAtPosition(y: rect.origin.y)
        let end = getIndexAtPosition(y: rect.origin.y + rect.height)

        var attrs = [UICollectionViewLayoutAttributes]()
        if start == -1 || end == -1 {
            return attrs
        }

        for i in start...end {
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            let attr = layoutAttributesForItemAtIndexPath(indexPath)
            attrs.append(attr)

            if CGFloat(i) >= (numRows * numCols) - 1 {
                let decoration = layoutAttributesForDecorationViewOfKind(SeparatorKind, atIndexPath: indexPath)
                attrs.append(decoration)
            }
        }
        return attrs
    }

    override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let decoration = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)

        let h = ((CGFloat(indexPath.item + 1)) - numRows * numCols) * RowHeight
        decoration.frame = CGRect(x: 0,
            y: CGFloat(thumbnailHeight * numRows + h),
            width: width,
            height: 1)
        return decoration
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)

        let i = CGFloat(indexPath.item)
        if i < numRows * numCols {
            let row = floor(Double(i / numCols))
            let col = i % numCols
            attr.frame = CGRect(x: CGFloat(thumbnailWidth * col),
                y: CGFloat(row) * thumbnailHeight,
                width: thumbnailWidth,
                height: thumbnailHeight)
        } else {
            let h = CGFloat(i - numRows * numCols) * RowHeight
            attr.frame = CGRect(x: 0,
                y: CGFloat(thumbnailHeight * numRows + h),
                width: width,
                height: RowHeight)
        }

        return attr
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}

private class TopSitesDataSource: NSObject, UICollectionViewDataSource {
    var data: Cursor

    init(data: Cursor) {
        self.data = data
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let site = data[indexPath.item] as Site

        // Cells for the top site thumbnails.
        if indexPath.item < 6 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThumbnailIdentifier, forIndexPath: indexPath) as ThumbnailCell
            cell.textLabel.text = site.title.isEmpty ? site.url : site.title
            cell.imageView.image = UIImage(named: DefaultImage)
            cell.imageView.contentMode = UIViewContentMode.Center
            return cell
        }

        // Cells for the remainder of the top sites list.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(RowIdentifier, forIndexPath: indexPath) as TwoLineCollectionViewCell
        cell.textLabel.text = site.title.isEmpty ? site.url : site.title
        cell.detailTextLabel.text = site.url
        if let icon = site.icon? {
            cell.imageView.sd_setImageWithURL(NSURL(string: icon.url)!)
        } else {
            cell.imageView.image = UIImage(named: DefaultImage)
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: SeparatorIdentifier, forIndexPath: indexPath) as UICollectionReusableView
    }
}

private class TopSitesSeparator: UICollectionReusableView {
    override init() {
        super.init()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = SeparatorColor
    }

    required init(coder aDecoder: NSCoder) {
        assertionFailure("Not implemented")
    }
}
