/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

private let ThumbnailIdentifier = "Thumbnail"
private let RowIdentifier = "Row"
private let SeparatorKind = "separator"
private let SeparatorIdentifier = "separator"
private let SeparatorColor = UIColor(rgb: 0xffffff)

class Tile: Site {
    let backgroundColor: UIColor
    let trackingId: Int

    init(url: String, color: UIColor, image: String, trackingId: Int, title: String) {
        self.backgroundColor = color
        self.trackingId = trackingId
        super.init(url: url, title: title)
        self.icon = Favicon(url: image, date: NSDate(), type: IconType.Icon)
    }

    init(json: JSON) {
        let colorString = json["bgcolor"].asString!
        var colorInt: UInt32 = 0
        NSScanner(string: colorString).scanHexInt(&colorInt)
        self.backgroundColor = UIColor(rgb: (Int) (colorInt ?? 0xaaaaaa))
        self.trackingId = json["trackingid"].asInt ?? 0

        super.init(url: json["url"].asString!, title: json["title"].asString!)

        self.icon = Favicon(url: json["imageurl"].asString!, date: NSDate(), type: .Icon)
    }
}

private class SuggestedSitesData<T: Tile>: Cursor<T> {
    var tiles = [T]()

    init() {
        // TODO: Make this list localized. That should be as simple as making sure its in the lproj directory.
        var err: NSError? = nil
        let path = NSBundle.mainBundle().pathForResource("suggestedsites", ofType: "json")
        let data = NSString(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: &err)
        let json = JSON.parse(data as! String)

        for i in 0..<json.length {
            let t = T(json: json[i])
            tiles.append(t)
        }
    }

    override var count: Int {
        return tiles.count
    }

    override subscript(index: Int) -> T? {
        get {
            return tiles[index]
        }
    }
}

class TopSitesPanel: UIViewController, UICollectionViewDelegate, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?

    private var collection: TopSitesCollectionView!
    private var dataSource: TopSitesDataSource!
    private let layout = TopSitesLayout()

    var profile: Profile! {
        didSet {
            // This needs to run on the main thread so that our dataSource is ready.
            profile.history.getSitesByFrecencyWithLimit(100).uponQueue(dispatch_get_main_queue()) { result in
                if let data = result.successValue {
                    self.dataSource.data = data
                    self.dataSource.profile = self.profile
                    self.collection.reloadData()
                }
                // TODO: error handling.
            }
        }
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        layout.setupForOrientation(toInterfaceOrientation)
        collection.setNeedsLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = TopSitesDataSource(profile: profile, data: Cursor(status: .Failure, msg: "Nothing loaded yet"))

        layout.registerClass(TopSitesSeparator.self, forDecorationViewOfKind: SeparatorKind)

        collection = TopSitesCollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collection.backgroundColor = AppConstants.PanelBackgroundColor
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
        if let site = dataSource[indexPath.item] {
            // We're gonna call Top Sites bookmarks for now.
            let visitType = VisitType.Bookmark
            homePanelDelegate?.homePanel(self, didSelectURL: NSURL(string: site.url)!, visitType: visitType)
        }
    }
}

private class TopSitesCollectionView: UICollectionView {
    private override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // Hide the keyboard if this view is touched.
        window?.rootViewController?.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
}

private class TopSitesLayout: UICollectionViewLayout {
    private var thumbnailRows = 3
    private var thumbnailCols = 2
    private var thumbnailCount: Int { return thumbnailRows * thumbnailCols }
    private var width: CGFloat { return self.collectionView?.frame.width ?? 0 }

    // The width and height of the thumbnail here are the width and height of the tile itself, not the image inside the tile.
    private var thumbnailWidth: CGFloat { return (width - ThumbnailCellUX.Insets.left - ThumbnailCellUX.Insets.right) / CGFloat(thumbnailCols) }
    // The tile's height is determined the aspect ratio of the thumbnails width + the height of the text label on the bottom. We also take into account
    // some padding between the title and the image.
    private var thumbnailHeight: CGFloat { return thumbnailWidth / CGFloat(ThumbnailCellUX.ImageAspectRatio) + CGFloat(ThumbnailCellUX.TextSize) + CGFloat(ThumbnailCellUX.Insets.bottom) + CGFloat(ThumbnailCellUX.TextOffset) }

    // Used to calculate the height of the list.
    private var count: Int {
        if let dataSource = self.collectionView?.dataSource as? TopSitesDataSource {
            return dataSource.collectionView(self.collectionView!, numberOfItemsInSection: 0)
        }
        return 0
    }

