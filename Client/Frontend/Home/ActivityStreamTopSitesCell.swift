/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebImage
import Storage

struct TopSiteCellUX {
    static let TitleHeight: CGFloat = 32
    static let TitleBackgroundColor = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.7)
    static let TitleTextColor = UIColor.black
    static let TitleFont = DynamicFontHelper.defaultHelper.DefaultSmallFont
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CellCornerRadius: CGFloat = 4
    static let TitleOffset: CGFloat = 5
    static let OverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let IconSize = CGSize(width: 32, height: 32)
    static let BorderColor = UIColor(white: 0, alpha: 0.1)
    static let BorderWidth: CGFloat = 0.5
}

/*
 *  The TopSite cell that appears in the ASHorizontalScrollView.
 */
class TopSiteItemCell: UICollectionViewCell {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.layer.masksToBounds = true
        titleLabel.textAlignment = .center
        titleLabel.font = TopSiteCellUX.TitleFont
        titleLabel.textColor = TopSiteCellUX.TitleTextColor
        titleLabel.backgroundColor = UIColor.clear
        return titleLabel
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = TopSiteCellUX.OverlayColor
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()

    lazy var titleBorder: CALayer = {
        let border = CALayer()
        border.backgroundColor = TopSiteCellUX.BorderColor.cgColor
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
        contentView.layer.cornerRadius = TopSiteCellUX.CellCornerRadius
        contentView.layer.masksToBounds = true

        contentView.layer.borderWidth = TopSiteCellUX.BorderWidth
        contentView.layer.borderColor = TopSiteCellUX.BorderColor.cgColor

        let titleWrapper = UIView()
        titleWrapper.backgroundColor = TopSiteCellUX.TitleBackgroundColor
        titleWrapper.layer.masksToBounds = true
        contentView.addSubview(titleWrapper)

        contentView.addSubview(titleLabel)
        contentView.addSubview(imageView)
        contentView.addSubview(selectedOverlay)

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self).offset(TopSiteCellUX.TitleOffset)
            make.right.equalTo(self).offset(-TopSiteCellUX.TitleOffset)
            make.height.equalTo(TopSiteCellUX.TitleHeight)
            make.bottom.equalTo(self)
        }

        imageView.snp.makeConstraints { make in
            make.size.equalTo(TopSiteCellUX.IconSize)
            // Add an offset to the image to make it appear centered with the titleLabel
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(-TopSiteCellUX.TitleHeight/2)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        titleWrapper.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(TopSiteCellUX.TitleHeight)
        }

        // The titleBorder must appear ABOVE the titleLabel. Meaning it must be 0.5 pixels above of the titleWrapper frame.
        titleBorder.frame = CGRect(x: 0, y: self.frame.height - TopSiteCellUX.TitleHeight -  TopSiteCellUX.BorderWidth, width: self.frame.width, height: TopSiteCellUX.BorderWidth)
        self.contentView.layer.addSublayer(titleBorder)

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleBorder.frame = CGRect(x: 0, y: frame.height - TopSiteCellUX.TitleHeight -  TopSiteCellUX.BorderWidth, width: frame.width, height: TopSiteCellUX.BorderWidth)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = UIColor.clear
        imageView.image = nil
        imageView.backgroundColor = UIColor.clear
        titleLabel.text = ""
    }

    func configureWithTopSiteItem(_ site: Site) {
        if let provider = site.provider {
            titleLabel.text = provider.lowercased()
        } else {
            titleLabel.text = site.tileURL.hostSLD
        }
        accessibilityLabel = titleLabel.text
        if let suggestedSite = site as? SuggestedSite {
            let img = UIImage(named: suggestedSite.faviconImagePath!)
            imageView.image = img
            // This is a temporary hack to make amazon/wikipedia have white backrounds instead of their default blacks
            // Once we remove the old TopSitesPanel we can change the values of amazon/wikipedia to be white instead of black.
            contentView.backgroundColor = suggestedSite.backgroundColor.isBlackOrWhite ? UIColor.white : suggestedSite.backgroundColor
            imageView.backgroundColor = contentView.backgroundColor
        } else {
            imageView.setFavicon(forSite: site, onCompletion: { (color, url) in
                if let url = url, url == site.tileURL {
                    self.contentView.backgroundColor = color
                    self.imageView.backgroundColor = color
                }
            })
        }
    }

}

struct ASHorizontalScrollCellUX {
    static let TopSiteCellIdentifier = "TopSiteItemCell"
    static let TopSiteItemSize = CGSize(width: 99, height: 99)
    static let BackgroundColor = UIColor.white
    static let PageControlRadius: CGFloat = 3
    static let PageControlSize = CGSize(width: 30, height: 15)
    static let PageControlOffset: CGFloat = -20
}

