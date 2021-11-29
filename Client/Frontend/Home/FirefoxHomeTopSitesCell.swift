// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import SDWebImage
import Storage

struct TopSiteCellUX {
    static let titleHeight: CGFloat = 20
    static let cellCornerRadius: CGFloat = 8
    static let titleOffset: CGFloat = 4
    static let overlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let iconSize = CGSize(width: 36, height: 36)
    static let iconCornerRadius: CGFloat = 4
    static let backgroundSize = CGSize(width: 60, height: 60)
    static let shadowRadius: CGFloat = 6
    static let borderColor = UIColor(white: 0, alpha: 0.1)
    static let borderWidth: CGFloat = 0.5
    static let pinIconSize: CGFloat = 12
}

/*
 *  The TopSite cell that appears in the ASHorizontalScrollView.
 */
class TopSiteItemCell: UICollectionViewCell, NotificationThemeable {

    var url: URL?

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = TopSiteCellUX.iconCornerRadius
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var titleWrapper = UIView()

    lazy var pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.templateImageNamed("pin_small")
        return imageView
    }()

    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        titleLabel.preferredMaxLayoutWidth = TopSiteCellUX.backgroundSize.width + TopSiteCellUX.shadowRadius
        return titleLabel
    }()

    lazy private var faviconBG: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TopSiteCellUX.cellCornerRadius
        view.layer.borderWidth = TopSiteCellUX.borderWidth
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = TopSiteCellUX.shadowRadius
        return view
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.isHidden = true
        return selectedOverlay
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
        contentView.addSubview(titleWrapper)
        titleWrapper.addSubview(titleLabel)
        contentView.addSubview(faviconBG)
        faviconBG.addSubview(imageView)
        contentView.addSubview(selectedOverlay)

        titleWrapper.snp.makeConstraints { make in
            make.top.equalTo(faviconBG.snp.bottom).offset(8)
            make.bottom.centerX.equalTo(contentView)
            make.width.lessThanOrEqualTo(TopSiteCellUX.backgroundSize.width + 20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleWrapper)
            make.leading.trailing.equalTo(titleWrapper)
        }

        imageView.snp.makeConstraints { make in
            make.size.equalTo(TopSiteCellUX.iconSize)
            make.center.equalTo(faviconBG)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        faviconBG.snp.makeConstraints { make in
            make.top.centerX.equalTo(contentView)
            make.size.equalTo(TopSiteCellUX.backgroundSize)
        }

        pinImageView.snp.makeConstraints { make in
            make.size.equalTo(TopSiteCellUX.pinIconSize)
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
    }

    func configureWithTopSiteItem(_ site: Site) {
        url = site.tileURL

        if let provider = site.metadata?.providerName {
            titleLabel.text = provider.lowercased()
        } else {
            titleLabel.text = site.tileURL.shortDisplayString
        }

        let words = titleLabel.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
        titleLabel.numberOfLines = words == 1 ? 1 : 2

        // If its a pinned site add a bullet point to the front
        if let _ = site as? PinnedSite {
            titleWrapper.addSubview(pinImageView)
            pinImageView.snp.makeConstraints { make in
                make.trailing.equalTo(self.titleLabel.snp.leading).offset(-TopSiteCellUX.titleOffset)
                make.centerY.equalTo(self.titleLabel.snp.centerY)
            }
            titleLabel.snp.updateConstraints { make in
                make.leading.equalTo(titleWrapper).offset(TopSiteCellUX.pinIconSize + TopSiteCellUX.titleOffset)
            }
        } else {
            titleLabel.snp.updateConstraints { make in
                make.leading.equalTo(titleWrapper)
            }
        }

        accessibilityLabel = titleLabel.text
        self.imageView.setFaviconOrDefaultIcon(forSite: site) {}

        applyTheme()
    }

    func applyTheme() {
        pinImageView.tintColor = UIColor.theme.homePanel.topSitePin
        faviconBG.backgroundColor = UIColor.theme.homePanel.shortcutBackground
        faviconBG.layer.borderColor = TopSiteCellUX.borderColor.cgColor
        faviconBG.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        faviconBG.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        selectedOverlay.backgroundColor = TopSiteCellUX.overlayColor
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.theme.homePanel.topSiteDomain
    }
}

// An empty cell to show when a row is incomplete
class EmptyTopsiteDecorationCell: UICollectionReusableView {

    lazy private var emptyBG: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TopSiteCellUX.cellCornerRadius
        view.layer.borderWidth = TopSiteCellUX.borderWidth
        view.layer.borderColor = TopSiteCellUX.borderColor.cgColor
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(emptyBG)
        emptyBG.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(TopSiteCellUX.backgroundSize)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct ASHorizontalScrollCellUX {
    static let TopSiteCellIdentifier = "TopSiteItemCell"
    static let TopSiteEmptyCellIdentifier = "TopSiteItemEmptyCell"

    static let TopSiteItemSize = CGSize(width: 65, height: 90)
    static let MinimumInsets: CGFloat = 4
    static let VerticalInsets: CGFloat = 16
}

/*
 The View that describes the topSite cell that appears in the tableView.
 */
class ASHorizontalScrollCell: UICollectionViewCell, ReusableCell {

    lazy var collectionView: UICollectionView = {
        let layout  = HorizontalFlowLayout()
        layout.itemSize = ASHorizontalScrollCellUX.TopSiteItemSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TopSiteItemCell.self, forCellWithReuseIdentifier: ASHorizontalScrollCellUX.TopSiteCellIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.layer.masksToBounds = false
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
        let estimatedItemSize = itemSize

        //calculate our estimates.
        let rows = CGFloat(ceil(Double(Float(cellCount)/Float(horizontalItemsCount))))
        let estimatedHeight = (rows * estimatedItemSize.height) + (8 * rows)
        let estimatedSize = CGSize(width: width, height: estimatedHeight)

        // Take the number of cells and subtract its space in the view from the width. The left over space is the white space.
        // The left over space is then divided evenly into (n - 1) parts to figure out how much space should be in between a cell
        let calculatedSpacing = floor((width - (CGFloat(horizontalItemsCount) * estimatedItemSize.width)) / CGFloat(horizontalItemsCount - 1))
        let insets = max(ASHorizontalScrollCellUX.MinimumInsets, calculatedSpacing)
        let estimatedInsets = UIEdgeInsets(top: ASHorizontalScrollCellUX.VerticalInsets, left: insets, bottom: ASHorizontalScrollCellUX.VerticalInsets, right: insets)

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

        decorationAttr.frame.size.height -= TopSiteCellUX.titleHeight
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
        frame.origin.x = CGFloat(columnPosition) * (itemSize.width + insets.left)
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

    var urlPressedHandler: ((Site, IndexPath) -> Void)?
    // The current traits that define the parent ViewController. Used to determine how many rows/columns should be created.
    var currentTraits: UITraitCollection?

    func numberOfHorizontalItems() -> Int {
        guard let traits = currentTraits else {
            return 0
        }
        let isLandscape = UIWindow.isLandscape
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
        if UIWindow.isLandscape || (traits.horizontalSizeClass == .compact && isLandscape) {
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
        urlPressedHandler?(contentItem, indexPath)
    }
}