    private var topSectionHeight: CGFloat {
        let maxRows = ceil(Float(count) / Float(thumbnailCols))
        let rows = min(Int(maxRows), thumbnailRows)
        return thumbnailHeight * CGFloat(rows) + ThumbnailCellUX.Insets.top + ThumbnailCellUX.Insets.bottom
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
            thumbnailRows = 2
            thumbnailCols = 3
        } else {
            thumbnailRows = 3
            thumbnailCols = 2
        }
    }

    private func getIndexAtPosition(#y: CGFloat) -> Int {
        if y < topSectionHeight {
            let row = Int(y / thumbnailHeight)
            return min(count - 1, max(0, row * thumbnailCols))
        }
        return min(count - 1, max(0, Int((y - topSectionHeight) / AppConstants.DefaultRowHeight + CGFloat(thumbnailCount))))
    }

    override func collectionViewContentSize() -> CGSize {
        if count <= thumbnailCount {
            let row = floor(Double(count / thumbnailCols))
            return CGSize(width: width, height: topSectionHeight)
        }

        let bottomSectionHeight = CGFloat(count - thumbnailCount) * AppConstants.DefaultRowHeight
        return CGSize(width: width, height: topSectionHeight + bottomSectionHeight)
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

            if i >= thumbnailCount - 1 {
                let decoration = layoutAttributesForDecorationViewOfKind(SeparatorKind, atIndexPath: indexPath)
                attrs.append(decoration)
            }
        }
        return attrs
    }

    // Set the frames for the row separators.
    override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let rowIndex = indexPath.item - thumbnailCount + 1
        let rowYOffset = CGFloat(rowIndex) * AppConstants.DefaultRowHeight
        let y = topSectionHeight + rowYOffset

        let decoration = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)
        decoration.frame = CGRectMake(0, y, width, 0.5)
        return decoration
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)

        let i = indexPath.item
        if i < thumbnailCount {
            // Set the top thumbnail frames.
            let row = floor(Double(i / thumbnailCols))
            let col = i % thumbnailCols
            let x = ThumbnailCellUX.Insets.left + thumbnailWidth * CGFloat(col)
            let y = ThumbnailCellUX.Insets.top + CGFloat(row) * thumbnailHeight
            attr.frame = CGRectMake(x, y, thumbnailWidth, thumbnailHeight)
        } else {
            // Set the bottom row frames.
            let rowYOffset = CGFloat(i - thumbnailCount) * AppConstants.DefaultRowHeight
            let y = CGFloat(topSectionHeight + rowYOffset)
            attr.frame = CGRectMake(0, y, width, AppConstants.DefaultRowHeight)
        }

        return attr
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}

private class TopSitesDataSource: NSObject, UICollectionViewDataSource {
    var data: Cursor<Site>
    var profile: Profile
    lazy var suggestedSites: SuggestedSitesData<Tile> = {
        return SuggestedSitesData<Tile>()
    }()

    init(profile: Profile, data: Cursor<Site>) {
        self.data = data
        self.profile = profile
    }

    @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if data.status != .Success {
            return 0
        }

        // If there aren't enough data items to fill the grid, look for items in suggested sites.
        if let layout = collectionView.collectionViewLayout as? TopSitesLayout {
            if data.count < layout.thumbnailCount {
                return min(data.count + suggestedSites.count, layout.thumbnailCount)
            }
        }
        return data.count
    }

    private func setDefaultThumbnailBackground(cell: ThumbnailCell) {
        cell.imageView.image = UIImage(named: "defaultFavicon")!
        cell.imageView.contentMode = UIViewContentMode.Center
    }

    private func createTileForSite(cell: ThumbnailCell, site: Site) -> ThumbnailCell {
        cell.textLabel.text = site.title.isEmpty ? site.url : site.title
        cell.imageWrapper.backgroundColor = UIColor.clearColor()
        // cell.backgroundColor = UIColor.random()

        if let thumbs = profile.thumbnails as? SDWebThumbnails {
            let key = SDWebThumbnails.getKey(site.url)
            cell.imageView.moz_getImageFromCache(key, cache: thumbs.cache, completed: { img, err, type, key in
                if img == nil { self.setDefaultThumbnailBackground(cell) }
            })
        } else {
            setDefaultThumbnailBackground(cell)
        }
        cell.imagePadding = 0
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = cell.textLabel.text
        return cell
    }

    private func createTileForSuggestedSite(cell: ThumbnailCell, tile: Tile) -> ThumbnailCell {
        cell.textLabel.text = tile.title.isEmpty ? tile.url : tile.title
        cell.imageWrapper.backgroundColor = tile.backgroundColor

        if let iconString = tile.icon?.url {
            let icon = NSURL(string: iconString)!
            if icon.scheme == "asset" {
                cell.imageView.image = UIImage(named: icon.host!)
            } else {
                cell.imageView.sd_setImageWithURL(icon, completed: { img, err, type, key in
                    if img == nil {
                        self.setDefaultThumbnailBackground(cell)
                    }
                })
            }
        } else {
            self.setDefaultThumbnailBackground(cell)
        }

        cell.imagePadding = 10
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = cell.textLabel.text
        return cell
    }

    private func createListCell(cell: TwoLineCollectionViewCell, site: Site) -> TwoLineCollectionViewCell {
        cell.textLabel.text = site.title.isEmpty ? site.url : site.title
        cell.detailTextLabel.text = site.url
        cell.mergeAccessibilityLabels()
        if let icon = site.icon {
            cell.imageView.sd_setImageWithURL(NSURL(string: icon.url)!)
        } else {
            cell.imageView.image = ThumbnailCellUX.PlaceholderImage
        }
        return cell
    }

    subscript(index: Int) -> Site? {
        if data.status != .Success {
            return nil
        }

        if index >= data.count {
            return suggestedSites[index - data.count]
        }
        return data[index] as Site?
    }

    @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Cells for the top site thumbnails.
        let site = self[indexPath.item]!

        if let layout = collectionView.collectionViewLayout as? TopSitesLayout {
            if indexPath.item < layout.thumbnailCount {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThumbnailIdentifier, forIndexPath: indexPath) as! ThumbnailCell

                if indexPath.item >= data.count {
                    return createTileForSuggestedSite(cell, tile: site as! Tile)
                }
                return createTileForSite(cell, site: site)
            }
        }

        // Cells for the remainder of the top sites list.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(RowIdentifier, forIndexPath: indexPath) as! TwoLineCollectionViewCell
        return createListCell(cell, site: site)
    }
    
    @objc func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: SeparatorIdentifier, forIndexPath: indexPath) as! UICollectionReusableView
    }
}

private class TopSitesSeparator: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = SeparatorColor
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
