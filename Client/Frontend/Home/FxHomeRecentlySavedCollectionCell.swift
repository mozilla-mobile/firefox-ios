/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

private struct RecentlySavedCollectionCellUX {
    static let bookmarkItemsLimit: UInt = 5
    static let cellWidth: CGFloat = 134
    static let cellHeight: CGFloat = 120
    static let generalSpacing: CGFloat = 8
    static let sectionInsetSpacing: CGFloat = 4
}

/// A cell serving as a collectionView, to hold its associated bookmark cells.
class FxHomeRecentlySavedCollectionCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    weak var homePanelDelegate: HomePanelDelegate?
    var profile: Profile?
    var recentBookmarks = [BookmarkNode]()
    
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
        collectionView.register(RecentlySavedBookmarkCell.self, forCellWithReuseIdentifier: RecentlySavedBookmarkCell.cellIdentifier)
        
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
    
}

extension FxHomeRecentlySavedCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        profile?.places.getRecentBookmarks(limit: RecentlySavedCollectionCellUX.bookmarkItemsLimit).uponQueue(.main, block: { [weak self] result in
            self?.recentBookmarks = result.successValue ?? []
        })
        
        recentBookmarks = BookmarksHelper.filterOldBookmarks(bookmarks: recentBookmarks, since: 10)
        
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .recentlySavedBookmarkItemView,
                                     extras: [TelemetryWrapper.EventObject.recentlySavedItemImpressions.rawValue: recentBookmarks.count])
        
        return recentBookmarks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentlySavedBookmarkCell.cellIdentifier, for: indexPath) as! RecentlySavedBookmarkCell
        let currentItem = recentBookmarks[indexPath.row] as! BookmarkItem
        let site = Site(url: currentItem.url, title: currentItem.title, bookmarked: true, guid: currentItem.guid)
        
        profile?.favicons.getFaviconImage(forSite: site).uponQueue(.main, block: { result in
            guard let image = result.successValue else { return }
            
            cell.heroImage.image = image
            cell.setNeedsLayout()
        })
        
        cell.bookmarkTitle.text = site.title
        cell.bookmarkDetails.text = site.tileURL.shortDisplayString
        
        return cell
    }
    
}

extension FxHomeRecentlySavedCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bookmark = recentBookmarks[indexPath.row] as! BookmarkItem
        guard let url = URIFixup.getURL(bookmark.url) else { return }
        
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: .bookmark, isGoogleTopSite: false)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .bookmark, value: .recentlySavedBookmarkCell)
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

private struct RecentlySavedBookmarkCellUX {
    static let generalCornerRadius: CGFloat = 8
    static let bookmarkTitleFontSize: CGFloat = 17
    static let bookmarkDetailsFontSize: CGFloat = 12
    static let labelsWrapperSpacing: CGFloat = 4
    static let bookmarkStackViewSpacing: CGFloat = 8
    static let bookmarkStackViewShadowRadius: CGFloat = 4
    static let bookmarkStackViewShadowOffset: CGFloat = 2
}

/// A cell used in FxHomeScreen's Recently Saved section.
class RecentlySavedBookmarkCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static let cellIdentifier = "recentlySavedBookmarkCell"
    
    // UI
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = RecentlySavedBookmarkCellUX.generalCornerRadius
    }
    let divider: UIView = .build { view in
        view.backgroundColor = UIColor.theme.homePanel.activityStreamCellDescription
    }
    let bookmarkTitle: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: RecentlySavedBookmarkCellUX.bookmarkTitleFontSize)
    }
    let bookmarkDetails: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: RecentlySavedBookmarkCellUX.bookmarkDetailsFontSize)
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
        contentView.layer.cornerRadius = RecentlySavedBookmarkCellUX.generalCornerRadius
        contentView.layer.shadowRadius = RecentlySavedBookmarkCellUX.bookmarkStackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: RecentlySavedBookmarkCellUX.bookmarkStackViewShadowOffset)
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
            bookmarkDetails.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
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

extension RecentlySavedBookmarkCell: Themeable {
    func applyTheme() {
        contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        bookmarkDetails.textColor = UIColor.theme.homePanel.activityStreamCellDescription
        divider.backgroundColor = UIColor.theme.tabTray.background
    }
}
