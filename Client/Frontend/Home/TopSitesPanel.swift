/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import XCGLogger
import Storage

private let log = Logger.browserLogger

private let ThumbnailIdentifier = "Thumbnail"

extension UIView {
    public class func viewOrientationForSize(size: CGSize) -> UIInterfaceOrientation {
        return size.width > size.height ? UIInterfaceOrientation.LandscapeRight : UIInterfaceOrientation.Portrait
    }
}

class TopSitesPanel: UIViewController {
    weak var homePanelDelegate: HomePanelDelegate?

    private var collection: TopSitesCollectionView? = nil
    private lazy var dataSource: TopSitesDataSource = {
        return TopSitesDataSource(profile: self.profile, data: Cursor(status: .Failure, msg: "Nothing loaded yet"))
    }()
    private lazy var layout: TopSitesLayout = { return TopSitesLayout() }()

    private lazy var maxFrecencyLimit: Int = {
        return max(
            self.calculateApproxThumbnailCountForOrientation(UIInterfaceOrientation.LandscapeLeft),
            self.calculateApproxThumbnailCountForOrientation(UIInterfaceOrientation.Portrait)
        )
    }()

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

    let profile: Profile

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.layout.setupForOrientation(UIView.viewOrientationForSize(size))
        self.collection?.reloadData()
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
    }

    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notificationReceived:", name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notificationReceived:", name: NotificationPrivateDataClearedHistory, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let collection = TopSitesCollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collection.backgroundColor = UIConstants.PanelBackgroundColor
        collection.delegate = self
        collection.dataSource = dataSource
        collection.registerClass(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailIdentifier)
        collection.keyboardDismissMode = .OnDrag
        view.addSubview(collection)
        collection.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.collection = collection
        self.refreshHistory(maxFrecencyLimit)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationPrivateDataClearedHistory, object: nil)
    }
    
    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory:
            refreshHistory(maxFrecencyLimit)
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    //MARK: Private Helpers
    private func updateDataSourceWithSites(result: Maybe<Cursor<Site>>) {
        if let data = result.successValue {
            self.dataSource.data = data
            self.dataSource.profile = self.profile

            // redraw now we've udpated our sources
            self.collection?.collectionViewLayout.invalidateLayout()
            self.collection?.setNeedsLayout()
        }
    }

    private func updateRemoveButtonStates() {
        for i in 0..<layout.thumbnailCount {
            if let cell = collection?.cellForItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0)) as? ThumbnailCell {
                //TODO: Only toggle the remove button for non-suggested tiles for now
                if i < dataSource.data.count {
                    cell.toggleRemoveButton(editingThumbnails)
                } else {
                    cell.toggleRemoveButton(false)
                }
            }
        }
    }

    private func deleteHistoryTileForSite(site: Site, atIndexPath indexPath: NSIndexPath) {
        profile.history.removeSiteFromTopSites(site) >>== {
            self.profile.history.getSitesByFrecencyWithLimit(self.layout.thumbnailCount).uponQueue(dispatch_get_main_queue(), block: { result in
                self.deleteOrUpdateSites(result, indexPath: indexPath)
            })
        }
    }

    private func refreshHistory(frequencyLimit: Int) {
        self.profile.history.getSitesByFrecencyWithLimit(frequencyLimit).uponQueue(dispatch_get_main_queue(), block: { result in
            self.updateDataSourceWithSites(result)
            self.collection?.reloadData()
        })
    }

    private func deleteOrUpdateSites(result: Maybe<Cursor<Site>>, indexPath: NSIndexPath) {
        guard let collectionView = collection else { return }
        // get the number of top sites items we have before we update the data sourcce 
        // this is so we know how many new top sites cells to add
        // as a sync may have brought in more results than we had previously
        let previousNumberOfTopSitesItems = collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0) ?? 0

        // now update the data source with the new data
        self.updateDataSourceWithSites(result)

        let data = dataSource.data
        let numOfThumbnails = self.layout.thumbnailCount
        collection?.performBatchUpdates({
            // If we have enough data to fill the tiles after the deletion, then delete and insert the next one from data
            if (data.count + SuggestedSites.count >= numOfThumbnails) {
                self.collection?.deleteItemsAtIndexPaths([indexPath])
                self.collection?.dataSource?.collectionView(self.collection!, numberOfItemsInSection: 0)
                let indexesToAdd = (previousNumberOfTopSitesItems-1..<numOfThumbnails).map{ NSIndexPath(forItem: $0, inSection: 0) }
                self.collection?.insertItemsAtIndexPaths(indexesToAdd)
            }
            // If we don't have enough to fill the thumbnail tile area even with suggested tiles, just delete
            else if (data.count + SuggestedSites.count) < numOfThumbnails {
                self.collection?.deleteItemsAtIndexPaths([indexPath])
            }
        }, completion: { _ in
            self.updateRemoveButtonStates()
        })
    }

    /**
    Calculates an approximation of the number of tiles we want to display for the given orientation. This
    method uses the screen's size as it's basis for the calculation instead of the collectionView's since the 
    collectionView's bounds is determined until the next layout pass.

    - parameter orientation: Orientation to calculate number of tiles for

    - returns: Rough tile count we will be displaying for the passed in orientation
    */
    private func calculateApproxThumbnailCountForOrientation(orientation: UIInterfaceOrientation) -> Int {
        let size = UIScreen.mainScreen().bounds.size
        let portraitSize = CGSize(width: min(size.width, size.height), height: max(size.width, size.height))

        func calculateRowsForSize(size: CGSize, columns: Int) -> Int {
            let insets = ThumbnailCellUX.Insets
            let thumbnailWidth = (size.width - insets.left - insets.right) / CGFloat(columns)
            let thumbnailHeight = thumbnailWidth / CGFloat(ThumbnailCellUX.ImageAspectRatio)
            return max(2, Int(size.height / thumbnailHeight))
        }

        let numberOfColumns: Int
        let numberOfRows: Int

        if UIInterfaceOrientationIsLandscape(orientation) {
            numberOfColumns = 5
            numberOfRows = calculateRowsForSize(CGSize(width: portraitSize.height, height: portraitSize.width), columns: numberOfColumns)
        } else {
            numberOfColumns = 4
            numberOfRows = calculateRowsForSize(portraitSize, columns: numberOfColumns)
        }

        return numberOfColumns * numberOfRows
    }
}

