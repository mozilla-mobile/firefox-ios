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
        faviconBG.addSubview(imageView)
        contentView.addSubview(selectedOverlay)

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(contentView).offset(TopSiteCellUX.TitleOffset)
            make.right.equalTo(contentView).offset(-TopSiteCellUX.TitleOffset)
            make.height.equalTo(TopSiteCellUX.TitleHeight)
            make.bottom.equalTo(contentView)
        }

        imageView.snp.makeConstraints { make in
            make.size.equalTo(floor(frame.width * TopSiteCellUX.IconSizePercent))
            make.center.equalTo(faviconBG)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        faviconBG.snp.makeConstraints { make in
            make.top.left.right.equalTo(contentView)
            make.bottom.equalTo(contentView).inset(TopSiteCellUX.TitleHeight)
        }
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
        faviconBG.backgroundColor = UIColor.clear
        pinImageView.removeFromSuperview()
        imageView.sd_cancelCurrentImageLoad()
        titleLabel.text = ""
    }

    func configureWithTopSiteItem(_ site: Site) {
        url = site.tileURL

        if let provider = site.metadata?.providerName {
            titleLabel.text = provider.lowercased()
        } else {
            titleLabel.text = site.tileURL.shortDisplayString
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
                make.left.equalTo(contentView).offset(TopSiteCellUX.PinIconSize)
            }
        } else {
            titleLabel.snp.updateConstraints { make in
                make.left.equalTo(contentView).offset(TopSiteCellUX.TitleOffset)
            }
        }

        accessibilityLabel = titleLabel.text
        faviconBG.backgroundColor = .clear
        self.imageView.setFaviconOrDefaultIcon(forSite: site) { [weak self] in
            self?.imageView.snp.remakeConstraints { make in
                guard let faviconBG = self?.faviconBG , let frame = self?.frame else { return }
                if self?.imageView.backgroundColor == nil {
                    make.size.equalTo(frame.width)
                } else {
                    make.size.equalTo(floor(frame.width * TopSiteCellUX.IconSizePercent))
                }
                make.center.equalTo(faviconBG)
            }

            self?.faviconBG.backgroundColor = self?.imageView.backgroundColor
        }

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

    weak var delegate: ASHorizontalScrollCellManager? {
        didSet {
            collectionView.delegate = delegate
            collectionView.dataSource = delegate
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        accessibilityIdentifier = "TopSitesCell"
        backgroundColor = UIColor.clear
        contentView.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeArea.edges)
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
        return 1
    }

    func calculateLayout(for size: CGSize) -> (size: CGSize, cellSize: CGSize, cellInsets: UIEdgeInsets) {
        let width = size.width
        guard width != 0 else {
            return (size: .zero, cellSize: self.itemSize, cellInsets: self.insets)
        }

        let horizontalItemsCount = maxHorizontalItemsCount(width: width) // 8

        // Take the number of cells and subtract its space in the view from the height. The left over space is the white space.
        // The left over space is then devided evenly into (n + 1) parts to figure out how much space should be inbetween a cell
        let insets = ASHorizontalScrollCellUX.MinimumInsets

        var estimatedItemSize = itemSize
        estimatedItemSize.width = floor((width - (CGFloat(horizontalItemsCount + 1) * insets)) / CGFloat(horizontalItemsCount))
        estimatedItemSize.height = estimatedItemSize.width + TopSiteCellUX.TitleHeight

        //calculate our estimates.
        let rows = CGFloat(ceil(Double(Float(cellCount)/Float(horizontalItemsCount))))
        let estimatedHeight = (rows * estimatedItemSize.height) + (insets * rows)
        let estimatedSize = CGSize(width: width, height: estimatedHeight)

        let estimatedInsets = UIEdgeInsets(equalInset: insets)
        return (size: estimatedSize, cellSize: estimatedItemSize, cellInsets: estimatedInsets)
    }

    override var collectionViewContentSize: CGSize {
        let estimatedLayout = calculateLayout(for: boundsSize)
        insets = estimatedLayout.cellInsets
        itemSize = estimatedLayout.cellSize
        boundsSize.height = estimatedLayout.size.height
        return estimatedLayout.size
    }

    func maxHorizontalItemsCount(width: CGFloat) -> Int {
        let horizontalItemsCount = Int(floor(width / (ASHorizontalScrollCellUX.TopSiteItemSize.width + insets.left)))
        if let delegate = self.collectionView?.delegate as? ASHorizontalLayoutDelegate {
            return delegate.numberOfHorizontalItems()
        } else {
            return horizontalItemsCount
        }
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let decorationAttr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
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
        return newBounds.width > 0 && newBounds.size != self.collectionView?.frame.size
    }

    func computeLayoutAttributesForCellAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let row = indexPath.row
        let bounds = self.collectionView!.bounds

        let horizontalItemsCount = maxHorizontalItemsCount(width: bounds.size.width)
        let columnPosition = row % horizontalItemsCount
        let rowPosition = Int(row/horizontalItemsCount)

        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        var frame = CGRect.zero
        frame.origin.x = CGFloat(columnPosition) * (itemSize.width + insets.left) + insets.left
        frame.origin.y = CGFloat(rowPosition) * (itemSize.height + insets.top)

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
    static let CellIdentifier = "TopSiteItemCell"
}

protocol ASHorizontalLayoutDelegate {
    func numberOfHorizontalItems() -> Int
}

/*
 This Delegate/DataSource is used to manage the ASHorizontalScrollCell's UICollectionView.
 This is left generic enough for it to be re used for other parts of Activity Stream.
 */

class ASHorizontalScrollCellManager: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, ASHorizontalLayoutDelegate {

    var content: [Site] = []

    var urlPressedHandler: ((URL, IndexPath) -> Void)?
    // The current traits that define the parent ViewController. Used to determine how many rows/columns should be created.
    var currentTraits: UITraitCollection?

    var numberOfRows: Int = 2

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
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        if UIDevice.current.userInterfaceIdiom == .phone {
            if isLandscape {
                return 8
            } else {
                return 4
            }
        }
        // On iPad
        // The number of items in a row is equal to the number of highlights in a row * 2
        var numItems = Int(FirefoxHomeUX.numberOfItemsPerRowForSizeClassIpad[traits.horizontalSizeClass])
        if UIApplication.shared.statusBarOrientation.isPortrait || (traits.horizontalSizeClass == .compact && isLandscape) {
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
}
