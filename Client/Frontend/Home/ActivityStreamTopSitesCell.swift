/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SDWebImage
import Storage

private struct TopSiteCellUX {
    static let TitleHeight: CGFloat = 20
    static let TitleFont = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CellCornerRadius: CGFloat = 4
    static let TitleOffset: CGFloat = 5
    static let OverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let IconSizePercent: CGFloat = 0.8
    static let BorderColor = UIColor(white: 0, alpha: 0.1)
    static let BorderWidth: CGFloat = 0.5
    static let PinIconSize: CGFloat = 12
    static let PinColor = UIColor.Photon.Grey60
}

/*
 *  The TopSite cell that appears in the ASHorizontalScrollView.
 */
class TopSiteItemCell: UICollectionViewCell, Themeable {

    var url: URL?

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.templateImageNamed("pin_small")
        return imageView
    }()

    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.layer.masksToBounds = true
        titleLabel.textAlignment = .center
        titleLabel.font = TopSiteCellUX.TitleFont
        return titleLabel
    }()

    lazy private var faviconBG: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TopSiteCellUX.CellCornerRadius
        view.layer.masksToBounds = true
        view.layer.borderWidth = TopSiteCellUX.BorderWidth
        return view
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()

    lazy var titleBorder: CALayer = {
        let border = CALayer()
        return border
    }()

    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityIdentifier = "TopSite"

        contentView.addSubview(titleLabel)
        contentView.addSubview(faviconBG)
        contentView.addSubview(imageView)
        contentView.addSubview(selectedOverlay)

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self).offset(TopSiteCellUX.TitleOffset)
            make.right.equalTo(self).offset(-TopSiteCellUX.TitleOffset)
            make.height.equalTo(TopSiteCellUX.TitleHeight)
            make.bottom.equalTo(self)
        }

        imageView.snp.makeConstraints { make in
            make.size.equalTo(floor(frame.width * TopSiteCellUX.IconSizePercent))
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).inset(-TopSiteCellUX.TitleHeight/2)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        faviconBG.snp.makeConstraints { make in
            make.top.left.right.equalTo(self)
            make.bottom.equalTo(self).inset(TopSiteCellUX.TitleHeight)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleBorder.frame = CGRect(x: 0, y: frame.height - TopSiteCellUX.TitleHeight -  TopSiteCellUX.BorderWidth, width: frame.width, height: TopSiteCellUX.BorderWidth)

        imageView.snp.remakeConstraints { make in
            make.size.equalTo(floor(self.frame.width * TopSiteCellUX.IconSizePercent))
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).inset(-TopSiteCellUX.TitleHeight/2)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = UIColor.clear
        imageView.image = nil
        imageView.backgroundColor = UIColor.clear
        faviconBG.backgroundColor = UIColor.clear
        pinImageView.removeFromSuperview()
        imageView.sd_cancelCurrentImageLoad()
        titleLabel.text = ""
        titleLabel.snp.updateConstraints { make in
            make.left.equalTo(self).offset(TopSiteCellUX.TitleOffset)
        }
    }

    func configureWithTopSiteItem(_ site: Site) {
        url = site.tileURL

        if let provider = site.metadata?.providerName {
            titleLabel.text = provider.lowercased()
        } else {
            titleLabel.text = site.tileURL.hostSLD
        }

        // If its a pinned site add a bullet point to the front
        if let _ = site as? PinnedSite {
            contentView.addSubview(pinImageView)
            pinImageView.snp.makeConstraints { make in
                make.right.equalTo(self.titleLabel.snp.left)
                make.size.equalTo(TopSiteCellUX.PinIconSize)
                make.centerY.equalTo(self.titleLabel.snp.centerY)
            }
            titleLabel.snp.updateConstraints { make in
                make.left.equalTo(self).offset(TopSiteCellUX.PinIconSize)
            }
        }

        accessibilityLabel = titleLabel.text
        imageView.setFavicon(forSite: site, onCompletion: { [weak self] (color, url) in
            if let url = url, url == self?.url {
                self?.faviconBG.backgroundColor = color
                self?.imageView.backgroundColor = color
            }
        })

        applyTheme()
    }

    func applyTheme() {
        imageView.tintColor = TopSiteCellUX.PinColor
        faviconBG.layer.borderColor = TopSiteCellUX.BorderColor.cgColor
        selectedOverlay.backgroundColor = TopSiteCellUX.OverlayColor
        titleBorder.backgroundColor = TopSiteCellUX.BorderColor.cgColor
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.theme.homePanel.topSiteDomain
    }
}