extension TopSitesPanel: HomePanel {
    func endEditing() {
        editingThumbnails = false

        collection?.reloadData()
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
            let destination = NSURL(string: site.url)?.domainURL() ?? NSURL(string: "about:blank")!
            homePanelDelegate?.homePanel(self, didSelectURL: destination, visitType: visitType)
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
        if let indexPath = collection?.indexPathForCell(thumbnailCell) {
            if let site = dataSource[indexPath.item] {
                self.deleteHistoryTileForSite(site, atIndexPath: indexPath)
            }
        }
        
    }

    func didLongPressThumbnail(thumbnailCell: ThumbnailCell) {
        editingThumbnails = true
    }
}

private class TopSitesCollectionView: UICollectionView {
    private override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Hide the keyboard if this view is touched.
        window?.rootViewController?.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
}

private class TopSitesLayout: UICollectionViewLayout {
    private var thumbnailRows: Int {
        return max(2, Int((self.collectionView?.frame.height ?? self.thumbnailHeight) / self.thumbnailHeight))
    }

    private var thumbnailCols = 2
    private var thumbnailCount: Int {
        return thumbnailRows * thumbnailCols
    }
    private var width: CGFloat { return self.collectionView?.frame.width ?? 0 }

    // The width and height of the thumbnail here are the width and height of the tile itself, not the image inside the tile.
    private var thumbnailWidth: CGFloat {
        let insets = ThumbnailCellUX.Insets
        return (width - insets.left - insets.right) / CGFloat(thumbnailCols) }
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
        let insets = ThumbnailCellUX.Insets
        return thumbnailHeight * CGFloat(rows) + insets.top + insets.bottom
    }

    override init() {
        super.init()
        setupForOrientation(UIApplication.sharedApplication().statusBarOrientation)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupForOrientation(orientation: UIInterfaceOrientation) {
        if orientation.isLandscape {
            thumbnailCols = 5
        } else if UIScreen.mainScreen().traitCollection.horizontalSizeClass == .Compact {
            thumbnailCols = 3
        } else {
            thumbnailCols = 4
        }
    }

    private func getIndexAtPosition(y: CGFloat) -> Int {
        if y < topSectionHeight {
            let row = Int(y / thumbnailHeight)
            return min(count - 1, max(0, row * thumbnailCols))
        }
        return min(count - 1, max(0, Int((y - topSectionHeight) / UIConstants.DefaultRowHeight + CGFloat(thumbnailCount))))
    }

    override func collectionViewContentSize() -> CGSize {
        if count <= thumbnailCount {
            return CGSize(width: width, height: topSectionHeight)
        }

        let bottomSectionHeight = CGFloat(count - thumbnailCount) * UIConstants.DefaultRowHeight
        return CGSize(width: width, height: topSectionHeight + bottomSectionHeight)
    }

    private var layoutAttributes:[UICollectionViewLayoutAttributes]?

    private override func prepareLayout() {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for section in 0..<(self.collectionView?.numberOfSections() ?? 0) {
            for item in 0..<(self.collectionView?.numberOfItemsInSection(section) ?? 0) {
                let indexPath = NSIndexPath(forItem: item, inSection: section)
                guard let attrs = self.layoutAttributesForItemAtIndexPath(indexPath) else { continue }
                layoutAttributes.append(attrs)
            }
        }
        self.layoutAttributes = layoutAttributes
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attrs = [UICollectionViewLayoutAttributes]()
        if let layoutAttributes = self.layoutAttributes {
            for attr in layoutAttributes {
                if CGRectIntersectsRect(rect, attr.frame) {
                    attrs.append(attr)
                }
            }
        }

        return attrs
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)

        // Set the top thumbnail frames.
        let row = floor(Double(indexPath.item / thumbnailCols))
        let col = indexPath.item % thumbnailCols
        let insets = ThumbnailCellUX.Insets
        let x = insets.left + thumbnailWidth * CGFloat(col)
        let y = insets.top + CGFloat(row) * thumbnailHeight
        attr.frame = CGRectMake(ceil(x), ceil(y), thumbnailWidth, thumbnailHeight)

        return attr
    }
}

