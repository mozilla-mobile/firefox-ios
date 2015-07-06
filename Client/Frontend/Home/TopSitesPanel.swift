/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

private let ThumbnailIdentifier = "Thumbnail"

struct TopSitesPanelUX {
    static let SuggestedTileImagePadding: CGFloat = 10
}

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
        println("\(data) \(json)")

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

class TopSitesPanel: UIViewController {
    weak var homePanelDelegate: HomePanelDelegate?

    private var collection: TopSitesCollectionView!
    private var dataSource: TopSitesDataSource!
    private let layout = TopSitesLayout()

    var editingThumbnails: Bool = false {
        didSet {
            if editingThumbnails != oldValue {
                dataSource.editingThumbnails = editingThumbnails

                if editingThumbnails {
                    homePanelDelegate?.homePanelWillEnterEditingMode?(self)
                }

                updateRemoveButtonStates()
            }
        }
    }

    var profile: Profile! {
        didSet {
            self.refreshHistory(self.layout.thumbnailCount)
        }
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        layout.setupForOrientation(toInterfaceOrientation)
        collection.setNeedsLayout()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "firefoxAccountChanged:", name: NotificationFirefoxAccountChanged, object: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = TopSitesDataSource(profile: profile, data: Cursor(status: .Failure, msg: "Nothing loaded yet"))

        collection = TopSitesCollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collection.backgroundColor = UIConstants.PanelBackgroundColor
        collection.delegate = self
        collection.dataSource = dataSource
        collection.registerClass(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailIdentifier)
        collection.keyboardDismissMode = .OnDrag
        view.addSubview(collection)
        collection.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
    }



    func firefoxAccountChanged(notification: NSNotification) {
        if notification.name == NotificationFirefoxAccountChanged {
            refreshHistory(self.layout.thumbnailCount)
        }
    }

    //MARK: Private Helpers
    private func updateDataSourceWithSites(result: Result<Cursor<Site>>) {
        if let data = result.successValue {
            self.dataSource.data = data
            self.dataSource.profile = self.profile
        }
    }

    private func updateRemoveButtonStates() {
        for i in 0..<layout.thumbnailCount {
            if let cell = collection.cellForItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0)) as? ThumbnailCell {
                //TODO: Only toggle the remove button for non-suggested tiles for now
                if i < dataSource.data.count {
                    cell.toggleRemoveButton(editingThumbnails)
                } else {
                    cell.toggleRemoveButton(false)
                }
            }
        }
    }

    private func deleteHistoryTileForURL(url: String, atIndexPath indexPath: NSIndexPath) {
        profile.history.removeHistoryForURL(url) >>== {
            self.profile.history.getSitesByFrecencyWithLimit(100).uponQueue(dispatch_get_main_queue(), block: { result in
                self.updateDataSourceWithSites(result)
                self.deleteOrUpdateSites(result, indexPath: indexPath)
            })
        }
    }

    private func refreshHistory(frequencyLimit: Int) {
        self.profile.history.getSitesByFrecencyWithLimit(frequencyLimit).uponQueue(dispatch_get_main_queue(), block: { result in
            self.updateDataSourceWithSites(result)
            self.collection.reloadData()
        })
    }

    private func deleteOrUpdateSites(result: Result<Cursor<Site>>, indexPath: NSIndexPath) {
        if let data = result.successValue {
            let numOfThumbnails = self.layout.thumbnailCount
            collection.performBatchUpdates({
                // If we have enough data to fill the tiles after the deletion, then delete and insert the next one from data
                if (data.count + self.dataSource.suggestedSites.count >= numOfThumbnails) {
                    self.collection.deleteItemsAtIndexPaths([indexPath])
                    self.collection.insertItemsAtIndexPaths([NSIndexPath(forItem: numOfThumbnails - 1, inSection: 0)])
                }

                // If we don't have enough to fill the thumbnail tile area even with suggested tiles, just delete
                else if (data.count + self.dataSource.suggestedSites.count) < numOfThumbnails {
                    self.collection.deleteItemsAtIndexPaths([indexPath])
                }
            }, completion: { _ in
                self.updateRemoveButtonStates()
            })
        }
    }
}

extension TopSitesPanel: HomePanel {
    func endEditing() {
        editingThumbnails = false
    }
}

extension TopSitesPanel: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if editingThumbnails {
            return
        }

        if let site = dataSource[indexPath.item] {
            // We're gonna call Top Sites bookmarks for now.
            let visitType = VisitType.Bookmark
            homePanelDelegate?.homePanel(self, didSelectURL: NSURL(string: site.url)!, visitType: visitType)
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let thumbnailCell = cell as? ThumbnailCell {
            thumbnailCell.delegate = self

            if editingThumbnails && indexPath.item < dataSource.data.count && thumbnailCell.removeButton.hidden {
                thumbnailCell.removeButton.hidden = false
            }
        }
    }
}

