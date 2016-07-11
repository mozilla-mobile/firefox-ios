/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import XCGLogger
import Storage
import WebImage
import Deferred

private let log = Logger.browserLogger

private let ThumbnailIdentifier = "Thumbnail"

extension CGSize {
    public func widthLargerOrEqualThanHalfIPad() -> Bool {
        let halfIPadSize: CGFloat = 507
        return width >= halfIPadSize
    }
}

struct TopSitesPanelUX {
    private static let EmptyStateTitleTextColor = UIColor.darkGrayColor()
    private static let EmptyStateTopPaddingInBetweenItems: CGFloat = 15
    private static let WelcomeScreenPadding: CGFloat = 15
    private static let WelcomeScreenItemTextColor = UIColor.grayColor()
    private static let WelcomeScreenItemWidth = 170
}

class TopSitesPanel: UIViewController {
    weak var homePanelDelegate: HomePanelDelegate?
    private lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverlayView()
    private var collection: TopSitesCollectionView? = nil
    private lazy var dataSource: TopSitesDataSource = {
        return TopSitesDataSource(profile: self.profile)
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

                updateAllRemoveButtonStates()
            }
        }
    }

    let profile: Profile

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        coordinator.animateAlongsideTransition({ context in
            self.collection?.reloadData()
        }, completion: nil)
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
    }

    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopSitesPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopSitesPanel.notificationReceived(_:)), name: NotificationProfileDidFinishSyncing, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopSitesPanel.notificationReceived(_:)), name: NotificationPrivateDataClearedHistory, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopSitesPanel.notificationReceived(_:)), name: NotificationDynamicFontChanged, object: nil)
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
        collection.accessibilityIdentifier = "Top Sites View"
        view.addSubview(collection)
        collection.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.collection = collection

        self.dataSource.collectionView = self.collection
        self.profile.history.setTopSitesCacheSize(Int32(maxFrecencyLimit))
        self.refreshTopSites(maxFrecencyLimit)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationPrivateDataClearedHistory, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
    }

    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationProfileDidFinishSyncing:
            // Only reload top sites if there the cache is dirty since the finish syncing
            // notification is fired everytime the user re-enters the app from the background.
            self.profile.history.areTopSitesDirty(withLimit: self.maxFrecencyLimit) >>== { dirty in
                if dirty {
                    self.refreshTopSites(self.maxFrecencyLimit)
                }
            }
        case NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory, NotificationDynamicFontChanged:
            self.refreshTopSites(self.maxFrecencyLimit)
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
        }
    }

    private func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.whiteColor()

        let logoImageView = UIImageView(image: UIImage(named: "emptyTopSites"))
        overlayView.addSubview(logoImageView)

        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFont
        titleLabel.text = Strings.TopSitesEmptyStateTitle
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.textColor = TopSitesPanelUX.EmptyStateTitleTextColor
        overlayView.addSubview(titleLabel)

        let descriptionLabel = UILabel()
        descriptionLabel.text = Strings.TopSitesEmptyStateDescription
        descriptionLabel.textAlignment = NSTextAlignment.Center
        descriptionLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        descriptionLabel.textColor = TopSitesPanelUX.WelcomeScreenItemTextColor
        descriptionLabel.numberOfLines = 2
        descriptionLabel.adjustsFontSizeToFitWidth = true
        overlayView.addSubview(descriptionLabel)

        logoImageView.snp_makeConstraints { make in
            make.centerX.equalTo(overlayView)

            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(overlayView).offset(HomePanelUX.EmptyTabContentOffset).priorityMedium()

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView).offset(50)
        }

        titleLabel.snp_makeConstraints { make in
            make.top.equalTo(logoImageView.snp_bottom).offset(TopSitesPanelUX.EmptyStateTopPaddingInBetweenItems)
            make.centerX.equalTo(logoImageView)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.top.equalTo(titleLabel.snp_bottom).offset(TopSitesPanelUX.WelcomeScreenPadding)
            make.width.equalTo(TopSitesPanelUX.WelcomeScreenItemWidth)
        }

        return overlayView
    }

    private func updateEmptyPanelState() {
        if dataSource.count() == 0 {
            if self.emptyStateOverlayView.superview == nil {
                self.view.addSubview(self.emptyStateOverlayView)
                self.emptyStateOverlayView.snp_makeConstraints { make -> Void in
                    make.edges.equalTo(self.view)
                }
            }
        } else {
            self.emptyStateOverlayView.removeFromSuperview()
        }
    }

    //MARK: Private Helpers
    private func updateDataSourceWithSites(result: Maybe<Cursor<Site>>) {
        if let data = result.successValue {
            self.dataSource.setHistorySites(data.asArray())
            self.dataSource.profile = self.profile
        }
        self.updateEmptyPanelState()
    }

    private func updateAllRemoveButtonStates() {
        collection?.indexPathsForVisibleItems().forEach(updateRemoveButtonStateForIndexPath)
    }

    private func deleteTileForSuggestedSite(site: SuggestedSite) -> Success {
        var deletedSuggestedSites = profile.prefs.arrayForKey("topSites.deletedSuggestedSites") as! [String]
        deletedSuggestedSites.append(site.url)
        profile.prefs.setObject(deletedSuggestedSites, forKey: "topSites.deletedSuggestedSites")
        return succeed()
    }

    private func deleteHistoryTileForSite(site: Site, atIndexPath indexPath: NSIndexPath) {
        collection?.userInteractionEnabled = false

        if site is SuggestedSite {
            deleteTileForSuggestedSite(site as! SuggestedSite)
        }

        profile.history.removeSiteFromTopSites(site).uponQueue(dispatch_get_main_queue()) { result in
            guard result.isSuccess else { return }

            // Remove the site from the current data source. Don't requery yet
            // since a Sync or location change may have changed the data under us.
            self.dataSource.sites = self.dataSource.sites.filter { $0 !== site }

            // Update the UICollectionView.
            self.deleteOrUpdateSites(indexPath) >>> {
                // Finally, requery to pull in the latest sites.
                self.profile.history.getTopSites(withLimit: self.maxFrecencyLimit).uponQueue(dispatch_get_main_queue()) { result in
                    self.updateDataSourceWithSites(result)
                    self.collection?.userInteractionEnabled = true
                }
            }
        }
    }

    private func updateRemoveButtonStateForIndexPath(indexPath: NSIndexPath) {
        // If we have a cell passed in, use it. If not, then use the indexPath to get it.
        guard let cell = collection?.cellForItemAtIndexPath(indexPath) as? ThumbnailCell else {
            return
        }

        cell.toggleRemoveButton(editingThumbnails)
    }

    private func refreshTopSites(frecencyLimit: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            // Don't allow Sync or other notifications to change the data source if we're deleting a thumbnail.
            if !(self.collection?.userInteractionEnabled ?? true) {
                return
            }

            // Reload right away with whatever is in the cache, then check to see if the cache is invalid.
            // If it's invalid, invalidate the cache and requery. This allows us to always show results
            // immediately while also loading up-to-date results asynchronously if needed.
            self.reloadTopSitesWithLimit(frecencyLimit) >>> {
                self.profile.history.updateTopSitesCacheIfInvalidated() >>== { dirty in
                    if dirty {
                        self.dataSource.sitesInvalidated = true
                        self.reloadTopSitesWithLimit(frecencyLimit)
                    }
                }
            }
        }
    }

    private func reloadTopSitesWithLimit(limit: Int) -> Success {
        return self.profile.history.getTopSites(withLimit: limit).bindQueue(dispatch_get_main_queue()) { result in
            self.updateDataSourceWithSites(result)
            self.collection?.reloadData()
            return succeed()
        }
    }

    private func deleteOrUpdateSites(indexPath: NSIndexPath) -> Success {
        guard let collection = self.collection else { return succeed() }

        let result = Success()

        collection.performBatchUpdates({
            collection.deleteItemsAtIndexPaths([indexPath])

            // If we have more items in our data source, replace the deleted site with a new one.
            let count = collection.numberOfItemsInSection(0) - 1
            if count < self.dataSource.count() {
                collection.insertItemsAtIndexPaths([ NSIndexPath(forItem: count, inSection: 0) ])
            }
        }, completion: { _ in
            self.updateAllRemoveButtonStates()
            result.fill(Maybe(success: ()))
        })

        return result
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
            let insets = ThumbnailCellUX.insetsForCollectionViewSize(size,
                traitCollection:  traitCollection)
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
            homePanelDelegate?.homePanel(self, didSelectURL: site.tileURL, visitType: visitType)
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let thumbnailCell = cell as? ThumbnailCell {
            thumbnailCell.delegate = self
            if editingThumbnails && indexPath.item < dataSource.count() && thumbnailCell.removeButton.hidden {
                thumbnailCell.removeButton.hidden = false
            }
        }
    }
}