// An empty cell to show when a row is incomplete
class EmptyTopsiteDecorationCell: UICollectionReusableView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = TopSiteCellUX.CellCornerRadius
        self.layer.borderWidth = TopSiteCellUX.BorderWidth
        self.layer.borderColor = TopSiteCellUX.BorderColor.cgColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct ASHorizontalScrollCellUX {
    static let TopSiteCellIdentifier = "TopSiteItemCell"
    static let TopSiteEmptyCellIdentifier = "TopSiteItemEmptyCell"

    static let TopSiteItemSize = CGSize(width: 75, height: 75)
    static let BackgroundColor = UIColor.Photon.White100
    static let PageControlRadius: CGFloat = 3
    static let PageControlSize = CGSize(width: 30, height: 15)
    static let PageControlOffset: CGFloat = 12
    static let MinimumInsets: CGFloat = 14
}

/*
 The View that describes the topSite cell that appears in the tableView.
 */
class ASHorizontalScrollCell: UICollectionViewCell {

    lazy var collectionView: UICollectionView = {
        let layout  = HorizontalFlowLayout()
        layout.itemSize = ASHorizontalScrollCellUX.TopSiteItemSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TopSiteItemCell.self, forCellWithReuseIdentifier: ASHorizontalScrollCellUX.TopSiteCellIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        return collectionView
    }()

    lazy fileprivate var pageControl: FilledPageControl = {
        let pageControl = FilledPageControl()
        pageControl.tintColor = UIColor.Photon.Grey50
        pageControl.indicatorRadius = ASHorizontalScrollCellUX.PageControlRadius
        pageControl.isUserInteractionEnabled = true
        pageControl.isAccessibilityElement = true
        pageControl.accessibilityIdentifier = "pageControl"
        pageControl.accessibilityLabel = Strings.ASPageControlButton
        pageControl.accessibilityTraits = UIAccessibilityTraitButton
        return pageControl
    }()

