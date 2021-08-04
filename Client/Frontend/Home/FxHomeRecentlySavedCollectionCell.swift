/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

struct RecentlySavedCollectionCellUX {
    static let bookmarkItemsLimit: UInt = 5
    static let bookmarkItemsCutoff: Int = 10
    static let readingListItemsLimit: Int = 5
    static let readingListItemsCutoff: Int = 7
    static let cellWidth: CGFloat = 134
    static let cellHeight: CGFloat = 120
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
    var profile: Profile?
    var recentBookmarks = [BookmarkItem]() {
        didSet {
            recentBookmarks = RecentItemsHelper.filterStaleItems(recentItems: recentBookmarks, since: Date()) as! [BookmarkItem]
        }
    }
    var readingListItems = [ReadingListItem]()
    var viewModel: FirefoxHomeRecentlySavedViewModel!
    
    // UI
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        UIDevice.current.userInterfaceIdiom != .pad ? layout.scrollDirection = .horizontal : nil
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RecentlySavedCell.self, forCellWithReuseIdentifier: RecentlySavedCell.cellIdentifier)
        
        UIDevice.current.userInterfaceIdiom == .pad ? collectionView.isScrollEnabled = false : nil
        
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
        profile?.places.getRecentBookmarks(limit: RecentlySavedCollectionCellUX.bookmarkItemsLimit).uponQueue(.global(), block: { [weak self] result in
            self?.recentBookmarks = result.successValue ?? []
        })
        
        if let readingList = profile?.readingList.getAvailableRecords().value.successValue?.prefix(RecentlySavedCollectionCellUX.readingListItemsLimit) {
            let readingListItems = Array(readingList)
            self.readingListItems = RecentItemsHelper.filterStaleItems(recentItems: readingListItems,
                                                                       since: Date()) as! [ReadingListItem]
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
            
            profile?.favicons.getFaviconImage(forSite: site).uponQueue(.main, block: { result in
                guard let image = result.successValue else { return }
                cell.heroImage.image = image
                cell.setNeedsLayout()
            })
            
            cell.bookmarkTitle.text = site.title
            cell.bookmarkDetails.text = site.tileURL.shortDisplayString
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
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .bookmark, value: .recentlySavedBookmarkItemAction)
        } else if let item = dataSource[safe: indexPath.row] as? ReadingListItem,
                  let url = URL(string: item.url),
                  let encodedUrl = url.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) {
            
            let visitType = VisitType.bookmark
            libraryPanelDelegate?.libraryPanel(didSelectURL: encodedUrl, visitType: visitType)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readingListItem, value: .recentlySavedReadingListAction)
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
    static let generalCornerRadius: CGFloat = 8
    static let bookmarkTitleFontSize: CGFloat = 17
    static let bookmarkDetailsFontSize: CGFloat = 12
    static let labelsWrapperSpacing: CGFloat = 4
    static let bookmarkStackViewSpacing: CGFloat = 8
    static let bookmarkStackViewShadowRadius: CGFloat = 4
    static let bookmarkStackViewShadowOffset: CGFloat = 2
}

/// A cell used in FxHomeScreen's Recently Saved section. It holds bookmarks and reading list items.
class RecentlySavedCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static let cellIdentifier = "recentlySavedCell"
    
    // UI
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = RecentlySavedCellUX.generalCornerRadius
    }
    let divider: UIView = .build { view in
        view.backgroundColor = UIColor.theme.homePanel.activityStreamCellDescription
    }
    let bookmarkTitle: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: RecentlySavedCellUX.bookmarkTitleFontSize)
    }
    let bookmarkDetails: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: RecentlySavedCellUX.bookmarkDetailsFontSize)
    }
    
    // MARK: - Inits
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        applyTheme()
        setupObservers()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
    }
    
    private func setupLayout() {
        contentView.layer.cornerRadius = RecentlySavedCellUX.generalCornerRadius
        contentView.layer.shadowRadius = RecentlySavedCellUX.bookmarkStackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: RecentlySavedCellUX.bookmarkStackViewShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        
        contentView.addSubview(heroImage)
        contentView.addSubview(divider)
        contentView.addSubview(bookmarkTitle)
        contentView.addSubview(bookmarkDetails)
        
        NSLayoutConstraint.activate([
            heroImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            heroImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            heroImage.heightAnchor.constraint(equalToConstant: 24),
            heroImage.widthAnchor.constraint(equalToConstant: 24),
            
            divider.topAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: 24),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            bookmarkTitle.topAnchor.constraint(equalTo: divider.topAnchor, constant: 7),
            bookmarkTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bookmarkTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            bookmarkDetails.topAnchor.constraint(equalTo: bookmarkTitle.bottomAnchor, constant: 2),
            bookmarkDetails.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bookmarkDetails.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
    
}

extension RecentlySavedCell: Themeable {
    func applyTheme() {
        contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        bookmarkDetails.textColor = UIColor.theme.homePanel.activityStreamCellDescription
        divider.backgroundColor = UIColor.theme.tabTray.background
    }
}