extension TopSitesPanel: ThumbnailCellDelegate {
    func didRemoveThumbnail(thumbnailCell: ThumbnailCell) {
        guard let indexPath = collection?.indexPathForCell(thumbnailCell),
              let site = dataSource[indexPath.item] else { return }

        self.deleteHistoryTileForSite(site, atIndexPath: indexPath)
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

class TopSitesLayout: UICollectionViewLayout {

    var thumbnailCount: Int {
        assertIsMainThread("layout.thumbnailCount interacts with UIKit components - cannot call from background thread.")
        return thumbnailRows * thumbnailCols
    }

    private var thumbnailRows: Int {
        assert(NSThread.isMainThread(), "Interacts with UIKit components - not thread-safe.")
        return max(2, Int((self.collectionView?.frame.height ?? self.thumbnailHeight) / self.thumbnailHeight))
    }

    private var thumbnailCols: Int {
        assert(NSThread.isMainThread(), "Interacts with UIKit components - not thread-safe.")

        let size = collectionView?.bounds.size ?? CGSizeZero
        let traitCollection = collectionView!.traitCollection
        if traitCollection.horizontalSizeClass == .Compact {
            // Landscape iPhone
            if traitCollection.verticalSizeClass == .Compact {
                return 5
            }
            // Split screen iPad width
            else if size.widthLargerOrEqualThanHalfIPad() ?? false {
                return 4
            }
            // iPhone portrait
            else {
                return 3
            }
        } else {
            // Portrait iPad
            if size.height > size.width {
                return 4;
            }
            // Landscape iPad
            else {
                return 5;
            }
        }
    }

    private var width: CGFloat {
        assertIsMainThread("layout.width interacts with UIKit components - cannot call from background thread.")
        return self.collectionView?.frame.width ?? 0
    }

    // The width and height of the thumbnail here are the width and height of the tile itself, not the image inside the tile.
    private var thumbnailWidth: CGFloat {
        assertIsMainThread("layout.thumbnailWidth interacts with UIKit components - cannot call from background thread.")

        let size = collectionView?.bounds.size ?? CGSizeZero
        let insets = ThumbnailCellUX.insetsForCollectionViewSize(size,
            traitCollection:  collectionView!.traitCollection)

        return floor(width - insets.left - insets.right) / CGFloat(thumbnailCols)
    }
    // The tile's height is determined the aspect ratio of the thumbnails width. We also take into account
    // some padding between the title and the image.
    private var thumbnailHeight: CGFloat {
        assertIsMainThread("layout.thumbnailHeight interacts with UIKit components - cannot call from background thread.")

        return floor(thumbnailWidth / CGFloat(ThumbnailCellUX.ImageAspectRatio))
    }

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
        let size = collectionView?.bounds.size ?? CGSizeZero
        let insets = ThumbnailCellUX.insetsForCollectionViewSize(size,
            traitCollection:  collectionView!.traitCollection)
        return thumbnailHeight * CGFloat(rows) + insets.top + insets.bottom
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

    override func prepareLayout() {
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
        let col: Int
        if UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft {
            // For RTL the rows are mirrored, item 0 starts at the right
            col = thumbnailCols - (indexPath.item % thumbnailCols) - 1
        } else {
            col = indexPath.item % thumbnailCols
        }
        let size = collectionView?.bounds.size ?? CGSizeZero
        let insets = ThumbnailCellUX.insetsForCollectionViewSize(size,
            traitCollection:  collectionView!.traitCollection)
        let x = insets.left + thumbnailWidth * CGFloat(col)
        let y = insets.top + CGFloat(row) * thumbnailHeight
        attr.frame = CGRectMake(ceil(x), ceil(y), thumbnailWidth, thumbnailHeight)

        return attr
    }
}

private class TopSitesDataSource: NSObject, UICollectionViewDataSource {
    var profile: Profile
    var editingThumbnails: Bool = false
    var suggestedSites = [SuggestedSite]()
    var sites = [Site]()
    private var sitesInvalidated = true

    weak var collectionView: UICollectionView?

    private let blurQueue = dispatch_queue_create("FaviconBlurQueue", DISPATCH_QUEUE_CONCURRENT)
    private let BackgroundFadeInDuration: NSTimeInterval = 0.3

    init(profile: Profile) {
        self.profile = profile
        if profile.prefs.arrayForKey("topSites.deletedSuggestedSites") == nil {
            profile.prefs.setObject([], forKey: "topSites.deletedSuggestedSites")
        }
        super.init()
    }

    @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // If there aren't enough data items to fill the grid, look for items in suggested sites.
        if let layout = collectionView.collectionViewLayout as? TopSitesLayout {
            return min(count(), layout.thumbnailCount)
        }

        return 0
    }

    private func setDefaultThumbnailBackgroundForCell(cell: ThumbnailCell) {
        cell.imageView.image = UIImage(named: "defaultTopSiteIcon")!
        cell.imageView.contentMode = UIViewContentMode.Center
    }

    private func setBlurredBackground(image: UIImage, withURL url: NSURL, forCell cell: ThumbnailCell) {
        let blurredKey = "\(url.absoluteString)!blurred"
        if let blurredImage = SDImageCache.sharedImageCache().imageFromMemoryCacheForKey(blurredKey) {
            cell.backgroundImage.image = blurredImage
        } else {
            let blurredImage = image.applyLightEffect()
            SDImageCache.sharedImageCache().storeImage(blurredImage, forKey: blurredKey, toDisk: false)
            cell.backgroundImage.alpha = 0
            cell.backgroundImage.image = blurredImage
            UIView.animateWithDuration(self.BackgroundFadeInDuration) {
                cell.backgroundImage.alpha = 1
            }
        }
    }

    private func downloadFaviconsAndUpdateForSite(site: Site) {
        guard let siteURL = site.url.asURL else { return }

        FaviconFetcher.getForURL(siteURL, profile: profile).uponQueue(dispatch_get_main_queue()) { result in
            guard let favicons = result.successValue where favicons.count > 0,
                  let url = favicons.first?.url.asURL,
                  let indexOfSite = (self.sites.indexOf { $0 == site }) else {
                return
            }

            let indexPathToUpdate = NSIndexPath(forItem: indexOfSite, inSection: 0)
            guard let cell = self.collectionView?.cellForItemAtIndexPath(indexPathToUpdate) as? ThumbnailCell else { return }
            cell.imageView.sd_setImageWithURL(url) { (img, err, type, url) -> Void in
                guard let img = img else {
                    self.setDefaultThumbnailBackgroundForCell(cell)
                    return
                }
                cell.image = img
                self.setBlurredBackground(img, withURL: url, forCell: cell)
            }
        }
    }

    private func configureCell(cell: ThumbnailCell, forSite site: Site, isEditing editing: Bool, profile: Profile) {

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

        let domainURL = extractDomainURL(site.url)
        cell.textLabel.text = domainURL
        cell.accessibilityLabel = cell.textLabel.text
        cell.removeButton.hidden = !editing

        let removeButtonAccessibilityLabel = String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, domainURL)
        cell.removeButton.accessibilityLabel = removeButtonAccessibilityLabel

        guard let icon = site.icon else {
            setDefaultThumbnailBackgroundForCell(cell)
            downloadFaviconsAndUpdateForSite(site)
            return
        }

        // We've looked before recently and didn't find a favicon
        switch icon.type {
        case .NoneFound where NSDate().timeIntervalSinceDate(icon.date) < FaviconFetcher.ExpirationTime:
            self.setDefaultThumbnailBackgroundForCell(cell)
        default:
            cell.imageView.sd_setImageWithURL(icon.url.asURL, completed: { (img, err, type, url) -> Void in
                if let img = img {
                    cell.image = img
                    self.setBlurredBackground(img, withURL: url, forCell: cell)
                } else {
                    self.setDefaultThumbnailBackgroundForCell(cell)
                    self.downloadFaviconsAndUpdateForSite(site)
                }
            })
        }
    }