extension TopSitesPanel: ThumbnailCellDelegate {
    func didRemoveThumbnail(thumbnailCell: ThumbnailCell) {
        if let indexPath = collection.indexPathForCell(thumbnailCell) {
            let site = dataSource[indexPath.item]
            if let url = site?.url {
                self.deleteHistoryTileForURL(url, atIndexPath: indexPath)
            }
        }
        
    }

    func didLongPressThumbnail(thumbnailCell: ThumbnailCell) {
        editingThumbnails = true
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
    private var thumbnailRows: Int {
        return Int((self.collectionView?.frame.height ?? 100) / self.thumbnailHeight)
    }

    private var thumbnailCols = 2
    private var thumbnailCount: Int { return thumbnailRows * thumbnailCols }
    private var width: CGFloat { return self.collectionView?.frame.width ?? 0 }

    // The width and height of the thumbnail here are the width and height of the tile itself, not the image inside the tile.
    private var thumbnailWidth: CGFloat { return (width - ThumbnailCellUX.Insets.left - ThumbnailCellUX.Insets.right) / CGFloat(thumbnailCols) }
    // The tile's height is determined the aspect ratio of the thumbnails width. We also take into account
    // some padding between the title and the image.
    private var thumbnailHeight: CGFloat { return thumbnailWidth / CGFloat(ThumbnailCellUX.ImageAspectRatio) }

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
            thumbnailCols = 3
        } else {
            thumbnailCols = 2
        }
    }

    private func getIndexAtPosition(#y: CGFloat) -> Int {
        if y < topSectionHeight {
            let row = Int(y / thumbnailHeight)
            return min(count - 1, max(0, row * thumbnailCols))
        }
        return min(count - 1, max(0, Int((y - topSectionHeight) / UIConstants.DefaultRowHeight + CGFloat(thumbnailCount))))
    }

    override func collectionViewContentSize() -> CGSize {
        if count <= thumbnailCount {
            let row = floor(Double(count / thumbnailCols))
            return CGSize(width: width, height: topSectionHeight)
        }

        let bottomSectionHeight = CGFloat(count - thumbnailCount) * UIConstants.DefaultRowHeight
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
        }
        return attrs
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)

        // Set the top thumbnail frames.
        let row = floor(Double(indexPath.item / thumbnailCols))
        let col = indexPath.item % thumbnailCols
        let x = ThumbnailCellUX.Insets.left + thumbnailWidth * CGFloat(col)
        let y = ThumbnailCellUX.Insets.top + CGFloat(row) * thumbnailHeight
        attr.frame = CGRectMake(x, y, thumbnailWidth, thumbnailHeight)

        return attr
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}

private class TopSitesDataSource: NSObject, UICollectionViewDataSource {
    var data: Cursor<Site>
    var profile: Profile
    var editingThumbnails: Bool = false

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
            return min(data.count + suggestedSites.count, layout.thumbnailCount)
        }

        return 0
    }

    private func setDefaultThumbnailBackground(cell: ThumbnailCell) {
        cell.imageView.image = UIImage(named: "defaultFavicon")!
        cell.imageView.contentMode = UIViewContentMode.Center
    }

    private func createTileForSite(cell: ThumbnailCell, site: Site) -> ThumbnailCell {
        cell.textLabel.text = site.title.isEmpty ? site.url : site.title
        cell.imageWrapper.backgroundColor = UIColor.clearColor()

        cell.imageView.sd_setImageWithURL(site.icon?.url.asURL!, completed: { (img, err, type, url) -> Void in
            if let img = img {
                cell.backgroundImage.image = img
            } else {
                cell.backgroundImage.image = nil
            }
        })

        cell.imagePadding = TopSitesPanelUX.SuggestedTileImagePadding
        cell.accessibilityLabel = cell.textLabel.text
        cell.removeButton.hidden = !editingThumbnails
        return cell
    }

    private func createTileForSuggestedSite(cell: ThumbnailCell, tile: Tile) -> ThumbnailCell {
        cell.textLabel.text = tile.title.isEmpty ? tile.url : tile.title
        cell.imageWrapper.backgroundColor = tile.backgroundColor
        cell.backgroundImage.image = nil

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

        cell.imagePadding = TopSitesPanelUX.SuggestedTileImagePadding
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = cell.textLabel.text

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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThumbnailIdentifier, forIndexPath: indexPath) as! ThumbnailCell

        if indexPath.item >= data.count {
            return createTileForSuggestedSite(cell, tile: site as! Tile)
        }
        return createTileForSite(cell, site: site)
    }
}