/*
 The View that describes the topSite cell that appears in the tableView.
 */
class ASHorizontalScrollCell: UITableViewCell {

    lazy var collectionView: UICollectionView = {
        let layout  = HorizontalFlowLayout()
        layout.itemSize = ASHorizontalScrollCellUX.TopSiteItemSize
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.register(TopSiteItemCell.self, forCellWithReuseIdentifier: ASHorizontalScrollCellUX.TopSiteCellIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
	 collectionView.isPagingEnabled = true
        return collectionView
    }()

    lazy fileprivate var pageControl: FilledPageControl = {
        let pageControl = FilledPageControl()
        pageControl.tintColor = UIColor.gray
        pageControl.indicatorRadius = ASHorizontalScrollCellUX.PageControlRadius
        pageControl.isUserInteractionEnabled = true
        pageControl.isAccessibilityElement = true
        pageControl.accessibilityIdentifier = "pageControl"
        pageControl.accessibilityLabel = Strings.ASPageControlButton
        pageControl.accessibilityTraits = UIAccessibilityTraitButton
        return pageControl
    }()

    lazy fileprivate var gradientBG: CAGradientLayer = {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.contentView.bounds
        gradient.colors = [UIColor.white.cgColor, UIColor(colorString: "f9f9f9").cgColor]
        return gradient
    }()

    lazy fileprivate var pageControlPress: UITapGestureRecognizer = {
        let press = UITapGestureRecognizer(target: self, action: #selector(ASHorizontalScrollCell.handlePageTap(_:)))
        press.delegate = self
        return press
    }()

    weak var delegate: ASHorizontalScrollCellManager? {
        didSet {
            collectionView.delegate = delegate
            collectionView.dataSource = delegate
            delegate?.pageChangedHandler = { [weak self] progress in
                self?.currentPageChanged(progress)
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        isAccessibilityElement = false
        accessibilityIdentifier = "TopSitesCell"
        backgroundColor = UIColor.clear
        contentView.addSubview(collectionView)
        contentView.addSubview(pageControl)
        self.selectionStyle = UITableViewCellSelectionStyle.none
        pageControl.addGestureRecognizer(self.pageControlPress)

        collectionView.snp.makeConstraints { make in

            make.edges.equalTo(contentView).inset(UIEdgeInsets(top: 0, left: 0, bottom: ASHorizontalScrollCellUX.PageControlOffset, right: 0))
        }

        pageControl.snp.makeConstraints { make in
            make.size.equalTo(ASHorizontalScrollCellUX.PageControlSize)
            make.top.equalTo(collectionView.snp.bottom)
            make.centerX.equalTo(self.snp.centerX)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let layout = collectionView.collectionViewLayout as! HorizontalFlowLayout

        gradientBG.frame = contentView.bounds
        if gradientBG.superlayer == nil {
            contentView.layer.insertSublayer(gradientBG, at: 0)
        }

        pageControl.pageCount = layout.numberOfPages()
        pageControl.isHidden = pageControl.pageCount <= 1
    }

    func currentPageChanged(_ currentPage: CGFloat) {
        pageControl.progress = currentPage
        if currentPage == floor(currentPage) {
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
            self.setNeedsLayout()
        }
    }

    func handlePageTap(_ gesture: UITapGestureRecognizer) {
        guard pageControl.pageCount > 1 else {
            return
        }

        if pageControl.pageCount > pageControl.currentPage + 1 {
            pageControl.progress = CGFloat(pageControl.currentPage + 1)
        } else {
            pageControl.progress = CGFloat(pageControl.currentPage - 1)
        }
        let swipeCoordinate = CGFloat(pageControl.currentPage) * self.collectionView.frame.size.width
        self.collectionView.setContentOffset(CGPoint(x: swipeCoordinate, y: 0), animated: true)
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
    var itemSize = CGSize.zero
    fileprivate var cellCount: Int {
        if let collectionView = collectionView, let dataSource = collectionView.dataSource {
            return dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
        }
        return 0
    }
    fileprivate var boundsSize = CGSize.zero
    fileprivate var insets = UIEdgeInsets.zero
    fileprivate let minimumInsets: CGFloat = 20

    override func prepare() {
        super.prepare()
        boundsSize = self.collectionView?.bounds.size ?? CGSize.zero
    }

    func numberOfPages() -> Int {
        let itemsPerPage = maxVerticalItemsCount() * maxHorizontalItemsCount()
        // Sometimes itemsPerPage is 0. In this case just return 0. We dont want to try dividing by 0.
        return itemsPerPage == 0 ? 0 : Int(ceil(Double(cellCount) / Double(itemsPerPage)))
    }

    override var collectionViewContentSize: CGSize {
        let contentSize = boundsSize
        let horizontalItemsCount = maxHorizontalItemsCount()
        let verticalItemsCount = maxVerticalItemsCount()

        // Take the number of cells and subtract its space in the view from the height. The left over space is the white space.
        // The left over space is then devided evenly into (n + 1) parts to figure out how much space should be inbetween a cell
        var verticalInsets = (contentSize.height - (CGFloat(verticalItemsCount) * itemSize.height)) / CGFloat(verticalItemsCount + 1)
        var horizontalInsets = (contentSize.width - (CGFloat(horizontalItemsCount) * itemSize.width)) / CGFloat(horizontalItemsCount + 1)

        // We want a minimum inset to make things not look crowded. We also don't want uneven spacing.
        // If we dont have this. Set a minimum inset and recalculate the size of a cell
        if horizontalInsets < minimumInsets || horizontalInsets != verticalInsets {
            verticalInsets = minimumInsets
            horizontalInsets = minimumInsets
            itemSize.width = (contentSize.width - (CGFloat(horizontalItemsCount + 1) * horizontalInsets)) / CGFloat(horizontalItemsCount)
            itemSize.height = itemSize.width
        }

        insets = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)
        var size = contentSize
        size.width = CGFloat(numberOfPages()) * contentSize.width
        
        return size
    }

    func maxVerticalItemsCount() -> Int {
        let verticalItemsCount =  Int(floor(boundsSize.height / (itemSize.height + insets.top)))
        if let delegate = self.collectionView?.delegate as? ASHorizontalLayoutDelegate {
            return delegate.numberOfVerticalItems()
        } else {
            return verticalItemsCount
        }
    }

    func maxHorizontalItemsCount() -> Int {
        let horizontalItemsCount =  Int(floor(boundsSize.width / (itemSize.width + insets.left)))
        if let delegate = self.collectionView?.delegate as? ASHorizontalLayoutDelegate {
            return delegate.numberOfHorizontalItems()
        } else {
            return horizontalItemsCount
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElements(in: rect)
        var allAttributes = [UICollectionViewLayoutAttributes]()
        for i in 0 ..< cellCount {
            let indexPath = IndexPath(row: i, section: 0)
            let attr = self.computeLayoutAttributesForCellAtIndexPath(indexPath)
            allAttributes.append(attr)
        }
        return allAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.computeLayoutAttributesForCellAtIndexPath(indexPath)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // Sometimes when the topsiteCell isnt on the screen the newbounds that it tries to layout in is very tiny
        // Resulting in incorrect layouts. So only layout when the width is greater than 320.
        return newBounds.width <= 320
    }

    func computeLayoutAttributesForCellAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let row = indexPath.row
        let bounds = self.collectionView!.bounds

        let verticalItemsCount = maxVerticalItemsCount()
        let horizontalItemsCount = maxHorizontalItemsCount()

        let itemsPerPage = verticalItemsCount * horizontalItemsCount

        let columnPosition = row % horizontalItemsCount
        let rowPosition = (row / horizontalItemsCount) % verticalItemsCount
        let itemPage = Int(floor(Double(row)/Double(itemsPerPage)))

        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        var frame = CGRect.zero
        frame.origin.x = CGFloat(itemPage) * bounds.size.width + CGFloat(columnPosition) * (itemSize.width + insets.left) + insets.left
        frame.origin.y = CGFloat(rowPosition) * (itemSize.height + insets.top) + insets.top
        frame.size = itemSize
        attr.frame = frame
        
        return attr
    }
}

/*
    Defines the number of items to show in topsites for different size classes.
*/
struct ASTopSiteSourceUX {
    static let verticalItemsForTraitSizes = [UIUserInterfaceSizeClass.compact: 1, UIUserInterfaceSizeClass.regular: 2, UIUserInterfaceSizeClass.unspecified: 0]
    static let horizontalItemsForTraitSizes = [UIUserInterfaceSizeClass.compact: 3, UIUserInterfaceSizeClass.regular: 5, UIUserInterfaceSizeClass.unspecified: 0]
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
        // An iPhone 5 in both landscape/portrait is considered compactWidth which means we need to let the layout determine how many items to show based on actual width.
        if traits.horizontalSizeClass == .compact && traits.verticalSizeClass == .compact {
            return ASTopSiteSourceUX.horizontalItemsForTraitSizes[.regular]!
        }
        return ASTopSiteSourceUX.horizontalItemsForTraitSizes[traits.horizontalSizeClass]!
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
