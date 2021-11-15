// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage

struct RecentlySavedCollectionCellUX {
    static let bookmarkItemsLimit: UInt = 5
    static let bookmarkItemsCutoff: Int = 10
    static let readingListItemsLimit: Int = 5
    static let readingListItemsCutoff: Int = 7
    static let cellWidth: CGFloat = 150
    static let cellHeight: CGFloat = 110
    static let generalSpacing: CGFloat = 8
    static let sectionInsetSpacing: CGFloat = 4
}

protocol RecentlySavedItem {
    var title: String { get }
    var url: String { get }
}

extension ReadingListItem: RecentlySavedItem { }
extension BookmarkItem: RecentlySavedItem { }

/// A cell serving as a collectionView to hold its associated recently saved cells.
class FxHomeRecentlySavedCollectionCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    var profile: Profile!
    var recentBookmarks = [BookmarkItem]() {
        didSet {
            recentBookmarks = RecentItemsHelper.filterStaleItems(recentItems: recentBookmarks, since: Date()) as! [BookmarkItem]
        }
    }
    var readingListItems = [ReadingListItem]()
    var viewModel: FirefoxHomeRecentlySavedViewModel!
    lazy var siteImageHelper = SiteImageHelper(profile: profile)
    
    // UI
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RecentlySavedCell.self, forCellWithReuseIdentifier: RecentlySavedCell.cellIdentifier)
        
        return collectionView
    }()
    
    // MARK: - Inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    private func setupLayout() {
        contentView.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    private func loadItems() -> [RecentlySavedItem] {
        var items = [RecentlySavedItem]()
        
        items.append(contentsOf: recentBookmarks)
        items.append(contentsOf: readingListItems)
        
        viewModel.recentItems = items
        
        return items
    }
    
    private func configureDataSource() {
        profile.places.getRecentBookmarks(limit: RecentlySavedCollectionCellUX.bookmarkItemsLimit).uponQueue(.main, block: { [weak self] result in
            self?.recentBookmarks = result.successValue ?? []
        })
        
        if let readingList = profile.readingList.getAvailableRecords().value.successValue?.prefix(RecentlySavedCollectionCellUX.readingListItemsLimit) {
            let readingListItems = Array(readingList)
            self.readingListItems = RecentItemsHelper.filterStaleItems(recentItems: readingListItems, since: Date()) as! [ReadingListItem]
        }
    }
    
}

extension FxHomeRecentlySavedCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        configureDataSource()
        
        return loadItems().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentlySavedCell.cellIdentifier, for: indexPath) as! RecentlySavedCell
        let dataSource = loadItems()
        
        if let item = dataSource[safe: indexPath.row] {
            let site = Site(url: item.url, title: item.title, bookmarked: true)
            cell.itemTitle.text = site.title
            cell.heroImage.image = nil
            
            let heroImageCacheKey = NSString(string: site.url)
            if let cachedImage = SiteImageHelper.cache.object(forKey: heroImageCacheKey) {
                cell.heroImage.image = cachedImage
            } else {
                siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: true) { image in
                    cell.heroImage.image = image
                }
            }
            
        }
        
        return cell
    }
    
}

extension FxHomeRecentlySavedCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dataSource = loadItems()
        
        if let item = dataSource[safe: indexPath.row] as? BookmarkItem {
            guard let url = URIFixup.getURL(item.url) else { return }
            
            homePanelDelegate?.homePanel(didSelectURL: url, visitType: .bookmark, isGoogleTopSite: false)
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedBookmarkItemAction,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        } else if let item = dataSource[safe: indexPath.row] as? ReadingListItem,
                  let url = URL(string: item.url),
                  let encodedUrl = url.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) {
            
            let visitType = VisitType.bookmark
            libraryPanelDelegate?.libraryPanel(didSelectURL: encodedUrl, visitType: visitType)
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedReadingListAction,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        }
        
    }
}

extension FxHomeRecentlySavedCollectionCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: RecentlySavedCollectionCellUX.cellWidth, height: RecentlySavedCollectionCellUX.cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: RecentlySavedCollectionCellUX.generalSpacing,
                            left: RecentlySavedCollectionCellUX.sectionInsetSpacing,
                            bottom: RecentlySavedCollectionCellUX.generalSpacing,
                            right: RecentlySavedCollectionCellUX.sectionInsetSpacing)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return RecentlySavedCollectionCellUX.generalSpacing
    }
    
}

private struct RecentlySavedCellUX {
    static let generalCornerRadius: CGFloat = 12
    static let bookmarkTitleFontSize: CGFloat = 17
    static let bookmarkDetailsFontSize: CGFloat = 12
    static let labelsWrapperSpacing: CGFloat = 4
    static let bookmarkStackViewSpacing: CGFloat = 8
    static let bookmarkStackViewShadowRadius: CGFloat = 4
    static let bookmarkStackViewShadowOffset: CGFloat = 2
}

/// A cell used in FxHomeScreen's Recently Saved section. It holds bookmarks and reading list items.
class RecentlySavedCell: UICollectionViewCell, NotificationThemeable {
    
    // MARK: - Properties
    
    static let cellIdentifier = "recentlySavedCell"
    
    // UI
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = RecentlySavedCellUX.generalCornerRadius
        imageView.backgroundColor = .systemBackground
    }
    let itemTitle: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: RecentlySavedCellUX.bookmarkTitleFontSize)
        label.textColor = .label
    }
    
    // MARK: - Inits
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupLayout()
        setupNotifications()
        applyTheme()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Helpers
    
    private func setupLayout() {
        contentView.layer.cornerRadius = RecentlySavedCellUX.generalCornerRadius
        contentView.layer.shadowRadius = RecentlySavedCellUX.bookmarkStackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: RecentlySavedCellUX.bookmarkStackViewShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        
        contentView.addSubviews(heroImage, itemTitle)
        
        NSLayoutConstraint.activate([
            heroImage.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroImage.heightAnchor.constraint(equalToConstant: 92),
            heroImage.widthAnchor.constraint(equalToConstant: 110),
            
            itemTitle.topAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: 8),
            itemTitle.leadingAnchor.constraint(equalTo: heroImage.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: -2)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
    }
    
    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }
    
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            itemTitle.textColor = UIColor.Photon.LightGrey10
        } else {
            itemTitle.textColor = UIColor.Photon.DarkGrey90
        }
    }
    
}