    lazy fileprivate var pageControlPress: UITapGestureRecognizer = {
        let press = UITapGestureRecognizer(target: self, action: #selector(handlePageTap))
   //     press.delegate = self
        return press
    }()

    weak var delegate: ASHorizontalScrollCellManager? {
        didSet {
            collectionView.delegate = delegate
            collectionView.dataSource = delegate
            delegate?.pageChangedHandler = { [weak self] progress in
                self?.currentPageChanged(progress)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        accessibilityIdentifier = "TopSitesCell"
        backgroundColor = UIColor.clear
        contentView.addSubview(collectionView)
        contentView.addSubview(pageControl)

        pageControl.addGestureRecognizer(self.pageControlPress)

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeArea.edges)
        }

        pageControl.snp.makeConstraints { make in
            make.size.equalTo(ASHorizontalScrollCellUX.PageControlSize)
            make.top.equalTo(collectionView.snp.bottom).inset(ASHorizontalScrollCellUX.PageControlOffset)
            make.centerX.equalTo(self.snp.centerX)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let layout = collectionView.collectionViewLayout as! HorizontalFlowLayout

        pageControl.pageCount = layout.numberOfPages(with: self.frame.size)
        pageControl.isHidden = pageControl.pageCount <= 1
    }

    func currentPageChanged(_ currentPage: CGFloat) {
        pageControl.progress = currentPage
        if currentPage == floor(currentPage) {
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
            self.setNeedsLayout()
        }
    }

    @objc func handlePageTap(_ gesture: UITapGestureRecognizer) {
        guard pageControl.pageCount > 1 else {
            return
        }

        if pageControl.pageCount > pageControl.currentPage + 1 {
            pageControl.progress = CGFloat(pageControl.currentPage + 1)
        } else {
            pageControl.progress = CGFloat(pageControl.currentPage - 1)
        }

        moveToPage(pageControl.currentPage, animated: true)
    }

    func moveToPage(_ pageNumber: Int, animated: Bool = false) {
        if pageNumber < 0 || pageNumber >= pageControl.pageCount {
            return
        }
        pageControl.progress = CGFloat(pageNumber)
        let swipeCoordinate = CGFloat(pageNumber) * self.collectionView.frame.size.width
        self.collectionView.setContentOffset(CGPoint(x: swipeCoordinate, y: 0), animated: animated)
    }

    func moveToInitialPage() {
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            moveToPage(pageControl.pageCount-1)
        } else {
            moveToPage(0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
/*
    A custom layout used to show a horizontal scrolling list with paging. Similar to iOS springboard.
    A modified version of http://stackoverflow.com/a/34167915
 */

class HorizontalFlowLayout: UICollectionViewLayout {
    fileprivate var cellCount: Int {
        if let collectionView = collectionView, let dataSource = collectionView.dataSource {
            return dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
        }
        return 0
    }
    var boundsSize = CGSize.zero
    private var insets = UIEdgeInsets(equalInset: ASHorizontalScrollCellUX.MinimumInsets)
    private var sectionInsets: CGFloat = 0
    var itemSize = CGSize.zero
    var cachedAttributes: [UICollectionViewLayoutAttributes]?

    override func prepare() {
        super.prepare()
        if boundsSize != self.collectionView?.frame.size {
            self.collectionView?.setContentOffset(.zero, animated: false)
        }
        boundsSize = self.collectionView?.frame.size ?? .zero
        cachedAttributes = nil
        register(EmptyTopsiteDecorationCell.self, forDecorationViewOfKind: ASHorizontalScrollCellUX.TopSiteEmptyCellIdentifier)
    }

    func numberOfPages(with bounds: CGSize) -> Int {
        let itemsPerPage = maxVerticalItemsCount(height: bounds.height) * maxHorizontalItemsCount(width: bounds.width)
        // Sometimes itemsPerPage is 0. In this case just return 0. We dont want to try dividing by 0.
        return itemsPerPage == 0 ? 0 : Int(ceil(Double(cellCount) / Double(itemsPerPage)))
    }

    func calculateLayout(for size: CGSize) -> (size: CGSize, cellSize: CGSize, cellInsets: UIEdgeInsets) {
        let width = size.width
        let height = size.height
        guard width != 0 else {
            return (size: .zero, cellSize: self.itemSize, cellInsets: self.insets)
        }

        let horizontalItemsCount = maxHorizontalItemsCount(width: width)
        var verticalItemsCount = maxVerticalItemsCount(height: height)
        if cellCount <= horizontalItemsCount {
            // If we have only a few items don't provide space for multiple rows.
            verticalItemsCount = 1
        }

        // Take the number of cells and subtract its space in the view from the height. The left over space is the white space.
        // The left over space is then devided evenly into (n + 1) parts to figure out how much space should be inbetween a cell
        var verticalInsets = floor((height - (CGFloat(verticalItemsCount) * itemSize.height)) / CGFloat(verticalItemsCount + 1))
        var horizontalInsets = floor((width - (CGFloat(horizontalItemsCount) * itemSize.width)) / CGFloat(horizontalItemsCount + 1))

        // We want a minimum inset to make things not look crowded. We also don't want uneven spacing.
        // If we dont have this. Set a minimum inset and recalculate the size of a cell
        var estimatedItemSize = itemSize
        if horizontalInsets != ASHorizontalScrollCellUX.MinimumInsets {
            verticalInsets = ASHorizontalScrollCellUX.MinimumInsets
            horizontalInsets = ASHorizontalScrollCellUX.MinimumInsets
            estimatedItemSize.width = floor((width - (CGFloat(horizontalItemsCount + 1) * horizontalInsets)) / CGFloat(horizontalItemsCount))
            estimatedItemSize.height = estimatedItemSize.width + TopSiteCellUX.TitleHeight
        }

        //calculate our estimates.
        let estimatedHeight = floor(estimatedItemSize.height * CGFloat(verticalItemsCount)) + (verticalInsets * (CGFloat(verticalItemsCount) + 1))
        let estimatedSize = CGSize(width: CGFloat(numberOfPages(with: boundsSize)) * width, height: estimatedHeight)

        let estimatedInsets = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)
        return (size: estimatedSize, cellSize: estimatedItemSize, cellInsets: estimatedInsets)
    }

    override var collectionViewContentSize: CGSize {
        let estimatedLayout = calculateLayout(for: boundsSize)
        insets = estimatedLayout.cellInsets
        itemSize = estimatedLayout.cellSize
        boundsSize.height = estimatedLayout.size.height
        return estimatedLayout.size
    }

    func maxVerticalItemsCount(height: CGFloat) -> Int {
        let verticalItemsCount =  Int(floor(height / (ASHorizontalScrollCellUX.TopSiteItemSize.height + insets.top)))
        if let delegate = self.collectionView?.delegate as? ASHorizontalLayoutDelegate {
            return delegate.numberOfVerticalItems()
        } else {
            return verticalItemsCount
        }
    }

    func maxHorizontalItemsCount(width: CGFloat) -> Int {
        let horizontalItemsCount =  Int(floor(width / (ASHorizontalScrollCellUX.TopSiteItemSize.width + insets.left)))
        if let delegate = self.collectionView?.delegate as? ASHorizontalLayoutDelegate {
            return delegate.numberOfHorizontalItems()
        } else {
            return horizontalItemsCount
        }
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let decorationAttr =  UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
        let cellAttr = self.computeLayoutAttributesForCellAtIndexPath(indexPath)
        decorationAttr.frame = cellAttr.frame

        decorationAttr.frame.size.height -= TopSiteCellUX.TitleHeight
        decorationAttr.zIndex = -1
        return decorationAttr
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if cachedAttributes != nil {
            return cachedAttributes
        }
        var allAttributes = [UICollectionViewLayoutAttributes]()
        for i in 0 ..< cellCount {
            let indexPath = IndexPath(row: i, section: 0)
            let attr = self.computeLayoutAttributesForCellAtIndexPath(indexPath)
            allAttributes.append(attr)
        }

        //create decoration attributes
        let horizontalItemsCount = maxHorizontalItemsCount(width: boundsSize.width)
        var numberOfCells = cellCount
        while numberOfCells % horizontalItemsCount != 0 {
            //we need some empty cells dawg.

            let attr = self.layoutAttributesForDecorationView(ofKind: ASHorizontalScrollCellUX.TopSiteEmptyCellIdentifier, at: IndexPath(item: numberOfCells, section: 0))
            allAttributes.append(attr!)
            numberOfCells += 1
        }
        cachedAttributes = allAttributes
        return allAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.computeLayoutAttributesForCellAtIndexPath(indexPath)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        cachedAttributes = nil
        // Sometimes when the topsiteCell isnt on the screen the newbounds that it tries to layout in is 0
        // Resulting in incorrect layouts. Only layout when a valid width is given
        return newBounds.width > 0
    }

    func computeLayoutAttributesForCellAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let row = indexPath.row
        let bounds = self.collectionView!.bounds

        let verticalItemsCount = maxVerticalItemsCount(height: bounds.size.height)
        let horizontalItemsCount = maxHorizontalItemsCount(width: bounds.size.width)

        let itemsPerPage = verticalItemsCount * horizontalItemsCount

        let columnPosition = row % horizontalItemsCount
        let rowPosition = (row / horizontalItemsCount) % verticalItemsCount

        let itemPage: Int
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            itemPage = Int(floor(Double(row)/Double(itemsPerPage)))
        } else {
            // For RTL we invert the page position
            let pageCount = Int(ceil(Double(cellCount)/Double(itemsPerPage)))
            itemPage = pageCount - Int(floor(Double(row)/Double(itemsPerPage))) - 1
        }

        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        var frame = CGRect.zero
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            frame.origin.x = CGFloat(itemPage) * bounds.size.width + CGFloat(columnPosition) * (itemSize.width + insets.left) + insets.left
        } else {
            // For RTL all we have to do is invert the colum
            frame.origin.x = CGFloat(itemPage) * bounds.size.width + CGFloat(horizontalItemsCount - 1 - columnPosition) * (itemSize.width + insets.left) + insets.left
        }
        frame.origin.y = CGFloat(rowPosition) * (itemSize.height + insets.top) + insets.top
        frame.size = itemSize
        attr.frame = frame

        return attr
    }
}

/*
    Defines the number of items to show in topsites for different size classes.
*/
private struct ASTopSiteSourceUX {
    static let verticalItemsForTraitSizes: [UIUserInterfaceSizeClass: Int] = [.compact: 1, .regular: 2, .unspecified: 0]
    static let maxNumberOfPages = 2
    static let CellIdentifier = "TopSiteItemCell"
}

protocol ASHorizontalLayoutDelegate {
    func numberOfVerticalItems() -> Int
    func numberOfHorizontalItems() -> Int
}

/*
 This Delegate/DataSource is used to manage the ASHorizontalScrollCell's UICollectionView.
 This is left generic enough for it to be re used for other parts of Activity Stream.
 */

class ASHorizontalScrollCellManager: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, ASHorizontalLayoutDelegate {