    private func configureCell(cell: ThumbnailCell, forSuggestedSite site: SuggestedSite) {
        let title = site.title.isEmpty ? NSURL(string: site.url)?.normalizedHostAndPath() : site.title
        cell.textLabel.text = title
        cell.imageWrapper.backgroundColor = site.backgroundColor
        cell.imageView.contentMode = .ScaleAspectFit
        cell.imageView.layer.minificationFilter = kCAFilterTrilinear
        cell.accessibilityLabel = cell.textLabel.text

        if let title = title {
            cell.removeButton.accessibilityLabel =  String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, title)
        }

        guard let icon = site.wordmark.url.asURL,
            let host = icon.host else {
                self.setDefaultThumbnailBackgroundForCell(cell)
                return
        }

        if icon.scheme == "asset" {
            cell.imageView.image = UIImage(named: host)
        } else {
            cell.imageView.sd_setImageWithURL(icon, completed: { img, err, type, key in
                if img == nil {
                    self.setDefaultThumbnailBackgroundForCell(cell)
                }
            })
        }
    }

    private func setHistorySites(historySites: [Site]) {
        // Sites are invalidated and we have a new data set, so do a replace.
        if (sitesInvalidated) {
            self.sites = []
        }

        // We requery every time we do a deletion. If the query contains a top site that's
        // bubbled up that wasn't there previously (e.g., a page just finished loading
        // in the background), it will change the index of any following site currently
        // displayed. This, in turn, would cause sites to shuffle around, and we would
        // possibly have duplicates if a site that's already visible has been reindexed
        // to a newly added position, post-deletion.
        //
        // The fix? Go through our existing set of sites on an update and append new sites
        // to the end. This preserves the ordering of existing sites, meaning the last
        // index, post-deletion, will always be a new site. Of course, this is temporary;
        // whenever the panel is reloaded, our transient, ordered state will be lost. But
        // that's OK: top sites change frequently anyway.
        var historySites: [Site] = historySites
        self.sites = self.sites.filter { site in
            if let index = historySites.indexOf({ extractDomainURL($0.url) == extractDomainURL(site.url) }) {
                historySites.removeAtIndex(index)
                return true
            }

            return site is SuggestedSite
        }

        self.sites += historySites

        // Since future updates to history sites will append to the previous result set,
        // including suggested sites, we only need to do this once.
        if sitesInvalidated {
            sitesInvalidated = false
            mergeSuggestedSites()
        }
    }

    private func mergeSuggestedSites() {
        suggestedSites = SuggestedSites.asArray()
        for url in profile.prefs.arrayForKey("topSites.deletedSuggestedSites") as! [String] {
            suggestedSites = suggestedSites.filter { extractDomainURL($0.url) != extractDomainURL(url) }
        }

        sites = sites.map { site in
            let domainURL = extractDomainURL(site.url)
            if let index = (suggestedSites.indexOf { extractDomainURL($0.url) == domainURL }) {
                let suggestedSite = suggestedSites[index]
                suggestedSites.removeAtIndex(index)
                return suggestedSite
            }
            return site
        }

        sites += suggestedSites as [Site]
    }

    subscript(index: Int) -> Site? {
        if count() == 0 {
            return nil
        }

        return self.sites[index] as Site?
    }

    private func count() -> Int {
        return sites.count
    }

    private func extractDomainURL(url: String) -> String {
        return NSURL(string: url)?.normalizedHost() ?? url
    }

    @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Cells for the top site thumbnails.
        let site = self[indexPath.item]!
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThumbnailIdentifier, forIndexPath: indexPath) as! ThumbnailCell

        let traitCollection = collectionView.traitCollection

        if let site = site as? SuggestedSite {
            configureCell(cell, forSuggestedSite: site)
            cell.updateLayoutForCollectionViewSize(collectionView.bounds.size, traitCollection: traitCollection, forSuggestedSite: true)
            return cell
        }

        configureCell(cell, forSite: site, isEditing: editingThumbnails, profile: profile)
        cell.updateLayoutForCollectionViewSize(collectionView.bounds.size, traitCollection: traitCollection, forSuggestedSite: false)
        return cell
    }
}
