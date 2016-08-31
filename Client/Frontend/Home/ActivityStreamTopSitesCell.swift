import Foundation
import Shared
import WebImage

struct TopSiteItem {
    let urlTitle: String
    let faviconURL: NSURL?
    let siteURL: NSURL
}

struct TopSiteCellUX {
    static let TitleInsetPercent: CGFloat = 0.66
    static let TitleBackgroundColor = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.7)
    static let TitleTextColor = UIColor.blackColor()
    static let TitleFont = DynamicFontHelper.defaultHelper.DefaultSmallFont
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CellCornerRadius: CGFloat = 4
    static let OverlayColor = UIColor(white: 0.0, alpha: 0.25)
}

/*
 *  The TopSite cell that appears in the ASHorizontalScrollView.
*/
class TopSiteItemCell: UICollectionViewCell {

    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.layer.masksToBounds = true
        titleLabel.textAlignment = .Center
        titleLabel.font = TopSiteCellUX.TitleFont
        titleLabel.textColor = TopSiteCellUX.TitleTextColor
        titleLabel.backgroundColor = TopSiteCellUX.TitleBackgroundColor
        return titleLabel
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = TopSiteCellUX.OverlayColor
        selectedOverlay.hidden = true
        return selectedOverlay
    }()

    override var selected: Bool {
        didSet {
            self.selectedOverlay.hidden = !selected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = TopSiteCellUX.CellCornerRadius
        contentView.layer.masksToBounds = true
        contentView.addSubview(titleLabel)
        contentView.addSubview(imageView)
        contentView.addSubview(selectedOverlay)

        let titleHeight = Int(frame.height - (frame.height * TopSiteCellUX.TitleInsetPercent))
        titleLabel.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(titleHeight)
        }
        imageView.snp_makeConstraints { make in
            make.size.equalTo(CGSize(width: self.frame.width/2, height: self.frame.height/2))
            // Add an offset to the image to make it appear centered with the titleLabel
            make.center.equalTo(self.snp_center).offset(UIEdgeInsets(top: -CGFloat(titleHeight)/2, left: 0, bottom: 0, right: 0))
        }

        selectedOverlay.snp_makeConstraints { make in
            make.edges.equalTo(contentView)
        }
    }

    override func updateConstraints() {
        let height = Int(frame.height - (frame.height * TopSiteCellUX.TitleInsetPercent))
        titleLabel.snp_updateConstraints { make in
            make.height.equalTo(height)
        }
        super.updateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = UIColor.lightGrayColor()
        imageView.image = nil
        titleLabel.text = ""
    }

    private func setImageWithURL(url: NSURL) {
        imageView.sd_setImageWithURL(url) { [unowned self] (img, err, type, url) -> Void in
            guard let img = img else {
                self.contentView.backgroundColor = UIColor.lightGrayColor()
                self.imageView.image = FaviconFetcher.getDefaultFavicon(url)
                return
            }

            // Get dominant colors using a scaled 25/25 image.
            img.getColors(CGSize(width: 25, height: 25)) { colors in
                //In cases where the background is white. Force the background color to a different color
                let colorArr = [colors.backgroundColor, colors.detailColor, colors.primaryColor].filter { !$0.isWhite }
                self.contentView.backgroundColor = colorArr.isEmpty ? UIColor.lightGrayColor() : colorArr.first
            }
        }
    }

    func configureWithTopSiteItem(site: TopSiteItem) {
        titleLabel.text = site.urlTitle
        guard let favURL = site.faviconURL else {
            contentView.backgroundColor = UIColor.lightGrayColor()
            imageView.image = FaviconFetcher.getDefaultFavicon(site.siteURL)
            return
        }
        setImageWithURL(favURL)
    }

}

struct ASHorizontalScrollCellUX {
    static let TopSiteCellIdentifier = "TopSiteItemCell"
    static let TopSiteItemSize = CGSize(width: 100, height: 100)
    static let BackgroundColor = UIColor.whiteColor()
    static let PageControlRadius: CGFloat = 3
    static let PageControlSize = CGSize(width: 30, height: 15)
    static let PageControlOffset: CGFloat = -20
}

/*
 The View that describes the topSite cell that appears in the tableView.
 */
class ASHorizontalScrollCell: UITableViewCell {

    lazy private var collectionView: UICollectionView = {
        let layout  = HorizontalFlowLayout()
        layout.itemSize = ASHorizontalScrollCellUX.TopSiteItemSize
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.registerClass(TopSiteItemCell.self, forCellWithReuseIdentifier: ASHorizontalScrollCellUX.TopSiteCellIdentifier)
        collectionView.backgroundColor = ASHorizontalScrollCellUX.BackgroundColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.pagingEnabled = true
        return collectionView
    }()