private class TopSitesDataSource: NSObject, UICollectionViewDataSource {
    var data: Cursor<Site>
    var profile: Profile
    var editingThumbnails: Bool = false

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
            return min(data.count + SuggestedSites.count, layout.thumbnailCount)
        }

        return 0
    }

    private func setDefaultThumbnailBackground(cell: ThumbnailCell) {
        cell.imageView.image = UIImage(named: "defaultTopSiteIcon")!
        cell.imageView.contentMode = UIViewContentMode.Center
    }

    private func getFavicon(cell: ThumbnailCell, site: Site) {
        self.setDefaultThumbnailBackground(cell)

        if let url = site.url.asURL {
            FaviconFetcher.getForURL(url, profile: profile) >>== { icons in
                if (icons.count > 0) {
                    cell.imageView.sd_setImageWithURL(icons[0].url.asURL!) { (img, err, type, url) -> Void in
                        if let img = img {
                            cell.backgroundImage.image = img
                            cell.backgroundEffect?.alpha = 1
                            cell.image = img
                        } else {
                            let icon = Favicon(url: "", date: NSDate(), type: IconType.NoneFound)
                            self.profile.favicons.addFavicon(icon, forSite: site)
                            self.setDefaultThumbnailBackground(cell)
                        }
                    }
                }
            }
        }
    }

    private func createTileForSite(cell: ThumbnailCell, site: Site) -> ThumbnailCell {

        // We always want to show the domain URL, not the title.
        //
        // Eventually we can do something more sophisticated — e.g., if the site only consists of one
        // history item, show it, and otherwise use the longest common sub-URL (and take its title
        // if you visited that exact URL), etc. etc. — but not yet.
        //
        // The obvious solution here and in collectionView:didSelectItemAtIndexPath: is for the cursor
        // to return domain sites, not history sites -- that is, with the right icon, title, and URL --
        // and for this code to just use what it gets.
        //
        // Instead we'll painstakingly re-extract those things here.

        let domainURL = NSURL(string: site.url)?.host ?? site.url
        cell.textLabel.text = domainURL
        cell.imageWrapper.backgroundColor = UIColor.clearColor()

        // Resets used cell's background image so that it doesn't get recycled when a tile doesn't update its background image.
        cell.backgroundImage.image = nil
        cell.backgroundEffect?.alpha = 0

        if let icon = site.icon {
            // We've looked before recently and didn't find a favicon
            switch icon.type {
            case .NoneFound where NSDate().timeIntervalSinceDate(icon.date) < FaviconFetcher.ExpirationTime:
                self.setDefaultThumbnailBackground(cell)
            default:
                cell.imageView.sd_setImageWithURL(icon.url.asURL, completed: { (img, err, type, url) -> Void in
                    if let img = img {
                        cell.backgroundImage.image = img
                        cell.backgroundEffect?.alpha = 1
                        cell.image = img
                    } else {
                        self.getFavicon(cell, site: site)
                    }
                })
            }
        } else {
            getFavicon(cell, site: site)
        }

        cell.isAccessibilityElement = true
        cell.accessibilityLabel = cell.textLabel.text
        cell.removeButton.hidden = !editingThumbnails
        return cell
    }

    private func createTileForSuggestedSite(cell: ThumbnailCell, site: SuggestedSite) -> ThumbnailCell {
        cell.textLabel.text = site.title.isEmpty ? NSURL(string: site.url)?.normalizedHostAndPath() : site.title
        cell.imageWrapper.backgroundColor = site.backgroundColor
        cell.backgroundImage.image = nil
        cell.backgroundEffect?.alpha = 0

        if let icon = site.wordmark.url.asURL,
           let host = icon.host {
            if icon.scheme == "asset" {
                cell.imageView.image = UIImage(named: host)
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

        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = cell.textLabel.text
        cell.removeButton.hidden = true

        return cell
    }

    subscript(index: Int) -> Site? {
        if data.status != .Success {
            return nil
        }

        if index >= data.count {
            return SuggestedSites[index - data.count]
        }
        return data[index] as Site?
    }

    @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Cells for the top site thumbnails.
        let site = self[indexPath.item]!
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThumbnailIdentifier, forIndexPath: indexPath) as! ThumbnailCell

        if indexPath.item >= data.count {
            return createTileForSuggestedSite(cell, site: site as! SuggestedSite)
        }
        return createTileForSite(cell, site: site)
    }
}