    var content: [Site] = []

    var urlPressedHandler: ((URL, IndexPath) -> Void)?
    var pageChangedHandler: ((CGFloat) -> Void)?

    // The current traits that define the parent ViewController. Used to determine how many rows/columns should be created.
    var currentTraits: UITraitCollection?

    // Size classes define how many items to show per row/column.
    func numberOfVerticalItems() -> Int {
        guard let traits = currentTraits else {
            return 0
        }
        return ASTopSiteSourceUX.verticalItemsForTraitSizes[traits.verticalSizeClass]!
    }

    func numberOfHorizontalItems() -> Int {
        guard let traits = currentTraits else {
            return 0
        }
        let isLandscape = UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)
        if UIDevice.current.userInterfaceIdiom == .phone {
            if isLandscape {
                return 8
            } else {
                return 4
            }
        }
        // On iPad
        // The number of items in a row is equal to the number of highlights in a row * 2
        var numItems: Int = Int(ASPanelUX.numberOfItemsPerRowForSizeClassIpad[traits.horizontalSizeClass])
        if UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) || (traits.horizontalSizeClass == .compact && isLandscape) {
            numItems = numItems - 1
        }
        return numItems * 2
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.content.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ASTopSiteSourceUX.CellIdentifier, for: indexPath) as! TopSiteItemCell
        let contentItem = content[indexPath.row]
        cell.configureWithTopSiteItem(contentItem)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let contentItem = content[indexPath.row]
        guard let url = contentItem.url.asURL else {
            return
        }
        urlPressedHandler?(url, indexPath)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        pageChangedHandler?(scrollView.contentOffset.x / pageWidth)
    }

}