    lazy private var pageControl: FilledPageControl = {
        let pageControl = FilledPageControl()
        pageControl.tintColor = UIColor.grayColor()
        pageControl.indicatorRadius = ASHorizontalScrollCellUX.PageControlRadius
        pageControl.userInteractionEnabled = false
        return pageControl
    }()

    weak var delegate: ASHorizontalScrollCellManager? {
        didSet {
            collectionView.delegate = delegate
            collectionView.dataSource = delegate
            delegate?.pageChangedHandler = { [weak self] progress in
                self?.currentPageChanged(progress)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.collectionView.reloadData()
            }
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = ASHorizontalScrollCellUX.BackgroundColor
        contentView.addSubview(collectionView)
        contentView.addSubview(pageControl)
        self.selectionStyle = UITableViewCellSelectionStyle.None

        collectionView.snp_makeConstraints { make in
            make.edges.equalTo(contentView).offset(UIEdgeInsets(top: 0, left: 0, bottom: ASHorizontalScrollCellUX.PageControlOffset, right: 0))
        }

        pageControl.snp_makeConstraints { make in
            make.size.equalTo(ASHorizontalScrollCellUX.PageControlSize)
            make.top.equalTo(collectionView.snp_bottom)
            make.centerX.equalTo(self.snp_centerX)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let layout = collectionView.collectionViewLayout as! HorizontalFlowLayout

        pageControl.pageCount = layout.numberOfPages
        pageControl.hidden = pageControl.pageCount <= 1
    }

    func currentPageChanged(currentPage: CGFloat) {
        pageControl.progress = currentPage
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
    private var cellCount = 0
    private var boundsSize = CGSize.zero
    private var insets = UIEdgeInsetsZero
    private let minimumInsets: CGFloat = 20
    var numberOfPages = 0

    override func prepareLayout() {
        super.prepareLayout()
        cellCount = self.collectionView!.numberOfItemsInSection(0)
        boundsSize = self.collectionView!.bounds.size
    }

    override func collectionViewContentSize() -> CGSize {
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

        let itemsPerPage = verticalItemsCount * horizontalItemsCount

        numberOfPages = Int(ceil(Double(cellCount) / Double(itemsPerPage)))
        insets = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)

        var size = contentSize
        size.width = CGFloat(numberOfPages) * contentSize.width
        
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

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElementsInRect(rect)
        var allAttributes = [UICollectionViewLayoutAttributes]()
        for i in 0 ..< cellCount {
            let indexPath = NSIndexPath(forRow: i, inSection: 0)
            let attr = self.computeLayoutAttributesForCellAtIndexPath(indexPath)
            allAttributes.append(attr)
        }
        return allAttributes
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return self.computeLayoutAttributesForCellAtIndexPath(indexPath)
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        // Sometimes when the topsiteCell isnt on the screen the newbounds that it tries to layout in is very tiny
        // Resulting in incorrect layouts. So only layout when the width is greater than 320.
        return newBounds.width <= 320
    }

    func computeLayoutAttributesForCellAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let row = indexPath.row
        let bounds = self.collectionView!.bounds

        let verticalItemsCount = maxVerticalItemsCount()
        let horizontalItemsCount = maxHorizontalItemsCount()

        let itemsPerPage = verticalItemsCount * horizontalItemsCount

        let columnPosition = row % horizontalItemsCount
        let rowPosition = (row / horizontalItemsCount) % verticalItemsCount
        let itemPage = Int(floor(Double(row)/Double(itemsPerPage)))

        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)

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
    static let verticalItemsForTraitSizes = [UIUserInterfaceSizeClass.Compact : 1, UIUserInterfaceSizeClass.Regular : 2, UIUserInterfaceSizeClass.Unspecified: 0]
    static let horizontalItemsForTraitSizes = [UIUserInterfaceSizeClass.Compact : 3, UIUserInterfaceSizeClass.Regular : 5, UIUserInterfaceSizeClass.Unspecified: 0]
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

    var content: [TopSiteItem] = []

    var urlPressedHandler: ((NSURL) -> Void)?
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
        if traits.horizontalSizeClass == .Compact && traits.verticalSizeClass == .Compact {
            return ASTopSiteSourceUX.horizontalItemsForTraitSizes[.Regular]!
        }
        return ASTopSiteSourceUX.horizontalItemsForTraitSizes[traits.horizontalSizeClass]!
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.content.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ASTopSiteSourceUX.CellIdentifier, forIndexPath: indexPath) as! TopSiteItemCell
        let contentItem = content[indexPath.row]
        cell.configureWithTopSiteItem(contentItem)
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let contentItem = content[indexPath.row]
        urlPressedHandler?(contentItem.siteURL)
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let pageWidth = CGRectGetWidth(scrollView.frame)
        pageChangedHandler?(scrollView.contentOffset.x / pageWidth)
    }
}
